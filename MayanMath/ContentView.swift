//
//  ContentView.swift
//  MayanMath
//
//  Vista principal: encabezado + barra lateral + sección activa.
//  La app abre en la Calculadora.
//

import SwiftUI

struct ContentView: View {
    @State private var section: AppSection = .calculator
    /// Vive aquí para que la calculadora conserve sus números al cambiar de sección.
    @State private var calculator = CalculatorViewModel()
    @AppStorage("appLanguage") private var language: AppLanguage = .spanish

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(section: section, stars: 0, language: $language)

            HStack(spacing: 0) {
                AppSidebar(selection: $section)

                Group {
                    switch section {
                    case .calculator:
                        CalculatorView(viewModel: calculator)
                    default:
                        ComingSoonView(section: section)
                    }
                }
                .id(section)
                .transition(.blurReplace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Palette.appBackground.ignoresSafeArea())
        .fontDesign(.rounded)
    }
}

/// Marcador para las secciones que aún no se programan.
struct ComingSoonView: View {
    let section: AppSection

    var body: some View {
        VStack(spacing: 18) {
            GuideCharacter(pose: .point)
                .frame(width: 170, height: 220)
            Text("¡Muy pronto!")
                .font(.rounded(34, weight: .black))
                .foregroundStyle(Palette.heading)
            Text(section.subtitle)
                .font(.mmBody)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(48)
        .mmPanel()
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
