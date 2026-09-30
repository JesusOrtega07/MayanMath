//
//  LearningComponents.swift
//  MayanMath
//
//  Piezas compartidas por Números y Retos: frases de composición,
//  número maya con sus niveles etiquetados y botón de audio.
//

import SwiftUI

/// Frases para explicar cómo se forma un dígito maya.
enum MayanPhrases {
    /// "2 barras y 3 puntos", "1 punto", "una concha".
    static func composition(_ digit: MayanDigit) -> LocalizedStringKey {
        if digit.isZero { return "una concha" }
        if digit.bars == 0 { return "^[\(digit.dots) punto](inflect: true)" }
        if digit.dots == 0 { return "^[\(digit.bars) barra](inflect: true)" }
        return "^[\(digit.bars) barra](inflect: true) y ^[\(digit.dots) punto](inflect: true)"
    }

    /// "2 × 5 + 3 = 13", "3", "0".
    static func arithmetic(_ digit: MayanDigit) -> String {
        switch (digit.bars, digit.dots) {
        case (0, let dots): "\(dots)"
        case (let bars, 0): "\(bars) × 5 = \(bars * 5)"
        case (let bars, let dots): "\(bars) × 5 + \(dots) = \(digit.value)"
        }
    }

    static func levelName(_ level: Int) -> LocalizedStringKey {
        level == 0 ? "Nivel de 1 (unidades)" : "Nivel de 20 (veintenas)"
    }
}

/// Número maya dibujado en cajas por nivel (20 arriba, 1 abajo) con su valor a la derecha.
struct LabeledMayanNumber: View {
    let number: MayanNumber
    /// Muestra también el nivel de 20 (vacío) cuando el número es menor que 20.
    var alwaysShowTwoLevels = true
    var glyphScale: CGFloat = 0.7
    var boxHeight: CGFloat = 100

    var body: some View {
        let levels = alwaysShowTwoLevels ? max(2, number.levelCount) : number.levelCount
        VStack(spacing: 10) {
            ForEach((0..<levels).reversed(), id: \.self) { level in
                let isUsed = level < number.levelCount
                let isGold = level == 0
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isGold ? Palette.zoneGoldFill : Palette.zoneGreenFill)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isGold ? Palette.zoneGoldBorder : Palette.zoneGreenBorder,
                                      style: StrokeStyle(lineWidth: 2, dash: isUsed ? [] : [6, 5]))
                    if isUsed {
                        MayanDigitGlyph(digit: number.digit(atLevel: level), scale: glyphScale)
                    }
                    Text(MayanNumber.placeValue(ofLevel: level), format: .number)
                        .font(.rounded(20, weight: .black))
                        .foregroundStyle((isGold ? Palette.zoneGoldBorder : Palette.zoneGreenBorder).opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 12)
                }
                .frame(height: boxHeight)
                .opacity(isUsed ? 1 : 0.55)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(number.value) en números mayas"))
    }
}

/// Botón verde de bocina que dice el número en voz alta.
struct SpeakNumberButton: View {
    let value: Int
    let language: AppLanguage
    var diameter: CGFloat = 62

    @State private var tapped = 0

    var body: some View {
        if SpeechService.shared.canSpeak(in: language) {
            Button {
                tapped += 1
                SpeechService.shared.speak(number: value, language: language)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .symbolEffect(.variableColor.iterative, value: tapped)
            }
            .buttonStyle(CircleButtonStyle(diameter: diameter))
            .accessibilityLabel(Text("Escuchar número"))
        }
    }
}

/// Tarjeta crema con foco (dato) o verde (consejo), como en el Figma.
struct InfoCard<Content: View>: View {
    enum Style { case fact, tip }
    var style: Style = .fact
    var systemImage: String = "lightbulb.fill"
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.focus)
                .padding(.top, 2)
            content
                .font(.rounded(15, weight: .bold))
                .foregroundStyle(style == .tip ? Palette.greenSoft : Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .background(style == .tip ? Palette.tip : Palette.fact,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
