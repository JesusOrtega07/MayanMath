//
//  MayanGlyphs.swift
//  MayanMath
//
//  Dibujo de los números mayas: punto, barra y concha.
//  Medidas del Figma (tamaño grande): barra 80×10, punto 16, separación 8.
//

import SwiftUI

/// La concha (cero). Usa la imagen `conchaCero` de Assets en modo plantilla,
/// así toma el color del texto como los puntos y las barras.
struct ShellGlyph: View {
    var width: CGFloat = 80

    var body: some View {
        Image("conchaCero")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            // La imagen trae margen transparente; se compensa para que mida como una barra.
            .frame(width: width * 1.2, height: width * 0.75)
            .accessibilityHidden(true)
    }
}

/// Un dígito maya (0…19): puntos arriba, barras abajo, o la concha.
struct MayanDigitGlyph: View {
    let digit: MayanDigit
    /// 1 = tamaño grande del Figma (área de construcción); 0.6 = paleta.
    var scale: CGFloat = 1
    var color: Color = Palette.glyph

    private var barWidth: CGFloat { 80 * scale }
    private var barHeight: CGFloat { 10 * scale }
    private var dotSize: CGFloat { 16 * scale }
    private var spacing: CGFloat { 8 * scale }

    var body: some View {
        Group {
            if digit.isZero {
                ShellGlyph(width: barWidth)
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: spacing) {
                    if digit.dots > 0 {
                        HStack(spacing: spacing) {
                            ForEach(0..<digit.dots, id: \.self) { _ in
                                Circle()
                                    .frame(width: dotSize, height: dotSize)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    ForEach(0..<digit.bars, id: \.self) { _ in
                        Capsule()
                            .frame(width: barWidth, height: barHeight)
                            .transition(.scale(scale: 0.4, anchor: .center).combined(with: .opacity))
                    }
                }
            }
        }
        .foregroundStyle(color)
        .animation(.spring(duration: 0.45, bounce: 0.4), value: digit)
        .accessibilityElement()
        .accessibilityLabel(Text("\(digit.value)"))
    }
}

/// Número maya completo apilado de arriba (nivel alto) hacia abajo (unidades).
struct MayanNumberGlyph: View {
    let number: MayanNumber
    var scale: CGFloat = 1
    var color: Color = Palette.glyph
    /// Líneas finas entre niveles, como en las tarjetas de operación.
    var showsSeparators = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(number.digitsTopToBottom.enumerated()), id: \.offset) { index, digit in
                if index > 0 && showsSeparators {
                    Rectangle()
                        .fill(Palette.green.opacity(0.35))
                        .frame(height: 1)
                }
                MayanDigitGlyph(digit: digit, scale: scale, color: color)
                    .frame(minHeight: 110 * scale)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(number.value)"))
    }
}

#Preview("Glifos 0–19", traits: .landscapeLeft) {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 24) {
        ForEach(MayanDigit.all) { digit in
            VStack {
                MayanDigitGlyph(digit: digit, scale: 0.6)
                    .frame(height: 90)
                Text("\(digit.value)").font(.rounded(18))
            }
        }
    }
    .padding()
}
