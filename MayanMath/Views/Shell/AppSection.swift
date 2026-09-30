//
//  AppSection.swift
//  MayanMath
//
//  Secciones de la barra lateral y el idioma de la app.
//

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case calculator
    case home
    case numbers
    case operations
    case achievements

    var id: Self { self }

    /// Texto del botón en la barra lateral.
    var label: LocalizedStringKey {
        switch self {
        case .calculator: "Calculadora"
        case .home: "Inicio"
        case .numbers: "Números"
        case .operations: "Operaciones matemáticas"
        case .achievements: "Logros"
        }
    }

    /// Título del encabezado verde.
    var title: LocalizedStringKey {
        switch self {
        case .calculator: "Calculadora maya"
        case .home: "¡Bienvenido a MayanMath!"
        case .numbers: "Aprendo a representar números mayas"
        case .operations: "Aprendemos operaciones mayas"
        case .achievements: "Mis logros"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .calculator: "Arrastra o toca los símbolos para formar tus números"
        case .home: "Aprende matemáticas mientras descubres una cultura increíble"
        case .numbers: "Arrastra los símbolos mayas para formar el número"
        case .operations: "Resuelve las operaciones usando los símbolos mayas"
        case .achievements: "Cada reto completado te acerca a ser un maestro maya"
        }
    }

    @ViewBuilder
    func icon(size: CGFloat = 30) -> some View {
        switch self {
        case .calculator:
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: size * 0.9, weight: .bold))
        case .home:
            Image(systemName: "house.fill")
                .font(.system(size: size * 0.85, weight: .bold))
        case .numbers:
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: size * 0.85, weight: .bold))
        case .operations:
            CalculatorIcon(size: size)
        case .achievements:
            Image(systemName: "trophy.fill")
                .font(.system(size: size * 0.85, weight: .bold))
        }
    }
}

/// Idiomas de la app. El Mam no existe como idioma del sistema,
/// por eso el idioma se elige dentro de la app (tocando el avatar).
enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"
    case mam = "mam"

    var id: Self { self }

    /// Nombre en su propio idioma (no se traduce).
    var displayName: String {
        switch self {
        case .spanish: "Español"
        case .english: "English"
        case .mam: "Mam"
        }
    }
}
