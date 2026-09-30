//
//  SymbolPalette.swift
//  MayanMath
//
//  Paleta de fichas 1…9 y la concha (0).
//  • Arrastra una ficha: sigue al dedo desde el primer movimiento y cae en el nivel.
//  • Tócala: se pone en el nivel seleccionado.
//

import SwiftUI

struct SymbolPalette: View {
    let drag: PaletteDragModel
    var onChoose: (MayanDigit) -> Void
    var onDrop: (MayanDigit, DropZoneID) -> Void
    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Paleta de símbolos mayas \(Text("(arrastra o toca)").fontWeight(.semibold))")
                .font(.rounded(18, weight: .black))
                .foregroundStyle(Palette.greenText)

            HStack(spacing: 10) {
                ForEach(MayanDigit.palette) { digit in
                    PaletteTile(
                        digit: digit,
                        drag: drag,
                        onTap: { onChoose(digit) },
                        onDrop: { zone in onDrop(digit, zone) }
                    )
                }

                Button(action: onClear) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Palette.green, in: Circle())
                        Text("Borrar todo")
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Palette.navActiveText)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .padding(.horizontal, 6)
                }
                .buttonStyle(LiftButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .mmPanel()
    }
}

/// Una ficha de la paleta. Un solo gesto decide si fue toque o arrastre.
struct PaletteTile: View {
    let digit: MayanDigit
    let drag: PaletteDragModel
    var onTap: () -> Void
    var onDrop: (DropZoneID) -> Void

    @State private var isPressed = false
    @State private var isDraggingThis = false

    /// Distancia mínima para considerar que es arrastre y no toque.
    private let dragThreshold: CGFloat = 6

    var body: some View {
        VStack(spacing: 6) {
            MayanDigitGlyph(digit: digit, scale: 0.42)
                .frame(height: 44)
            Text(digit.value, format: .number)
                .font(.rounded(20, weight: .black))
                .foregroundStyle(Color(hex: 0x111111))
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(isPressed ? Palette.tilePressed : Palette.tile,
                    in: RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Metrics.tileRadius))
        // La ficha "se queda" semitransparente mientras su copia viaja con el dedo.
        .opacity(isDraggingThis ? 0.45 : 1)
        .scaleEffect(isPressed && !isDraggingThis ? 0.95 : 1)
        .animation(.spring(duration: 0.25, bounce: 0.4), value: isPressed)
        .animation(.easeOut(duration: 0.2), value: isDraggingThis)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(PaletteDragModel.coordinateSpace))
                .onChanged { value in
                    isPressed = true
                    let distance = hypot(value.translation.width, value.translation.height)
                    if isDraggingThis || distance > dragThreshold {
                        isDraggingThis = true
                        drag.move(digit, to: value.location)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    if isDraggingThis {
                        isDraggingThis = false
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            if let dropped = drag.end() {
                                onDrop(dropped.zone)
                            }
                        }
                    } else {
                        onTap()
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Ficha \(digit.value)"))
        .accessibilityHint(Text("Toca para ponerla en el nivel elegido, o arrástrala a un nivel"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }
}
