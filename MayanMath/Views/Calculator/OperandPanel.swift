//
//  OperandPanel.swift
//  MayanMath
//
//  Panel de un número: dos niveles (20 · 1) donde se sueltan fichas.
//  • Arrastra una ficha a un nivel, o toca un nivel y luego una ficha de la paleta.
//  • Toca un punto (−1), una barra (−5) o la concha para quitarlos.
//

import SwiftUI

struct OperandPanel: View {
    let title: LocalizedStringKey
    let operand: CalculatorOperand
    let viewModel: CalculatorViewModel
    let drag: PaletteDragModel

    /// Contadores que disparan animaciones por nivel.
    @State private var shakes: [Int: Int] = [:]
    @State private var pulses: [Int: Int] = [:]

    private var builder: MayanNumberBuilder { viewModel.builder(for: operand) }
    private var isActiveOperand: Bool { viewModel.activeOperand == operand }

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.rounded(20, weight: .black))
                .foregroundStyle(isActiveOperand ? Palette.greenText : Palette.heading)

            ForEach((0..<builder.maxLevels).reversed(), id: \.self) { level in
                LevelDropZone(
                    level: level,
                    content: builder.content(atLevel: level),
                    canRemoveShell: builder.levels[level] == 0,
                    isSelected: isActiveOperand && viewModel.activeLevel == level,
                    isTargeted: drag.hoveredZone == DropZoneID(operand: operand, level: level),
                    shakeCount: shakes[level, default: 0],
                    pulseCount: pulses[level, default: 0],
                    onTap: {
                        withAnimation(.snappy) { viewModel.focus(operand, level: level) }
                    },
                    onFrameChange: { frame in
                        drag.register(DropZoneID(operand: operand, level: level), frame: frame)
                    },
                    onRemove: { symbol in
                        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                            viewModel.removeSymbol(symbol, fromLevel: level, of: operand)
                        }
                    }
                )
            }

            footer
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mmPanel()
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .strokeBorder(Palette.green.opacity(isActiveOperand ? 0.35 : 0), lineWidth: 2)
        }
        .animation(.snappy, value: isActiveOperand)
        .onChange(of: viewModel.lastChange) { _, change in
            react(to: change)
        }
    }

    private var footer: some View {
        HStack {
            Group {
                if let value = viewModel.decimalValue(of: operand) {
                    Text(value, format: .number)
                        .contentTransition(.numericText(value: Double(value)))
                } else {
                    Text("—")
                }
            }
            .font(.rounded(30, weight: .black))
            .foregroundStyle(Palette.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text("Valor: \(viewModel.decimalValue(of: operand) ?? 0)"))

            Button {
                withAnimation(.spring(duration: 0.4)) { viewModel.clear(operand) }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.green)
                    .frame(width: 40, height: 40)
                    .background(Palette.resultCard, in: Circle())
            }
            .buttonStyle(LiftButtonStyle())
            .disabled(builder.isEmpty)
            .opacity(builder.isEmpty ? 0.4 : 1)
            .accessibilityLabel(Text("Borrar número"))
        }
        .padding(.horizontal, 4)
    }

    /// Sacude el nivel si la ficha no cupo; hace latir el nivel que recibió un punto de arriba.
    private func react(to change: BuilderChange?) {
        guard let change, change.operand == operand else { return }
        switch change.kind {
        case .rejected:
            if let level = change.level { shakes[level, default: 0] += 1 }
        case .added(_, let regroupings):
            for event in regroupings {
                if case .carried(_, let toLevel, _) = event {
                    pulses[toLevel, default: 0] += 1
                }
            }
        default:
            break
        }
    }
}

// MARK: - Nivel

struct LevelDropZone: View {
    let level: Int
    let content: LevelContent
    let canRemoveShell: Bool
    let isSelected: Bool
    let isTargeted: Bool
    let shakeCount: Int
    let pulseCount: Int
    var onTap: () -> Void
    var onFrameChange: (CGRect) -> Void
    var onRemove: (MayanSymbol) -> Void

    private var style: (fill: Color, border: Color) {
        switch level {
        case 0: (Palette.zoneGoldFill, Palette.zoneGoldBorder)
        default: (Palette.zoneGreenFill, Palette.zoneGreenBorder)
        }
    }

    private var levelName: LocalizedStringKey {
        switch level {
        case 0: "unidades"
        default: "veintenas"
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.zoneRadius, style: .continuous)

        ZStack {
            shape.fill(style.fill)
            shape.strokeBorder(
                style.border,
                style: StrokeStyle(lineWidth: isSelected || isTargeted ? 3 : 2,
                                   dash: isSelected || isTargeted ? [] : [7, 5])
            )

            Group {
                switch content {
                case .empty:
                    EmptyView()
                case .digit(let digit):
                    InteractiveDigitGlyph(
                        digit: digit,
                        scale: 0.85,
                        canRemoveShell: canRemoveShell,
                        onRemove: onRemove
                    )
                }
            }

            Text(MayanNumber.placeValue(ofLevel: level), format: .number)
                .font(.rounded(22, weight: .black))
                .foregroundStyle(style.border.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 14)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, minHeight: 70, maxHeight: .infinity)
        .overlay {
            if isSelected {
                shape.stroke(Palette.green.opacity(0.15), lineWidth: 8).padding(-4)
            }
        }
        .scaleEffect(isTargeted ? 1.03 : 1)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isTargeted)
        .modifier(ShakeEffect(animatableData: CGFloat(shakeCount)))
        .animation(.linear(duration: 0.35), value: shakeCount)
        .phaseAnimator([false, true], trigger: pulseCount) { zone, glowing in
            zone
                .scaleEffect(glowing ? 1.05 : 1)
                .brightness(glowing ? 0.04 : 0)
        } animation: { _ in .spring(duration: 0.3, bounce: 0.5) }
        .contentShape(shape)
        .onTapGesture(perform: onTap)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(PaletteDragModel.coordinateSpace))
        } action: { frame in
            onFrameChange(frame)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(levelName))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Dígito con símbolos que se pueden tocar

/// Igual que `MayanDigitGlyph`, pero cada punto, barra o concha se puede tocar para quitarlo.
struct InteractiveDigitGlyph: View {
    let digit: MayanDigit
    var scale: CGFloat = 0.68
    var canRemoveShell: Bool
    var onRemove: (MayanSymbol) -> Void

    var body: some View {
        Group {
            if digit.isZero {
                ShellGlyph(width: 80 * scale)
                    .padding(6)
                    .contentShape(Rectangle())
                    .onTapGesture { if canRemoveShell { onRemove(.shell) } }
                    .accessibilityLabel(Text("cero"))
            } else {
                VStack(spacing: 8 * scale) {
                    if digit.dots > 0 {
                        HStack(spacing: 8 * scale) {
                            ForEach(0..<digit.dots, id: \.self) { _ in
                                Circle()
                                    .frame(width: 16 * scale, height: 16 * scale)
                                    .padding(5)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onRemove(.dot) }
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    ForEach(0..<digit.bars, id: \.self) { _ in
                        Capsule()
                            .frame(width: 80 * scale, height: 10 * scale)
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                            .onTapGesture { onRemove(.bar) }
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(digit.value)"))
                .accessibilityHint(Text("Toca un punto o una barra para quitarlo"))
            }
        }
        .foregroundStyle(Palette.glyph)
    }
}

// MARK: - Sacudida

/// Movimiento lateral de "no cabe".
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: travel * sin(animatableData * .pi * shakes * 2),
            y: 0
        ))
    }
}
