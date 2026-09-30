//
//  Challenge.swift
//  MayanMath
//
//  Retos "número decimal → número maya": catálogo, evaluación, pistas y estrellas.
//

import Foundation

nonisolated enum ChallengeCatalog {
    /// Números de los retos, en orden.
    static let numbers: [Int] = Array(1...30)

    static var first: Int { numbers[0] }

    static func next(after number: Int) -> Int? {
        guard let index = numbers.firstIndex(of: number), index + 1 < numbers.count else { return nil }
        return numbers[index + 1]
    }

    static func previous(before number: Int) -> Int? {
        guard let index = numbers.firstIndex(of: number), index > 0 else { return nil }
        return numbers[index - 1]
    }

    /// Primer reto sin completar (o el último si ya están todos).
    static func firstPending(completed: Set<Int>) -> Int {
        numbers.first { !completed.contains($0) } ?? numbers[numbers.count - 1]
    }

    static func position(of number: Int) -> Int? {
        numbers.firstIndex(of: number).map { $0 + 1 }
    }
}

nonisolated enum ChallengeScoring {
    static let firstTryStars = 10
    static let laterStars = 5

    /// 10 estrellas al primer intento, 5 después.
    static func stars(forAttempts attempts: Int) -> Int {
        attempts <= 1 ? firstTryStars : laterStars
    }
}

/// Resultado de tocar "Comprobar".
nonisolated enum ChallengeFeedback: Hashable, Sendable {
    case correct
    /// No hay nada construido.
    case empty
    /// El nivel de 20 no coincide.
    case wrongTwenties(tooMany: Bool)
    /// El nivel de 20 está bien pero el de 1 no.
    case wrongUnits(tooMany: Bool)

    /// Nivel que conviene señalar (sacudir) en la vista.
    var levelToHighlight: Int? {
        switch self {
        case .wrongTwenties: 1
        case .wrongUnits: 0
        case .correct, .empty: nil
        }
    }
}

nonisolated enum ChallengeEvaluator {
    static func evaluate(target: MayanNumber, built: MayanNumberBuilder) -> ChallengeFeedback {
        guard let number = built.number else { return .empty }
        if number.value == target.value { return .correct }

        let expectedTwenties = target.digit(atLevel: 1).value
        let builtTwenties = number.digit(atLevel: 1).value
        if expectedTwenties != builtTwenties {
            return .wrongTwenties(tooMany: builtTwenties > expectedTwenties)
        }
        return .wrongUnits(tooMany: number.digit(atLevel: 0).value > target.digit(atLevel: 0).value)
    }
}

/// Pistas que se revelan una a una.
nonisolated enum ChallengeHint: Hashable, Identifiable, Sendable {
    /// Cuántos puntos van en el nivel de 20 (0 = ninguno).
    case twenties(target: Int, count: Int)
    /// Qué va en el nivel de 1.
    case units(digit: MayanDigit)
    /// Se muestra el número resuelto.
    case solution(MayanNumber)

    var id: Int {
        switch self {
        case .twenties: 0
        case .units: 1
        case .solution: 2
        }
    }

    static func hints(for target: MayanNumber) -> [ChallengeHint] {
        [
            .twenties(target: target.value, count: target.digit(atLevel: 1).value),
            .units(digit: target.digit(atLevel: 0)),
            .solution(target)
        ]
    }
}
