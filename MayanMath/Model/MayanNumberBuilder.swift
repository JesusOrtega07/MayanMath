//
//  MayanNumberBuilder.swift
//  MayanMath
//
//  Estado del "Área de construcción": lo que el usuario arma arrastrando fichas.
//
//  Reglas:
//  • Las fichas que se sueltan en un nivel SE SUMAN (5 + 5 + 3 → 13).
//  • 5 puntos se juntan en una barra dentro del mismo nivel.
//  • Si un nivel llega a 20, sube un punto al nivel superior y se queda con el resto.
//  • Soltar la concha (0) en un nivel vacío lo marca como 0; en uno con valor no cambia nada.
//  • Tocar un punto resta 1, tocar una barra resta 5, tocar la concha vacía el nivel.
//

import Foundation

/// Lo que se ve en un nivel del área de construcción.
nonisolated enum LevelContent: Hashable, Sendable {
    /// Hueco sin nada (por encima del número o todo vacío).
    case empty
    case digit(MayanDigit)
}

/// Reagrupaciones que ocurrieron al soltar una ficha. La vista las usa para animar.
nonisolated enum RegroupEvent: Hashable, Sendable {
    /// `count` grupos de 5 puntos se juntaron en barras dentro de `level`.
    case dotsBecameBar(level: Int, count: Int)
    /// El nivel `fromLevel` llegó a 20: sube `dots` punto(s) a `toLevel`.
    case carried(fromLevel: Int, toLevel: Int, dots: Int)
}

nonisolated enum BuilderError: Error, Hashable, Sendable {
    /// El nivel no existe en esta área de construcción.
    case levelOutOfRange(Int)
    /// La ficha haría que el número pase del máximo permitido.
    case overflow(maxValue: Int)
    /// No hay ese símbolo en el nivel.
    case nothingToRemove
}

nonisolated struct MayanNumberBuilder: Hashable, Sendable {
    let maxLevels: Int
    /// Valor de cada nivel. Índice 0 = unidades. `nil` = nivel sin tocar.
    private(set) var levels: [Int?]

    init(maxLevels: Int = MayanLimits.inputLevels) {
        precondition(maxLevels > 0, "Se necesita al menos un nivel.")
        self.maxLevels = maxLevels
        self.levels = Array(repeating: nil, count: maxLevels)
    }

    /// Carga un número ya hecho (p. ej. el resultado anterior para seguir calculando).
    init(number: MayanNumber, maxLevels: Int = MayanLimits.inputLevels) throws(BuilderError) {
        self.init(maxLevels: maxLevels)
        guard number.levelCount <= maxLevels else {
            throw .overflow(maxValue: MayanNumber.maxValue(levels: maxLevels))
        }
        for level in 0..<number.levelCount {
            levels[level] = number.digit(atLevel: level).value
        }
    }

    // MARK: Consulta

    var isEmpty: Bool { levels.allSatisfy { $0 == nil } }

    var maxValue: Int { MayanNumber.maxValue(levels: maxLevels) }

    /// Valor decimal de lo construido (los niveles vacíos cuentan como 0).
    var value: Int {
        levels.enumerated().reduce(0) { total, level in
            total + (level.element ?? 0) * MayanNumber.placeValue(ofLevel: level.offset)
        }
    }

    /// `nil` mientras no haya nada construido.
    var number: MayanNumber? { isEmpty ? nil : MayanNumber(value) }

    /// Nivel más alto que tiene algo.
    var highestUsedLevel: Int? { levels.lastIndex { $0 != nil } }

    /// Qué dibujar en un nivel. Los huecos por debajo del nivel más alto
    /// se muestran como concha, porque en notación posicional el 0 se escribe.
    func content(atLevel level: Int) -> LevelContent {
        guard levels.indices.contains(level), let highest = highestUsedLevel, level <= highest else {
            return .empty
        }
        return .digit(MayanDigit(levels[level] ?? 0) ?? .zero)
    }

    /// Contenido de todos los niveles, de arriba hacia abajo (como se dibuja).
    var contentTopToBottom: [(level: Int, content: LevelContent)] {
        levels.indices.reversed().map { ($0, content(atLevel: $0)) }
    }

    // MARK: Edición

    /// Suelta una ficha de la paleta en un nivel.
    /// Si lanza un error, el constructor no cambia.
    @discardableResult
    mutating func add(_ digit: MayanDigit, toLevel level: Int) throws(BuilderError) -> [RegroupEvent] {
        try validate(level)

        if digit.isZero {
            if levels[level] == nil { levels[level] = 0 }
            return []
        }

        var working = levels
        var events: [RegroupEvent] = []

        let old = working[level] ?? 0
        let mergedBars = (old % MayanDigit.barValue + digit.dots) / MayanDigit.barValue
        if mergedBars > 0 {
            events.append(.dotsBecameBar(level: level, count: mergedBars))
        }
        working[level] = old + digit.value

        // Llevar al nivel superior mientras algún nivel llegue a 20.
        var current = level
        while let raw = working[current], raw >= MayanDigit.base {
            let carry = raw / MayanDigit.base
            working[current] = raw % MayanDigit.base

            let upper = current + 1
            guard upper < maxLevels else { throw .overflow(maxValue: maxValue) }

            let upperOld = working[upper] ?? 0
            events.append(.carried(fromLevel: current, toLevel: upper, dots: carry))
            let upperMerged = (upperOld % MayanDigit.barValue + carry) / MayanDigit.barValue
            if upperMerged > 0 {
                events.append(.dotsBecameBar(level: upper, count: upperMerged))
            }
            working[upper] = upperOld + carry
            current = upper
        }

        levels = working
        return events
    }

    /// Quita un símbolo tocado en un nivel: punto −1, barra −5, concha vacía el nivel.
    mutating func remove(_ symbol: MayanSymbol, fromLevel level: Int) throws(BuilderError) {
        try validate(level)
        guard let current = levels[level] else { throw .nothingToRemove }

        switch symbol {
        case .dot:
            guard current % MayanDigit.barValue > 0 else { throw .nothingToRemove }
            levels[level] = current - 1
        case .bar:
            guard current >= MayanDigit.barValue else { throw .nothingToRemove }
            levels[level] = current - MayanDigit.barValue
        case .shell:
            guard current == 0 else { throw .nothingToRemove }
            levels[level] = nil
        }
    }

    mutating func clearLevel(_ level: Int) throws(BuilderError) {
        try validate(level)
        levels[level] = nil
    }

    mutating func clear() {
        levels = Array(repeating: nil, count: maxLevels)
    }

    private func validate(_ level: Int) throws(BuilderError) {
        guard levels.indices.contains(level) else { throw .levelOutOfRange(level) }
    }
}
