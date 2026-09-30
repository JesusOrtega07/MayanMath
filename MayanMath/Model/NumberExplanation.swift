//
//  NumberExplanation.swift
//  MayanMath
//
//  Cómo se compone un número maya, nivel por nivel. Lógica pura: la vista
//  convierte esto en frases ("2 barras y 3 puntos = 13").
//

import Foundation

/// Lo que hay en un nivel y cuánto aporta al total.
nonisolated struct LevelBreakdown: Hashable, Identifiable, Sendable {
    let level: Int
    let digit: MayanDigit

    var id: Int { level }
    var placeValue: Int { MayanNumber.placeValue(ofLevel: level) }
    var contribution: Int { digit.value * placeValue }
    var barsValue: Int { digit.bars * MayanDigit.barValue }
}

/// Etapa de aprendizaje del número: decide qué explicación amigable mostrar.
nonisolated enum NumberStage: Hashable, Sendable {
    case zero          // 0: la concha
    case onlyDots      // 1…4
    case firstBar      // 5
    case barsAndDots   // 6…19
    case twenty        // 20: primer número con dos niveles
    case withTwenties  // 21 en adelante
}

nonisolated struct NumberExplanation: Hashable, Sendable {
    let number: MayanNumber

    init(_ value: Int) {
        self.number = MayanNumber(value)
    }

    /// Niveles de arriba hacia abajo.
    var levels: [LevelBreakdown] {
        number.breakdown.map { LevelBreakdown(level: $0.level, digit: $0.digit) }
    }

    var usesTwoLevels: Bool { number.levelCount > 1 }

    var stage: NumberStage {
        switch number.value {
        case 0: .zero
        case 1...4: .onlyDots
        case 5: .firstBar
        case 6...19: .barsAndDots
        case 20: .twenty
        default: .withTwenties
        }
    }

    /// Sumandos por nivel, de arriba hacia abajo: 23 → [20, 3].
    var addends: [Int] { levels.map(\.contribution) }
}
