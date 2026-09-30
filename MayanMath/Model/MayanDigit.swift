//
//  MayanDigit.swift
//  MayanMath
//
//  Un dígito maya: el valor de UN nivel (0…19).
//  Se dibuja con barras (valen 5) y puntos (valen 1); el 0 es la concha.
//

import Foundation

/// Símbolo individual con el que se dibuja un dígito maya.
nonisolated enum MayanSymbol: Hashable, Sendable {
    case dot    // 1
    case bar    // 5
    case shell  // 0

    var value: Int {
        switch self {
        case .dot: 1
        case .bar: 5
        case .shell: 0
        }
    }
}

nonisolated struct MayanDigit: Hashable, Comparable, Identifiable, Sendable {
    /// Base del sistema maya (vigesimal).
    static let base = 20
    /// Valor de una barra.
    static let barValue = 5

    let value: Int
    var id: Int { value }

    /// Devuelve `nil` si el valor no cabe en un nivel (0…19).
    init?(_ value: Int) {
        guard (0..<Self.base).contains(value) else { return nil }
        self.value = value
    }

    private init(uncheckedValue: Int) {
        self.value = uncheckedValue
    }

    // MARK: Composición

    var bars: Int { value / Self.barValue }
    var dots: Int { value % Self.barValue }
    var isZero: Bool { value == 0 }

    /// Símbolos de arriba hacia abajo, como se dibujan: puntos arriba, barras abajo.
    /// El 0 es una sola concha.
    var symbols: [MayanSymbol] {
        guard !isZero else { return [.shell] }
        return Array(repeating: .dot, count: dots) + Array(repeating: .bar, count: bars)
    }

    // MARK: Catálogo

    static let zero = MayanDigit(uncheckedValue: 0)

    /// Los 20 dígitos posibles (0…19). Útil para la tabla de referencia.
    static let all: [MayanDigit] = (0..<base).map(MayanDigit.init(uncheckedValue:))

    /// Fichas de la paleta, en el orden de las vistas: 1…9 y al final la concha (0).
    static let palette: [MayanDigit] = (1...9).map(MayanDigit.init(uncheckedValue:)) + [zero]

    static func < (lhs: MayanDigit, rhs: MayanDigit) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Codable (valida el rango al decodificar)

nonisolated extension MayanDigit: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        guard let digit = MayanDigit(raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Un dígito maya debe estar entre 0 y 19; se recibió \(raw)."
            )
        }
        self = digit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
