//
//  PaletteDragModel.swift
//  MayanMath
//
//  Estado del arrastre de una ficha de la paleta hacia un nivel.
//  Es estado de la vista (no del negocio): dónde está el dedo, qué ficha
//  se arrastra y sobre qué nivel está. Los niveles registran su marco
//  en el espacio de coordenadas de la pantalla para saber dónde cae la ficha.
//

import SwiftUI

/// Identifica un nivel donde se puede soltar una ficha.
struct DropZoneID: Hashable {
    let operand: CalculatorOperand
    let level: Int
}

@Observable
final class PaletteDragModel {
    /// Nombre del espacio de coordenadas compartido por la paleta, los niveles y la ficha flotante.
    static let coordinateSpace = "paletteDrag"

    private(set) var digit: MayanDigit?
    private(set) var location: CGPoint = .zero
    private(set) var hoveredZone: DropZoneID?

    /// Marcos de los niveles. No se observa: cambia seguido y solo lo lee el gesto.
    @ObservationIgnored private var zoneFrames: [DropZoneID: CGRect] = [:]

    var isDragging: Bool { digit != nil }

    func register(_ zone: DropZoneID, frame: CGRect) {
        zoneFrames[zone] = frame
    }

    /// El dedo se movió con una ficha.
    func move(_ digit: MayanDigit, to location: CGPoint) {
        if self.digit != digit { self.digit = digit }
        self.location = location
        let zone = zoneFrames.first { $0.value.contains(location) }?.key
        if zone != hoveredZone { hoveredZone = zone }
    }

    /// El dedo se levantó. Devuelve la ficha y el nivel si cayó sobre uno.
    func end() -> (digit: MayanDigit, zone: DropZoneID)? {
        defer {
            digit = nil
            hoveredZone = nil
        }
        guard let digit, let hoveredZone else { return nil }
        return (digit, hoveredZone)
    }
}

/// Ficha que sigue al dedo mientras se arrastra.
struct DraggedTileGhost: View {
    let digit: MayanDigit
    let isOverZone: Bool

    var body: some View {
        MayanDigitGlyph(digit: digit, scale: 0.6)
            .padding(16)
            .frame(minWidth: 84, minHeight: 84)
            .background(Palette.tile, in: RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous)
                    .strokeBorder(Palette.green, lineWidth: isOverZone ? 3 : 0)
            )
            .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
            .scaleEffect(isOverZone ? 0.9 : 1.08)
            .rotationEffect(.degrees(isOverZone ? 0 : -4))
            .animation(.spring(duration: 0.25, bounce: 0.4), value: isOverZone)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
