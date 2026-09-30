//
//  ChallengeRecord.swift
//  MayanMath
//
//  Progreso guardado con SwiftData (un solo perfil por iPad).
//

import Foundation
import SwiftData

/// Un reto completado. Si se repite, se conserva la mejor puntuación.
@Model
final class ChallengeRecord {
    @Attribute(.unique) var number: Int
    var stars: Int
    var attempts: Int
    var hintsUsed: Int
    var completedAt: Date

    init(number: Int, stars: Int, attempts: Int, hintsUsed: Int, completedAt: Date = .now) {
        self.number = number
        self.stars = stars
        self.attempts = attempts
        self.hintsUsed = hintsUsed
        self.completedAt = completedAt
    }
}

/// Acceso al progreso. El ViewModel lo usa sin saber de SwiftData.
final class ProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func record(for number: Int) -> ChallengeRecord? {
        let target = number
        let descriptor = FetchDescriptor<ChallengeRecord>(predicate: #Predicate { $0.number == target })
        return try? context.fetch(descriptor).first
    }

    /// Guarda un reto resuelto y devuelve las estrellas NUEVAS ganadas
    /// (al repetir un reto solo se suma la diferencia si se mejora).
    @discardableResult
    func saveCompletion(number: Int, attempts: Int, hintsUsed: Int) -> Int {
        let stars = ChallengeScoring.stars(forAttempts: attempts)

        if let existing = record(for: number) {
            let gained = max(0, stars - existing.stars)
            if stars > existing.stars {
                existing.stars = stars
                existing.attempts = attempts
                existing.hintsUsed = hintsUsed
            }
            existing.completedAt = .now
            try? context.save()
            return gained
        }

        context.insert(ChallengeRecord(number: number, stars: stars, attempts: attempts, hintsUsed: hintsUsed))
        try? context.save()
        return stars
    }
}
