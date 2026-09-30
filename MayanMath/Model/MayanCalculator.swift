//
//  MayanCalculator.swift
//  MayanMath
//
//  Motor de operaciones. Lógica pura, sin UI.
//

import Foundation

nonisolated enum MayanOperation: String, CaseIterable, Identifiable, Sendable, Codable {
    case addition
    case subtraction
    case multiplication
    case division

    var id: Self { self }

    /// Signo para mostrar entre los operandos.
    var symbol: String {
        switch self {
        case .addition: "+"
        case .subtraction: "−"
        case .multiplication: "×"
        case .division: "÷"
        }
    }

    /// SF Symbol del botón.
    var systemImage: String {
        switch self {
        case .addition: "plus"
        case .subtraction: "minus"
        case .multiplication: "multiply"
        case .division: "divide"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .addition: LocalizedStringResource("operation.addition", defaultValue: "Suma")
        case .subtraction: LocalizedStringResource("operation.subtraction", defaultValue: "Resta")
        case .multiplication: LocalizedStringResource("operation.multiplication", defaultValue: "Multiplicación")
        case .division: LocalizedStringResource("operation.division", defaultValue: "División")
        }
    }
}

nonisolated struct CalculationResult: Hashable, Sendable {
    let lhs: MayanNumber
    let operation: MayanOperation
    let rhs: MayanNumber
    /// Resultado (en división, el cociente).
    let value: MayanNumber
    /// Solo en división.
    let remainder: MayanNumber?

    var hasRemainder: Bool { (remainder?.value ?? 0) > 0 }
}

nonisolated enum CalculationError: Error, Hashable, Sendable {
    /// Resta con el primer número menor que el segundo: los mayas no usaban negativos.
    case negativeResult
    case divisionByZero
    /// El resultado no cabe en los niveles permitidos.
    case overflow(maxValue: Int)

    var message: LocalizedStringResource {
        switch self {
        case .negativeResult:
            LocalizedStringResource(
                "error.negativeResult",
                defaultValue: "El primer número debe ser mayor o igual que el segundo."
            )
        case .divisionByZero:
            LocalizedStringResource(
                "error.divisionByZero",
                defaultValue: "No se puede dividir entre cero."
            )
        case .overflow(let maxValue):
            LocalizedStringResource(
                "error.overflow",
                defaultValue: "El resultado es muy grande. El máximo es \(maxValue)."
            )
        }
    }
}

nonisolated enum MayanCalculator {
    /// Calcula `lhs <operación> rhs`.
    /// La división es entera: devuelve cociente y residuo.
    static func calculate(
        _ lhs: MayanNumber,
        _ operation: MayanOperation,
        _ rhs: MayanNumber,
        maxValue: Int = MayanLimits.maxResultValue
    ) throws(CalculationError) -> CalculationResult {
        let a = lhs.value
        let b = rhs.value
        let raw: Int
        var remainder: Int?

        switch operation {
        case .addition:
            raw = a + b
        case .subtraction:
            guard a >= b else { throw .negativeResult }
            raw = a - b
        case .multiplication:
            let (product, overflowed) = a.multipliedReportingOverflow(by: b)
            guard !overflowed else { throw .overflow(maxValue: maxValue) }
            raw = product
        case .division:
            guard b != 0 else { throw .divisionByZero }
            raw = a / b
            remainder = a % b
        }

        guard raw <= maxValue else { throw .overflow(maxValue: maxValue) }

        return CalculationResult(
            lhs: lhs,
            operation: operation,
            rhs: rhs,
            value: MayanNumber(raw),
            remainder: remainder.map { MayanNumber($0) }
        )
    }
}
