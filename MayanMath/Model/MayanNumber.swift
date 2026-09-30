//
//  MayanNumber.swift
//  MayanMath
//
//  Número maya completo: una pila de dígitos, uno por nivel.
//  Nivel 0 = unidades (abajo), nivel 1 = veintenas, nivel 2 = 400s, …
//  Se dibuja y se lee de arriba (nivel más alto) hacia abajo (unidades).
//

import Foundation

/// Límites de la app.
nonisolated enum MayanLimits {
    /// Niveles que el usuario puede construir: unidades y veintenas → 0…399.
    static let inputLevels = 2
    /// Niveles que puede tener un resultado: hasta los 160,000s → 0…3,199,999.
    static let resultLevels = 5

    static var maxInputValue: Int { MayanNumber.maxValue(levels: inputLevels) }   // 399
    static var maxResultValue: Int { MayanNumber.maxValue(levels: resultLevels) } // 3,199,999
}

/// Aportación de un nivel al total. Ej.: nivel 1 con dígito 3 → 3 × 20 = 60.
nonisolated struct PlaceValueTerm: Hashable, Identifiable, Sendable {
    let level: Int
    let digit: MayanDigit
    let placeValue: Int

    var id: Int { level }
    var contribution: Int { digit.value * placeValue }
}

nonisolated struct MayanNumber: Hashable, Comparable, Sendable, CustomStringConvertible {
    /// Dígitos por nivel. Índice 0 = unidades. Nunca vacío y sin ceros sobrantes arriba.
    let digits: [MayanDigit]
    /// Valor decimal.
    let value: Int

    /// Convierte un entero no negativo dividiendo entre 20 repetidamente.
    init(_ value: Int) {
        precondition(value >= 0, "El sistema maya no representa números negativos.")
        var remaining = value
        var result: [MayanDigit] = []
        repeat {
            result.append(MayanDigit.all[remaining % MayanDigit.base])
            remaining /= MayanDigit.base
        } while remaining > 0
        self.digits = result
        self.value = value
    }

    /// Construye a partir de dígitos (índice 0 = unidades). Quita ceros sobrantes arriba.
    init(digits: [MayanDigit]) {
        var trimmed = digits
        while trimmed.count > 1, trimmed.last?.isZero == true {
            trimmed.removeLast()
        }
        if trimmed.isEmpty { trimmed = [.zero] }
        self.digits = trimmed
        self.value = trimmed.enumerated().reduce(0) { total, level in
            total + level.element.value * Self.placeValue(ofLevel: level.offset)
        }
    }

    static let zero = MayanNumber(0)

    // MARK: Consulta

    var levelCount: Int { digits.count }

    /// Dígito de un nivel; los niveles por encima del número valen 0.
    func digit(atLevel level: Int) -> MayanDigit {
        digits.indices.contains(level) ? digits[level] : .zero
    }

    /// De arriba hacia abajo: el orden en que se dibuja y se lee.
    var digitsTopToBottom: [MayanDigit] { digits.reversed() }

    /// Dígitos rellenados con ceros hasta `levels` niveles (índice 0 = unidades).
    func padded(toLevels levels: Int) -> [MayanDigit] {
        (0..<max(levels, levelCount)).map { digit(atLevel: $0) }
    }

    /// Desglose por valor posicional, de arriba hacia abajo.
    /// 315 → [15 × 20 = 300, 15 × 1 = 15]
    var breakdown: [PlaceValueTerm] {
        digits.indices.reversed().map {
            PlaceValueTerm(level: $0, digit: digits[$0], placeValue: Self.placeValue(ofLevel: $0))
        }
    }

    /// Notación vigesimal de arriba hacia abajo. 315 → "15.15"
    var vigesimalNotation: String {
        digitsTopToBottom.map { String($0.value) }.joined(separator: ".")
    }

    var description: String { "\(vigesimalNotation) (\(value))" }

    // MARK: Utilidades

    /// 20^nivel → 1, 20, 400, 8,000, 160,000…
    static func placeValue(ofLevel level: Int) -> Int {
        precondition(level >= 0)
        var result = 1
        for _ in 0..<level { result *= MayanDigit.base }
        return result
    }

    /// Valor máximo que caben en `levels` niveles. 3 → 7,999.
    static func maxValue(levels: Int) -> Int {
        placeValue(ofLevel: levels) - 1
    }

    static func < (lhs: MayanNumber, rhs: MayanNumber) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Codable (se guarda solo el valor decimal)

nonisolated extension MayanNumber: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        guard raw >= 0 else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Un número maya no puede ser negativo; se recibió \(raw)."
            )
        }
        self.init(raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
