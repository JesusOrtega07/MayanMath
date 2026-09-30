//
//  Theme.swift
//  MayanMath
//
//  Sistema de diseño: colores, tipografía y medidas tomados del Figma "Mundo Maya".
//

import SwiftUI

// MARK: - Color desde hex

extension Color {
    /// `Color(hex: 0x00733F)`
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Paleta

enum Palette {
    // Verdes de marca
    static let green = Color(hex: 0x00733F)          // botones principales, pestaña activa
    static let greenPressed = Color(hex: 0x004C2B)   // "sombra" 3D de los botones
    static let greenDark = Color(hex: 0x005B34)
    static let greenMid = Color(hex: 0x007840)
    static let greenDeep = Color(hex: 0x006334)
    static let greenText = Color(hex: 0x087044)      // títulos de ayuda, "eyebrow"
    static let greenSoft = Color(hex: 0x075F37)
    static let greenBright = Color(hex: 0x09814A)    // barras de progreso

    // Fondos
    static let background = Color(hex: 0xF7F1E9)
    static let backgroundHighlight = Color(hex: 0xFFFDF9)
    static let sidebar = Color(hex: 0xFFFAF4)
    static let sidebarBorder = Color(hex: 0xEADBCB)
    static let navActive = Color(hex: 0xF0ECE2)
    static let navActiveText = Color(hex: 0x006E3D)
    static let panel = Color.white.opacity(0.91)
    static let panelBorder = Color(hex: 0xEADFD4)
    static let panelShadow = Color(hex: 0x54371A, opacity: 0.07)

    // Texto
    static let ink = Color(hex: 0x171B17)
    static let heading = Color(hex: 0x14251C)
    static let textSecondary = Color(hex: 0x4F5C54)
    static let textMuted = Color(hex: 0x667069)

    // Acentos
    static let star = Color(hex: 0xFFC432)
    static let gold = Color(hex: 0xFFD55E)
    static let goldText = Color(hex: 0x714B00)
    static let focus = Color(hex: 0xF2B629)

    // Área de construcción
    static let zoneGreenFill = Color(hex: 0xF4F7EE)
    static let zoneGreenBorder = Color(hex: 0x7DAE78)
    static let zoneGoldFill = Color(hex: 0xFFF8F0)
    static let zoneGoldBorder = Color(hex: 0xD4A659)
    static let zoneNeutralFill = Color(hex: 0xFAF9F5)
    static let zoneNeutralBorder = Color(hex: 0xB9C7D6)
    static let zoneLabel = Color(hex: 0x9BBB85)

    // Paleta de fichas
    static let tile = Color(hex: 0xFBEFE3)
    static let tilePressed = Color(hex: 0xF2DFCA)
    static let glyph = Color(hex: 0x121412)

    // Tarjetas de ayuda
    static let fact = Color(hex: 0xFAF2E9)
    static let tip = Color(hex: 0xF5F2E8)
    static let helpCard = Color(hex: 0xFBF7F0)
    static let resultCard = Color(hex: 0xEDF2E5)

    // Tarjetas de actividad (Inicio)
    static let activityGreen = Color(hex: 0xE8F3E8)
    static let activityOrange = Color(hex: 0xFFF1DF)
    static let activityYellow = Color(hex: 0xFFF7D8)

    // Logros
    static let medalEarned = Color(hex: 0xFFDC6A)
    static let medalEarnedRing = Color(hex: 0xFFF0B4)
    static let medalLocked = Color(hex: 0xECEBE7)
    static let medalLockedIcon = Color(hex: 0x7B817D)
    static let medalCheck = Color(hex: 0x07834B)
    static let bigMedal = Color(hex: 0xFFCF49)
    static let bigMedalShadow = Color(hex: 0xD69C16)
    static let progressTrack = Color(hex: 0xE9E7E1)

    // Encabezado
    static let headerGradient = LinearGradient(
        stops: [
            .init(color: greenDark, location: 0),
            .init(color: greenMid, location: 0.56),
            .init(color: greenDeep, location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appBackground = RadialGradient(
        colors: [backgroundHighlight, Color(hex: 0xF8F1E8)],
        center: UnitPoint(x: 0.7, y: 0.1),
        startRadius: 0,
        endRadius: 900
    )
}

// MARK: - Tipografía (SF Pro Rounded)

extension Font {
    /// Tipografía de la app: SF Pro Rounded (equivalente de Apple a Nunito).
    static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let mmHeaderTitle = rounded(40, weight: .black)
    static let mmHeaderSubtitle = rounded(20, weight: .bold)
    static let mmPanelTitle = rounded(23, weight: .black)
    static let mmEyebrow = rounded(14, weight: .black)
    static let mmBody = rounded(17, weight: .semibold)
    static let mmCaption = rounded(13, weight: .bold)
}

// MARK: - Medidas

enum Metrics {
    static let panelRadius: CGFloat = 24
    static let cardRadius: CGFloat = 22
    static let zoneRadius: CGFloat = 19
    static let tileRadius: CGFloat = 14
    static let pagePadding: CGFloat = 32
    static let gridSpacing: CGFloat = 24
    static let sidebarWidth: CGFloat = 150
    static let headerHeight: CGFloat = 148
}

// MARK: - Estilos reutilizables

extension View {
    /// Tarjeta blanca con borde y sombra suave (`.panel` del Figma).
    func mmPanel(radius: CGFloat = Metrics.panelRadius) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.panel)
                .shadow(color: Palette.panelShadow, radius: 4, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Palette.panelBorder, lineWidth: 1)
        )
    }

    /// Etiqueta en mayúsculas verde ("TU AVENTURA CONTINÚA").
    func mmEyebrow() -> some View {
        font(.mmEyebrow)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Palette.greenText)
    }
}

/// Botón verde con "sombra sólida" que se hunde al presionarlo.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(18, weight: .black))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.green)
                    .shadow(color: Palette.greenPressed, radius: 0, y: configuration.isPressed ? 1 : 5)
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.spring(duration: 0.25, bounce: 0.4), value: configuration.isPressed)
    }
}

/// Botón redondo verde (audio, borrar).
struct CircleButtonStyle: ButtonStyle {
    var diameter: CGFloat = 62

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: diameter * 0.36, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(Palette.green)
                    .shadow(color: Palette.greenPressed, radius: 0, y: configuration.isPressed ? 1 : 4)
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(duration: 0.25, bounce: 0.4), value: configuration.isPressed)
    }
}

/// Efecto de "levantarse" al presionar (tarjetas de actividad, fichas).
struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: configuration.isPressed)
    }
}
