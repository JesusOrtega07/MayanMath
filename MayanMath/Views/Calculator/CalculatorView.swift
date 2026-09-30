//
//  CalculatorView.swift
//  MayanMath
//
//  Pantalla de la calculadora maya (sección principal).
//
//  ┌──────────── Suma · Resta · Multiplicación · División ────────────┐
//  │ [Primer número]  +  [Segundo número]  (=)  [Resultado]           │
//  │ [────────────── Paleta de símbolos mayas ──────────────]         │
//

import SwiftUI

struct CalculatorView: View {
    let viewModel: CalculatorViewModel
    @State private var drag = PaletteDragModel()

    var body: some View {
        VStack(spacing: 20) {
            OperationPicker(selection: Binding(
                get: { viewModel.operation },
                set: { newValue in
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) { viewModel.select(newValue) }
                }
            ))

            HStack(alignment: .center, spacing: 14) {
                OperandPanel(title: "Primer número", operand: .first, viewModel: viewModel, drag: drag)

                OperatorBadge(operation: viewModel.operation)

                OperandPanel(title: "Segundo número", operand: .second, viewModel: viewModel, drag: drag)

                EqualsButton(isEnabled: viewModel.canCalculate) {
                    withAnimation(.spring(duration: 0.55, bounce: 0.35)) {
                        viewModel.calculate()
                    }
                }

                ResultPanel(viewModel: viewModel)
                    .frame(maxWidth: 300)
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
                        _ = viewModel.drop(digit, onLevel: zone.level, of: zone.operand)
                    }
                },
                onClear: {
                    withAnimation(.spring(duration: 0.4)) { viewModel.clearAll() }
                }
            )
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        // Espacio compartido por la paleta, los niveles y la ficha flotante.
        .coordinateSpace(.named(PaletteDragModel.coordinateSpace))
        .overlay(alignment: .topLeading) {
            DragGhostLayer(drag: drag)
        }
        // Hápticos
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
        .sensoryFeedback(trigger: viewModel.state) { _, state in
            switch state {
            case .result: .success
            case .error: .warning
            case .editing: nil
            }
        }
    }
}

// MARK: - Ficha flotante

/// Vista aparte para que solo ella se redibuje mientras el dedo se mueve.
private struct DragGhostLayer: View {
    let drag: PaletteDragModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let digit = drag.digit {
                DraggedTileGhost(digit: digit, isOverZone: drag.hoveredZone != nil)
                    .position(drag.location)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

// MARK: - Selector de operación

struct OperationPicker: View {
    @Binding var selection: MayanOperation
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MayanOperation.allCases) { operation in
                let isActive = selection == operation
                Button {
                    selection = operation
                } label: {
                    Label {
                        Text(operation.title)
                    } icon: {
                        Image(systemName: operation.systemImage)
                    }
                    .font(.rounded(17, weight: .black))
                    .foregroundStyle(isActive ? .white : Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Palette.green)
                                .shadow(color: Color(hex: 0x00542F), radius: 0, y: 3)
                                .matchedGeometryEffect(id: "activeOperation", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Palette.panelShadow, radius: 4, y: 2)
        .frame(maxWidth: 720)
    }
}

// MARK: - Signos entre paneles

struct OperatorBadge: View {
    let operation: MayanOperation

    var body: some View {
        Text(operation.symbol)
            .font(.rounded(52, weight: .black))
            .foregroundStyle(Palette.green)
            .frame(width: 44)
            .id(operation)
            .transition(.scale(scale: 0.3).combined(with: .opacity))
            .accessibilityLabel(Text(operation.title))
    }
}

struct EqualsButton: View {
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("=")
                .font(.rounded(40, weight: .black))
                .padding(.bottom, 4)
        }
        .buttonStyle(CircleButtonStyle(diameter: 70))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .scaleEffect(isEnabled ? 1 : 0.92)
        .animation(.spring(duration: 0.35, bounce: 0.4), value: isEnabled)
        .accessibilityLabel(Text("Calcular"))
        .accessibilityHint(Text(isEnabled ? "" : "Forma los dos números primero"))
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
