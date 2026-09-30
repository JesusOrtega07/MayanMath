//
//  CalculatorViewModel.swift
//  MayanMath
//
//  ViewModel de la Calculadora (pantalla principal / Inicio).
//  La vista solo llama a estas funciones y lee el estado; no hace cálculos.
//

import Foundation
import Observation

/// Cuál de los dos números se está construyendo.
nonisolated enum CalculatorOperand: Hashable, CaseIterable, Sendable {
    case first
    case second
}

/// Estado de la calculadora.
nonisolated enum CalculatorState: Hashable, Sendable {
    /// El usuario está armando los números (no hay resultado vigente).
    case editing
    case result(CalculationResult)
    case error(CalculationError)
}

/// Último cambio en un área de construcción. La vista lo observa con
/// `.onChange(of: viewModel.lastChange)` para animar y hacer vibrar.
nonisolated struct BuilderChange: Hashable, Identifiable, Sendable {
    enum Kind: Hashable, Sendable {
        case added(MayanDigit, regroupings: [RegroupEvent])
        case removed(MayanSymbol)
        case clearedLevel
        case clearedOperand
        case rejected(BuilderError)
    }

    let id = UUID()
    let operand: CalculatorOperand
    /// `nil` cuando el cambio afecta a todo el número.
    let level: Int?
    let kind: Kind
}

@Observable
final class CalculatorViewModel {
    private(set) var first: MayanNumberBuilder
    private(set) var second: MayanNumberBuilder
    private(set) var operation: MayanOperation = .addition
    /// Número que recibe las fichas cuando no se indica uno.
    var activeOperand: CalculatorOperand = .first
    /// Nivel que recibe las fichas al tocarlas en la paleta (0 = unidades).
    var activeLevel: Int = 0
    private(set) var state: CalculatorState = .editing
    private(set) var lastChange: BuilderChange?

    private let maxResultValue: Int

    init(
        inputLevels: Int = MayanLimits.inputLevels,
        maxResultValue: Int = MayanLimits.maxResultValue
    ) {
        self.first = MayanNumberBuilder(maxLevels: inputLevels)
        self.second = MayanNumberBuilder(maxLevels: inputLevels)
        self.maxResultValue = maxResultValue
    }

    // MARK: - Lectura para la vista

    func builder(for operand: CalculatorOperand) -> MayanNumberBuilder {
        switch operand {
        case .first: first
        case .second: second
        }
    }

    /// Valor decimal en vivo de un número (se muestra debajo de cada operando).
    func decimalValue(of operand: CalculatorOperand) -> Int? {
        builder(for: operand).number?.value
    }

    var canCalculate: Bool { !first.isEmpty && !second.isEmpty }

    var result: CalculationResult? {
        guard case .result(let result) = state else { return nil }
        return result
    }

    var error: CalculationError? {
        guard case .error(let error) = state else { return nil }
        return error
    }

    /// El resultado cabe como primer número para seguir calculando.
    var canContinueWithResult: Bool {
        guard let result else { return false }
        return result.value.levelCount <= first.maxLevels
    }

    // MARK: - Intents: construcción

    /// El usuario tocó un nivel: las siguientes fichas tocadas van ahí.
    func focus(_ operand: CalculatorOperand, level: Int) {
        activeOperand = operand
        activeLevel = min(max(level, 0), builder(for: operand).maxLevels - 1)
    }

    /// Ficha tocada en la paleta: va al número y nivel activos.
    @discardableResult
    func dropOnActiveLevel(_ digit: MayanDigit) -> Bool {
        drop(digit, onLevel: activeLevel, of: activeOperand)
    }

    /// Suelta una ficha de la paleta en un nivel.
    /// - Returns: `false` si no cabe (la vista puede sacudir el nivel).
    @discardableResult
    func drop(_ digit: MayanDigit, onLevel level: Int, of operand: CalculatorOperand? = nil) -> Bool {
        let target = operand ?? activeOperand
        focus(target, level: level)
        do {
            let events = try update(target) { try $0.add(digit, toLevel: level) }
            record(target, level: level, .added(digit, regroupings: events))
            return true
        } catch let error as BuilderError {
            lastChange = BuilderChange(operand: target, level: level, kind: .rejected(error))
            return false
        } catch {
            return false
        }
    }

    /// El usuario tocó un símbolo dentro de un nivel para quitarlo.
    func removeSymbol(_ symbol: MayanSymbol, fromLevel level: Int, of operand: CalculatorOperand) {
        do {
            try update(operand) { try $0.remove(symbol, fromLevel: level) }
            record(operand, level: level, .removed(symbol))
        } catch let error as BuilderError {
            lastChange = BuilderChange(operand: operand, level: level, kind: .rejected(error))
        } catch {}
    }

    func clearLevel(_ level: Int, of operand: CalculatorOperand) {
        do {
            try update(operand) { try $0.clearLevel(level) }
            record(operand, level: level, .clearedLevel)
        } catch {}
    }

    /// Botón "Borrar todo" de un número.
    func clear(_ operand: CalculatorOperand) {
        update(operand) { $0.clear() }
        record(operand, level: nil, .clearedOperand)
    }

    /// Reinicia la calculadora completa.
    func clearAll() {
        first.clear()
        second.clear()
        operation = .addition
        activeOperand = .first
        activeLevel = 0
        state = .editing
        lastChange = nil
    }

    // MARK: - Intents: operación

    func select(_ operation: MayanOperation) {
        guard self.operation != operation else { return }
        self.operation = operation
        state = .editing
    }

    /// Botón "=".
    func calculate() {
        guard let lhs = first.number, let rhs = second.number else { return }
        do {
            let result = try MayanCalculator.calculate(lhs, operation, rhs, maxValue: maxResultValue)
            state = .result(result)
        } catch let error as CalculationError {
            state = .error(error)
        } catch {}
    }

    /// Intercambia los dos números (útil cuando la resta daría negativo).
    func swapOperands() {
        (first, second) = (second, first)
        state = .editing
    }

    /// Pasa el resultado al primer número y deja el segundo vacío para encadenar operaciones.
    @discardableResult
    func continueWithResult() -> Bool {
        guard let result, canContinueWithResult,
              let loaded = try? MayanNumberBuilder(number: result.value, maxLevels: first.maxLevels)
        else { return false }
        first = loaded
        second.clear()
        activeOperand = .second
        activeLevel = 0
        state = .editing
        return true
    }

    // MARK: - Privado

    private func update<T>(
        _ operand: CalculatorOperand,
        _ body: (inout MayanNumberBuilder) throws -> T
    ) rethrows -> T {
        switch operand {
        case .first: return try body(&first)
        case .second: return try body(&second)
        }
    }

    /// Cualquier edición invalida el resultado anterior.
    private func record(_ operand: CalculatorOperand, level: Int?, _ kind: BuilderChange.Kind) {
        lastChange = BuilderChange(operand: operand, level: level, kind: kind)
        state = .editing
    }
}
