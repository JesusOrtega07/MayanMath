//
//  NumbersView.swift
//  MayanMath
//
//  Números del 1 al 30: cómo se compone cada uno.
//  Izquierda: reglas básicas + cuadrícula 1–30. Derecha: explicación del número elegido.
//

import SwiftUI

struct NumbersView: View {
    var onPractice: (Int) -> Void

    @State private var selected = 1
    @AppStorage("appLanguage") private var language: AppLanguage = .spanish

    private let numbers = Array(1...30)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(spacing: 16) {
                RulesStrip()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(numbers, id: \.self) { value in
                            NumberCard(value: value, isSelected: value == selected)
                                .onTapGesture {
                                    withAnimation(.spring(duration: 0.45, bounce: 0.3)) { selected = value }
                                }
                        }
                    }
                    .padding(4)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: .infinity)

            NumberDetailPanel(
                value: selected,
                language: language,
                onPrevious: selected > 1 ? { () -> Void in move(-1) } : nil,
                onNext: selected < 30 ? { () -> Void in move(1) } : nil,
                onPractice: { onPractice(selected) }
            )
            .frame(width: 390)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func move(_ delta: Int) {
        withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
            selected = min(30, max(1, selected + delta))
        }
    }
}

// MARK: - Reglas

/// Punto = 1 · Barra = 5 · Concha = 0 · Nivel de arriba × 20
private struct RulesStrip: View {
    var body: some View {
        HStack(spacing: 10) {
            rule(glyph: MayanDigit(1)!, title: "Punto", value: "vale 1")
            rule(glyph: MayanDigit(5)!, title: "Barra", value: "vale 5")
            rule(glyph: .zero, title: "Concha", value: "vale 0")
            HStack(spacing: 10) {
                Image(systemName: "square.stack.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.green)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Nivel de arriba")
                        .font(.rounded(15, weight: .black))
                    Text("cada punto vale 20")
                        .font(.rounded(13, weight: .semibold))
                        .foregroundStyle(Palette.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .mmPanel(radius: 16)
        }
    }

    private func rule(glyph: MayanDigit, title: LocalizedStringKey, value: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            MayanDigitGlyph(digit: glyph, scale: 0.4)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.rounded(15, weight: .black))
                Text(value)
                    .font(.rounded(13, weight: .semibold))
                    .foregroundStyle(Palette.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .mmPanel(radius: 16)
    }
}

// MARK: - Tarjeta de la cuadrícula

private struct NumberCard: View {
    let value: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            MayanNumberGlyph(number: MayanNumber(value), scale: 0.26, showsSeparators: value >= 20)
                .frame(height: 64)
            Text(value, format: .number)
                .font(.rounded(19, weight: .black))
                .foregroundStyle(isSelected ? .white : Palette.ink)
                .frame(minWidth: 34)
                .padding(.vertical, 2)
                .background(isSelected ? Palette.green : .clear, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? Palette.zoneGreenFill : Palette.tile,
                    in: RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous)
                .strokeBorder(Palette.green, lineWidth: isSelected ? 3 : 0)
        )
        .scaleEffect(isSelected ? 1.04 : 1)
        .contentShape(RoundedRectangle(cornerRadius: Metrics.tileRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(value)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Explicación del número

private struct NumberDetailPanel: View {
    let value: Int
    let language: AppLanguage
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onPractice: () -> Void

    private var explanation: NumberExplanation { NumberExplanation(value) }

    var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    LabeledMayanNumber(number: explanation.number, glyphScale: 0.62, boxHeight: 92)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(explanation.levels) { level in
                            levelRow(level)
                        }
                        if explanation.usesTwoLevels {
                            totalRow
                        }
                    }

                    InfoCard(style: .tip) {
                        Text(storyText)
                    }
                }
                .id(value)
                .transition(.blurReplace)
            }
            .scrollBounceBehavior(.basedOnSize)

            footer
        }
        .padding(20)
        .frame(maxHeight: .infinity)
        .mmPanel()
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(value, format: .number)
                    .font(.rounded(64, weight: .black))
                    .foregroundStyle(Palette.green)
                    .contentTransition(.numericText(value: Double(value)))
                if let word = NumberWords.word(for: value, language: language) {
                    Text(verbatim: word)
                        .font(.rounded(22, weight: .black))
                        .foregroundStyle(Palette.heading)
                        .id(word)
                        .transition(.opacity)
                }
            }
            Spacer()
            SpeakNumberButton(value: value, language: language, diameter: 54)
        }
    }

    private func levelRow(_ level: LevelBreakdown) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(level.level == 0 ? Palette.zoneGoldBorder : Palette.zoneGreenBorder)
                .frame(width: 12, height: 12)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(MayanPhrases.levelName(level.level))
                    .font(.rounded(14, weight: .heavy))
                    .foregroundStyle(Palette.textMuted)
                Group {
                    if level.level == 0 {
                        Text("\(Text(MayanPhrases.composition(level.digit))) → \(MayanPhrases.arithmetic(level.digit))")
                    } else {
                        Text("\(Text(MayanPhrases.composition(level.digit))) → \(level.digit.value) × 20 = \(level.contribution)")
                    }
                }
                .font(.rounded(17, weight: .bold))
                .foregroundStyle(Palette.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalRow: some View {
        let sum = explanation.addends.map(String.init).joined(separator: " + ")
        return Text("Total: \(sum) = \(value)")
            .font(.rounded(19, weight: .black))
            .foregroundStyle(Palette.green)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Explicación amigable según la etapa del número.
    private var storyText: LocalizedStringKey {
        let units = explanation.number.digit(atLevel: 0)
        switch explanation.stage {
        case .zero:
            return "El cero se dibuja con una concha."
        case .onlyDots:
            return "Cada punto vale 1. Puedes poner hasta 4 puntos; al llegar a 5 se juntan en una barra."
        case .firstBar:
            return "¡Cinco puntos se juntan en una barra! Una barra vale 5."
        case .barsAndDots:
            return "Primero cuenta las barras de 5 y luego suma los puntos: \(MayanPhrases.arithmetic(units))."
        case .twenty:
            return "¡Llegaste a 20! Las 4 barras se cambian por un punto en el nivel de arriba, y abajo queda una concha (0)."
        case .withTwenties:
            return "Arriba hay una veintena (20). Abajo van las unidades que sobran: \(value) − 20 = \(units.value)."
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            navButton("chevron.left", action: onPrevious)
            Button {
                onPractice()
            } label: {
                Label("Practicar en Retos", systemImage: "target")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            navButton("chevron.right", action: onNext)
        }
    }

    private func navButton(_ systemImage: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Palette.green)
                .frame(width: 48, height: 48)
                .background(Palette.resultCard, in: Circle())
        }
        .buttonStyle(LiftButtonStyle())
        .disabled(action == nil)
        .opacity(action == nil ? 0.35 : 1)
    }
}

#Preview(traits: .landscapeLeft) {
    NumbersView(onPractice: { _ in })
        .background(Palette.appBackground)
}
