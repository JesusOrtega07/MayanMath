//
//  ChallengeViewModel.swift
//  MayanMath
//
//  Reto: "Forma el 23 en maya".
//  Construir → Comprobar → (mal) reintentar / pedir pista → (bien) estrellas → siguiente.
//

import Foundation
import Observation

nonisolated enum ChallengePhase: Hashable, Sendable {
    case building
    case wrong(ChallengeFeedback)
    case correct(earnedStars: Int)
}

@Observable
final class ChallengeViewModel {
    private(set) var target: MayanNumber
    private(set) var builder = MayanNumberBuilder(maxLevels: 2)
    private(set) var phase: ChallengePhase = .building
    /// Veces que se tocó "Comprobar" con algo construido en este reto.
    private(set) var attempts = 0
    private(set) var revealedHints = 0
    /// Nivel que recibe las fichas tocadas en la paleta.
    var activeLevel = 0
    private(set) var lastChange: BuilderChange?
    /// Aumenta con cada intento fallido (para animar el error).
    private(set) var failureCount = 0

    private var repository: ProgressRepository?

    init(number: Int = ChallengeCatalog.first) {
        self.target = MayanNumber(number)
    }

    /// Conecta el guardado de progreso (lo hace la vista con su ModelContext).
    func attach(_ repository: ProgressRepository) {
        self.repository = repository
    }

    // MARK: - Lectura

    var hints: [ChallengeHint] { ChallengeHint.hints(for: target) }
    var visibleHints: [ChallengeHint] { Array(hints.prefix(revealedHints)) }
    var canRevealHint: Bool { revealedHints < hints.count && !isSolved }

    var isSolved: Bool {
        if case .correct = phase { return true }
        return false
    }

    /// Después de fallar sin haber pedido pistas, se sugiere una.
    var shouldSuggestHint: Bool {
        if case .wrong(let feedback) = phase, feedback != .empty {
            return revealedHints == 0
        }
        return false
    }

    var hasNext: Bool { ChallengeCatalog.next(after: target.value) != nil }
    var hasPrevious: Bool { ChallengeCatalog.previous(before: target.value) != nil }

    // MARK: - Navegación entre retos

    func select(_ number: Int) {
        target = MayanNumber(number)
        builder.clear()
        phase = .building
        attempts = 0
        revealedHints = 0
        activeLevel = number >= MayanDigit.base ? 1 : 0
        lastChange = nil
    }

    func next() {
        if let number = ChallengeCatalog.next(after: target.value) { select(number) }
    }

    func previous() {
        if let number = ChallengeCatalog.previous(before: target.value) { select(number) }
    }

    /// Vuelve a intentar el mismo reto desde cero.
    func retry() {
        builder.clear()
        phase = .building
    }

    // MARK: - Construcción

    func focus(level: Int) {
        activeLevel = min(max(level, 0), builder.maxLevels - 1)
    }

    @discardableResult
    func drop(_ digit: MayanDigit, onLevel level: Int) -> Bool {
        guard !isSolved else { return false }
        focus(level: level)
        do {
            let events = try builder.add(digit, toLevel: level)
            record(level: level, .added(digit, regroupings: events))
            return true
        } catch let error as BuilderError {
            lastChange = BuilderChange(operand: .first, level: level, kind: .rejected(error))
            return false
        } catch {
            return false
        }
    }

    @discardableResult
    func dropOnActiveLevel(_ digit: MayanDigit) -> Bool {
        drop(digit, onLevel: activeLevel)
    }

    func removeSymbol(_ symbol: MayanSymbol, fromLevel level: Int) {
        guard !isSolved else { return }
        do {
            try builder.remove(symbol, fromLevel: level)
            record(level: level, .removed(symbol))
        } catch let error as BuilderError {
            lastChange = BuilderChange(operand: .first, level: level, kind: .rejected(error))
        } catch {}
    }

    func clear() {
        guard !isSolved else { return }
        builder.clear()
        record(level: nil, .clearedOperand)
    }

    // MARK: - Comprobar y pistas

    func check() {
        guard !isSolved else { return }
        let feedback = ChallengeEvaluator.evaluate(target: target, built: builder)
        switch feedback {
        case .empty:
            phase = .wrong(.empty)
        case .correct:
            attempts += 1
            let earned = repository?.saveCompletion(number: target.value,
                                                    attempts: attempts,
                                                    hintsUsed: revealedHints)
                ?? ChallengeScoring.stars(forAttempts: attempts)
            phase = .correct(earnedStars: earned)
        case .wrongTwenties, .wrongUnits:
            attempts += 1
            failureCount += 1
            phase = .wrong(feedback)
        }
    }

    func revealHint() {
        guard canRevealHint else { return }
        revealedHints += 1
    }

    // MARK: - Privado

    /// Cualquier edición quita el mensaje de error anterior.
    private func record(level: Int?, _ kind: BuilderChange.Kind) {
        lastChange = BuilderChange(operand: .first, level: level, kind: kind)
        if case .wrong = phase { phase = .building }
    }
}
