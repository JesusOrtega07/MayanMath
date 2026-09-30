//
//  ChallengesView.swift
//  MayanMath
//
//  Retos: "Forma el 23 en maya".
//  ┌ 1 2 3 … 30 (selector de retos) ────────────────────────────┐
//  │ [Número a formar] [Área de construcción + Comprobar] [Pistas] │
//  │ [──────────────── Paleta de símbolos mayas ────────────────]  │
//

import SwiftData
import SwiftUI

struct ChallengesView: View {
    let viewModel: ChallengeViewModel

    @Query private var records: [ChallengeRecord]
    @State private var drag = PaletteDragModel()
    @AppStorage("appLanguage") private var language: AppLanguage = .spanish

    private var starsByNumber: [Int: Int] {
        Dictionary(records.map { ($0.number, $0.stars) }, uniquingKeysWith: { max($0, $1) })
    }

    var body: some View {
        VStack(spacing: 16) {
            ChallengePicker(
                current: viewModel.target.value,
                starsByNumber: starsByNumber,
                onSelect: { number in
                    withAnimation(.spring(duration: 0.45, bounce: 0.25)) { viewModel.select(number) }
                }
            )

            HStack(alignment: .top, spacing: 18) {
                ChallengeTargetPanel(
                    value: viewModel.target.value,
                    stars: starsByNumber[viewModel.target.value],
                    language: language
                )
                .frame(width: 230)

                ChallengeBuildPanel(viewModel: viewModel, drag: drag)
                    .frame(maxWidth: .infinity)

                ChallengeHintsPanel(viewModel: viewModel)
                    .frame(width: 300)
            }
            .frame(maxHeight: .infinity)

            SymbolPalette(
                drag: drag,
                onChoose: { digit in
                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                        _ = viewModel.dropOnActiveLevel(digit)
                    }
                },
                onDrop: { digit, zone in
                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                        _ = viewModel.drop(digit, onLevel: zone.level)
                    }
                },
                onClear: {
                    withAnimation(.spring(duration: 0.4)) { viewModel.clear() }
                }
            )
            .disabled(viewModel.isSolved)
            .opacity(viewModel.isSolved ? 0.5 : 1)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .coordinateSpace(.named(PaletteDragModel.coordinateSpace))
        .overlay(alignment: .topLeading) {
            DragGhostLayer(drag: drag)
        }
        .sensoryFeedback(trigger: drag.hoveredZone) { _, zone in
            zone == nil ? nil : .selection
        }
        .sensoryFeedback(trigger: viewModel.lastChange) { _, change in
            guard let change else { return nil }
            switch change.kind {
            case .rejected: return .error
            case .added(_, let regroupings): return .impact(weight: regroupings.isEmpty ? .light : .medium)
            case .removed: return .selection
            case .clearedLevel, .clearedOperand: return .impact(weight: .light)
            }
        }
        .sensoryFeedback(trigger: viewModel.phase) { _, phase in
            switch phase {
            case .correct: .success
            case .wrong: .error
            case .building: nil
            }
        }
    }
}

// MARK: - Selector de retos

private struct ChallengePicker: View {
    let current: Int
    let starsByNumber: [Int: Int]
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Retos").mmEyebrow()
                Text("\(starsByNumber.count) de \(ChallengeCatalog.numbers.count)")
                    .font(.rounded(17, weight: .black))
                    .foregroundStyle(Palette.heading)
                    .contentTransition(.numericText(value: Double(starsByNumber.count)))
            }
            .frame(width: 90, alignment: .leading)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChallengeCatalog.numbers, id: \.self) { number in
                            chip(number)
                                .id(number)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .onAppear { proxy.scrollTo(current, anchor: .center) }
                .onChange(of: current) { _, newValue in
                    withAnimation(.snappy) { proxy.scrollTo(newValue, anchor: .center) }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .mmPanel(radius: 18)
    }

    private func chip(_ number: Int) -> some View {
        let isCurrent = number == current
        let isDone = starsByNumber[number] != nil
        return Button {
            onSelect(number)
        } label: {
            Text(number, format: .number)
                .font(.rounded(18, weight: .black))
                .foregroundStyle(isCurrent ? .white : (isDone ? Palette.greenSoft : Palette.ink))
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isCurrent ? Palette.green : (isDone ? Palette.zoneGreenFill : Palette.tile))
                )
                .overlay(alignment: .topTrailing) {
                    if isDone {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.star)
                            .padding(3)
                            .background(.white, in: Circle())
                            .offset(x: 5, y: -5)
                    }
                }
                .scaleEffect(isCurrent ? 1.08 : 1)
                .animation(.spring(duration: 0.35, bounce: 0.4), value: isCurrent)
        }
        .buttonStyle(LiftButtonStyle())
        .accessibilityLabel(Text("Reto \(number)"))
        .accessibilityValue(Text(isDone ? "completado" : ""))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

// MARK: - Número a formar

private struct ChallengeTargetPanel: View {
    let value: Int
    let stars: Int?
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 10) {
            Text("Número a formar")
                .font(.mmPanelTitle)
                .foregroundStyle(Palette.heading)
            Text("Conviértelo a maya")
                .font(.rounded(14, weight: .bold))
                .foregroundStyle(Palette.textMuted)

            Spacer(minLength: 0)

            Text(value, format: .number)
                .font(.rounded(100, weight: .black))
                .foregroundStyle(Palette.green)
                .contentTransition(.numericText(value: Double(value)))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if let word = NumberWords.word(for: value, language: language) {
                Text(verbatim: word)
                    .font(.rounded(24, weight: .black))
                    .foregroundStyle(Palette.heading)
                    .multilineTextAlignment(.center)
                    .id(word)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            SpeakNumberButton(value: value, language: language)

            if let stars {
                Label("\(stars)", systemImage: "star.fill")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Palette.goldText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Palette.gold.opacity(0.45), in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else if let position = ChallengeCatalog.position(of: value) {
                Text("Reto \(position) de \(ChallengeCatalog.numbers.count)")
                    .font(.rounded(14, weight: .bold))
                    .foregroundStyle(Palette.textMuted)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity)
        .mmPanel()
    }
}

// MARK: - Área de construcción

private struct ChallengeBuildPanel: View {
    let viewModel: ChallengeViewModel
    let drag: PaletteDragModel

    @State private var shakes: [Int: Int] = [:]
    @State private var pulses: [Int: Int] = [:]

    var body: some View {
        VStack(spacing: 10) {
            Text("Área de construcción")
                .font(.mmPanelTitle)
                .foregroundStyle(Palette.heading)
            Text("Se lee de arriba hacia abajo")
                .font(.rounded(14, weight: .bold))
                .foregroundStyle(Palette.textMuted)

            ForEach((0..<viewModel.builder.maxLevels).reversed(), id: \.self) { level in
                LevelDropZone(
                    level: level,
                    content: viewModel.builder.content(atLevel: level),
                    canRemoveShell: viewModel.builder.levels[level] == 0,
                    isSelected: viewModel.activeLevel == level && !viewModel.isSolved,
                    isTargeted: drag.hoveredZone == DropZoneID(operand: .first, level: level),
                    shakeCount: shakes[level, default: 0],
                    pulseCount: pulses[level, default: 0],
                    onTap: {
                        withAnimation(.snappy) { viewModel.focus(level: level) }
                    },
                    onFrameChange: { frame in
                        drag.register(DropZoneID(operand: .first, level: level), frame: frame)
                    },
                    onRemove: { symbol in
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            viewModel.removeSymbol(symbol, fromLevel: level)
                        }
                    }
                )
            }

            if case .wrong(let feedback) = viewModel.phase {
                WrongFeedbackBanner(feedback: feedback, target: viewModel.target.value)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(duration: 0.4)) { viewModel.clear() }
                } label: {
                    Label("Borrar", systemImage: "trash.fill")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Palette.green)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(Palette.resultCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(LiftButtonStyle())

                Button {
                    withAnimation(.spring(duration: 0.5, bounce: 0.35)) { viewModel.check() }
                } label: {
                    Label("Comprobar", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .mmPanel()
        .overlay {
            if case .correct(let earned) = viewModel.phase {
                SuccessOverlay(
                    value: viewModel.target.value,
                    earnedStars: earned,
                    hasNext: viewModel.hasNext,
                    onRetry: {
                        withAnimation(.spring(duration: 0.45)) { viewModel.select(viewModel.target.value) }
                    },
                    onNext: {
                        withAnimation(.spring(duration: 0.45, bounce: 0.25)) { viewModel.next() }
                    }
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.failureCount) { _, _ in
            if case .wrong(let feedback) = viewModel.phase, let level = feedback.levelToHighlight {
                shakes[level, default: 0] += 1
            }
        }
        .onChange(of: viewModel.lastChange) { _, change in
            guard let change else { return }
            switch change.kind {
            case .rejected:
                if let level = change.level { shakes[level, default: 0] += 1 }
            case .added(_, let regroupings):
                for event in regroupings {
                    if case .carried(_, let toLevel, _) = event { pulses[toLevel, default: 0] += 1 }
                }
            default:
                break
            }
        }
    }
}

/// Mensaje cuando la respuesta no es correcta.
private struct WrongFeedbackBanner: View {
    let feedback: ChallengeFeedback
    let target: Int

    var body: some View {
        HStack(spacing: 12) {
            GuideCharacter(pose: .think, animated: false)
                .frame(width: 44, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rounded(17, weight: .black))
                Text(message)
                    .font(.rounded(14, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.goldText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.gold.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var title: LocalizedStringKey {
        feedback == .empty ? "¡Aún no hay nada!" : "¡Casi! Inténtalo de nuevo"
    }

    private var message: LocalizedStringKey {
        switch feedback {
        case .empty:
            "Arrastra símbolos de la paleta a los niveles para formar el \(target)."
        case .wrongTwenties(let tooMany):
            if target < 20 {
                "El \(target) es menor que 20: el nivel de 20 debe quedar vacío."
            } else if tooMany {
                "Revisa el nivel de 20: pusiste de más."
            } else {
                "Revisa el nivel de 20: te faltan puntos."
            }
        case .wrongUnits(let tooMany):
            tooMany
                ? "El nivel de 20 está bien. En el nivel de 1 sobran símbolos."
                : "El nivel de 20 está bien. En el nivel de 1 faltan símbolos."
        case .correct:
            ""
        }
    }
}

/// Celebración al acertar.
private struct SuccessOverlay: View {
    let value: Int
    let earnedStars: Int
    let hasNext: Bool
    var onRetry: () -> Void
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                StarBurst()
                GuideCharacter(pose: .celebrate)
                    .frame(width: 120, height: 156)
            }

            Text("¡Correcto!")
                .font(.rounded(34, weight: .black))
                .foregroundStyle(Palette.green)

            MayanNumberGlyph(number: MayanNumber(value), scale: 0.4)
                .frame(maxHeight: 110)

            if earnedStars > 0 {
                Label("+\(earnedStars) estrellas", systemImage: "star.fill")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Palette.goldText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Palette.gold.opacity(0.5), in: Capsule())
            } else {
                Text("¡Ya lo habías resuelto antes!")
                    .font(.rounded(16, weight: .bold))
                    .foregroundStyle(Palette.textMuted)
            }

            HStack(spacing: 12) {
                Button(action: onRetry) {
                    Label("Repetir", systemImage: "arrow.counterclockwise")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Palette.green)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(LiftButtonStyle())

                if hasNext {
                    Button(action: onNext) {
                        Label("Siguiente reto", systemImage: "arrow.right")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .fill(Palette.resultCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .strokeBorder(Palette.zoneGreenBorder, lineWidth: 2)
        )
    }
}

/// Estrellas que salen disparadas alrededor del personaje.
private struct StarBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) / 10 * 2 * .pi
                Image(systemName: index.isMultiple(of: 2) ? "star.fill" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 18 : 14))
                    .foregroundStyle(index.isMultiple(of: 3) ? Palette.green : Palette.star)
                    .offset(x: burst ? cos(angle) * 95 : 0, y: burst ? sin(angle) * 80 : 0)
                    .scaleEffect(burst ? 1 : 0.2)
                    .opacity(burst ? 0 : 1)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.1)) { burst = true }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Pistas

private struct ChallengeHintsPanel: View {
    let viewModel: ChallengeViewModel

    private var pose: GuideCharacter.Pose {
        switch viewModel.phase {
        case .building: .wave
        case .wrong: .think
        case .correct: .celebrate
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Pistas")
                .font(.mmPanelTitle)
                .foregroundStyle(Palette.greenText)
            Text(viewModel.target.value < 20
                 ? LocalizedStringKey("Nivel 1 · Unidades")
                 : LocalizedStringKey("Nivel 2 · Unidades y veintenas"))
                .font(.rounded(16, weight: .heavy))
                .foregroundStyle(Palette.heading)

            MiniScene(pose: pose)
                .frame(height: 110)

            ScrollView {
                VStack(spacing: 10) {
                    if viewModel.revealedHints == 0 {
                        InfoCard(style: .fact) {
                            Text("Empieza por el nivel de abajo (unidades) y luego sube al nivel de 20.")
                        }
                        InfoCard(style: .tip) {
                            Text("5 puntos forman una barra, y 20 unidades suben un punto al nivel de 20.")
                        }
                    }

                    ForEach(Array(viewModel.visibleHints.enumerated()), id: \.element.id) { index, hint in
                        HintCard(number: index + 1, hint: hint)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            if viewModel.canRevealHint {
                Button {
                    withAnimation(.spring(duration: 0.45, bounce: 0.3)) { viewModel.revealHint() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .symbolEffect(.pulse, isActive: viewModel.shouldSuggestHint)
                        Text(viewModel.shouldSuggestHint
                             ? LocalizedStringKey("¿Necesitas una pista?")
                             : LocalizedStringKey("Ver una pista"))
                        Text("\(viewModel.revealedHints + 1)/\(viewModel.hints.count)")
                            .font(.rounded(13, weight: .heavy))
                            .opacity(0.7)
                    }
                    .font(.rounded(16, weight: .black))
                    .foregroundStyle(Palette.goldText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Palette.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .scaleEffect(viewModel.shouldSuggestHint ? 1.03 : 1)
                }
                .buttonStyle(LiftButtonStyle())
                .animation(.spring(duration: 0.4, bounce: 0.5), value: viewModel.shouldSuggestHint)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .mmPanel()
    }
}

private struct HintCard: View {
    let number: Int
    let hint: ChallengeHint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pista \(number)")
                .font(.rounded(11, weight: .black))
                .textCase(.uppercase)
                .foregroundStyle(Palette.goldText)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 5))

            switch hint {
            case .twenties(let target, let count):
                if count == 0 {
                    Text("El \(target) es menor que 20, así que el nivel de 20 se queda vacío. Todo va abajo.")
                } else {
                    Text("El \(target) tiene ^[\(count) veintena](inflect: true): pon ^[\(count) punto](inflect: true) en el nivel de 20 (arriba).")
                }
            case .units(let digit):
                if digit.isZero {
                    Text("No sobran unidades: en el nivel de 1 va una concha (0).")
                } else {
                    Text("En el nivel de 1 van \(digit.value): \(Text(MayanPhrases.composition(digit))).")
                }
            case .solution(let number):
                Text("Así se ve el número. ¡Cópialo!")
                LabeledMayanNumber(number: number, glyphScale: 0.38, boxHeight: 58)
            }
        }
        .font(.rounded(15, weight: .bold))
        .foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Palette.helpCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview(traits: .landscapeLeft) {
    ChallengesView(viewModel: ChallengeViewModel(number: 23))
        .background(Palette.appBackground)
        .modelContainer(for: ChallengeRecord.self, inMemory: true)
}
