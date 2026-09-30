//
//  ResultPanel.swift
//  MayanMath
//
//  Resultado de la calculadora: número maya + decimal, residuo en la división,
//  mensajes de error y botón para seguir calculando con el resultado.
//

import SwiftUI

struct ResultPanel: View {
    let viewModel: CalculatorViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Resultado")
                .font(.rounded(20, weight: .black))
                .foregroundStyle(Palette.greenText)

            Group {
                switch viewModel.state {
                case .editing:
                    placeholder
                case .result(let result):
                    ResultContent(
                        result: result,
                        canContinue: viewModel.canContinueWithResult,
                        onContinue: {
                            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                _ = viewModel.continueWithResult()
                            }
                        }
                    )
                case .error(let error):
                    ErrorContent(error: error) {
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            viewModel.swapOperands()
                            viewModel.calculate()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(stateID)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .fill(Palette.resultCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .strokeBorder(Palette.panelBorder, lineWidth: 1)
        )
    }

    /// Identidad del contenido para animar el cambio entre estados.
    private var stateID: String {
        switch viewModel.state {
        case .editing: "editing"
        case .result(let result): "result-\(result.value.value)-\(result.remainder?.value ?? -1)"
        case .error(let error): "error-\(error)"
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            GuideCharacter(pose: .point)
                .frame(maxWidth: 130, maxHeight: 170)
            Text("Forma dos números y toca =")
                .font(.rounded(16, weight: .bold))
                .foregroundStyle(Palette.greenSoft)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Resultado

private struct ResultContent: View {
    let result: CalculationResult
    let canContinue: Bool
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Número maya ajustado al espacio (hasta 5 niveles).
            GeometryReader { geo in
                let levels = CGFloat(result.value.levelCount)
                let scale = min(0.6, geo.size.height / (levels * 110))
                MayanNumberGlyph(number: result.value, scale: scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 90)

            Text(result.value.value, format: .number)
                .font(.rounded(44, weight: .black))
                .foregroundStyle(Palette.greenSoft)
                .contentTransition(.numericText(value: Double(result.value.value)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if let remainder = result.remainder, result.hasRemainder {
                HStack(spacing: 8) {
                    Text("Residuo")
                        .font(.rounded(15, weight: .heavy))
                    Text(remainder.value, format: .number)
                        .font(.rounded(20, weight: .black))
                }
                .foregroundStyle(Palette.goldText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Palette.gold.opacity(0.45), in: Capsule())
            }

            if canContinue {
                Button(action: onContinue) {
                    Label("Seguir calculando", systemImage: "arrow.uturn.left")
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Palette.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(LiftButtonStyle())
                .accessibilityHint(Text("Usa el resultado como primer número"))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Error

private struct ErrorContent: View {
    let error: CalculationError
    var onSwap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            GuideCharacter(pose: .think)
                .frame(maxWidth: 110, maxHeight: 145)

            Text(error.message)
                .font(.rounded(16, weight: .bold))
                .foregroundStyle(Palette.goldText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if error == .negativeResult {
                Button(action: onSwap) {
                    Label("Intercambiar números", systemImage: "arrow.left.arrow.right")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}
