//
//  GuideCharacter.swift
//  MayanMath
//
//  Personaje guía: niño/a maya en estilo plano, dibujado con formas de SwiftUI.
//  Todo se diseña en un lienzo de 200 × 260 y se escala al tamaño disponible.
//

import SwiftUI

private enum CharacterColors {
    static let skin = Color(hex: 0xC98556)
    static let skinShade = Color(hex: 0xB0703F)
    static let hair = Color(hex: 0x2B1B14)
    static let headband = Color(hex: 0xC8372D)
    static let pattern = Color(hex: 0xFFD55E)
    static let tunic = Color(hex: 0xEF9D42)
    static let tunicShade = Color(hex: 0xD9832A)
    static let necklace = Color(hex: 0xF2B629)
    static let eye = Color(hex: 0x1E140F)
    static let mouth = Color(hex: 0x6B2A1A)
    static let cheek = Color(hex: 0xF08A7A)
}

// MARK: - Cara (se reutiliza en el avatar)

/// Cabeza del personaje. Lienzo de diseño: 130 × 130.
struct GuideFace: View {
    var expression: Expression = .happy
    var animated = true

    enum Expression { case happy, excited, thinking }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cabello detrás
            Ellipse()
                .fill(CharacterColors.hair)
                .frame(width: 120, height: 118)
                .position(x: 65, y: 62)

            // Cabeza
            Circle()
                .fill(CharacterColors.skin)
                .frame(width: 104, height: 104)
                .position(x: 65, y: 70)

            // Fleco
            Ellipse()
                .fill(CharacterColors.hair)
                .frame(width: 108, height: 52)
                .position(x: 65, y: 30)

            // Banda de la cabeza con patrón
            Capsule()
                .fill(CharacterColors.headband)
                .frame(width: 112, height: 16)
                .overlay {
                    HStack(spacing: 11) {
                        ForEach(0..<6, id: \.self) { _ in
                            Rectangle()
                                .fill(CharacterColors.pattern)
                                .frame(width: 6, height: 6)
                                .rotationEffect(.degrees(45))
                        }
                    }
                }
                .position(x: 65, y: 44)

            // Mejillas
            ForEach([38.0, 92.0], id: \.self) { x in
                Circle()
                    .fill(CharacterColors.cheek.opacity(0.4))
                    .frame(width: 16, height: 16)
                    .position(x: x, y: 88)
            }

            eyes
            mouth
        }
        .frame(width: 130, height: 130)
    }

    private var eyes: some View {
        let lookUp: CGFloat = expression == .thinking ? -4 : 0
        return HStack(spacing: 26) {
            ForEach(0..<2, id: \.self) { _ in
                Ellipse()
                    .fill(CharacterColors.eye)
                    .frame(width: 12, height: 16)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(.white).frame(width: 4, height: 4).offset(x: -2, y: 3)
                    }
            }
        }
        .offset(y: lookUp)
        .phaseAnimator([1.0, 1.0, 0.1]) { content, scaleY in
            content.scaleEffect(x: 1, y: animated && !reduceMotion ? scaleY : 1)
        } animation: { scaleY in
            scaleY < 1 ? .easeIn(duration: 0.07) : .easeOut(duration: 0.1).delay(1.6)
        }
        .position(x: 65, y: 72)
    }

    @ViewBuilder
    private var mouth: some View {
        switch expression {
        case .happy:
            SmileShape()
                .stroke(CharacterColors.mouth, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 26, height: 10)
                .position(x: 65, y: 98)
        case .excited:
            SmileShape(closed: true)
                .fill(CharacterColors.mouth)
                .frame(width: 26, height: 14)
                .position(x: 65, y: 99)
        case .thinking:
            Capsule()
                .fill(CharacterColors.mouth)
                .frame(width: 14, height: 3.5)
                .position(x: 70, y: 99)
        }
    }
}

/// Sonrisa: arco hacia abajo (abierta si `closed`).
private struct SmileShape: Shape {
    var closed = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.maxY * 2 - rect.minY))
        if closed { path.closeSubpath() }
        return path
    }
}

// MARK: - Cuerpo completo

struct GuideCharacter: View {
    enum Pose {
        /// Saluda con la mano (bienvenida, tarjeta de nivel).
        case wave
        /// Señala hacia un lado (consejos, ayuda).
        case point
        /// Brazos arriba (respuesta correcta).
        case celebrate
        /// Mano en la barbilla (inténtalo de nuevo).
        case think
    }

    var pose: Pose = .wave
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 200, geo.size.height / 260)
            figure
                .frame(width: 200, height: 260)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: 200 * scale, height: 260 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Personaje guía"))
    }

    private var figure: some View {
        ZStack {
            // Cabello largo por detrás de los hombros
            RoundedRectangle(cornerRadius: 40)
                .fill(CharacterColors.hair)
                .frame(width: 112, height: 120)
                .position(x: 100, y: 118)

            arm(side: .leading)
            arm(side: .trailing)

            // Túnica
            UnevenRoundedRectangle(topLeadingRadius: 44, bottomLeadingRadius: 10,
                                   bottomTrailingRadius: 10, topTrailingRadius: 44)
                .fill(CharacterColors.tunic)
                .frame(width: 110, height: 100)
                .overlay(alignment: .bottom) {
                    // Franja bordada
                    Rectangle()
                        .fill(CharacterColors.headband)
                        .frame(height: 14)
                        .overlay {
                            HStack(spacing: 9) {
                                ForEach(0..<7, id: \.self) { _ in
                                    Circle().fill(CharacterColors.pattern).frame(width: 5, height: 5)
                                }
                            }
                        }
                        .padding(.bottom, 16)
                }
                .position(x: 100, y: 210)

            // Collar
            Circle()
                .trim(from: 0.1, to: 0.4)
                .stroke(CharacterColors.necklace, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 70, height: 70)
                .position(x: 100, y: 142)

            GuideFace(expression: expression, animated: animated)
                .position(x: 100, y: 88)
        }
        .phaseAnimator([false, true]) { content, up in
            content.offset(y: up && animated && !reduceMotion ? -3 : 0)
        } animation: { _ in .easeInOut(duration: 1.4) }
    }

    private var expression: GuideFace.Expression {
        switch pose {
        case .wave, .point: .happy
        case .celebrate: .excited
        case .think: .thinking
        }
    }

    private enum Side { case leading, trailing }

    /// Brazo que gira desde el hombro.
    private func arm(side: Side) -> some View {
        let isTrailing = side == .trailing
        let shoulder = CGPoint(x: isTrailing ? 142 : 58, y: 172)
        let length: CGFloat = pose == .think && isTrailing ? 62 : 72
        let restAngle: Double = isTrailing ? -18 : 18

        let angle: Double = switch (pose, side) {
        case (.wave, .trailing): -150
        case (.point, .trailing): -95
        case (.celebrate, .trailing): -155
        case (.celebrate, .leading): 155
        case (.think, .trailing): 150
        default: restAngle
        }
        let waves = pose == .wave && isTrailing

        return Capsule()
            .fill(CharacterColors.skin)
            .overlay(alignment: .bottom) {
                Circle().fill(CharacterColors.skinShade).frame(width: 26, height: 26)
            }
            .frame(width: 26, height: length)
            .phaseAnimator([0.0, 1.0]) { content, t in
                content.rotationEffect(
                    .degrees(angle + (waves && animated && !reduceMotion ? t * 18 : 0)),
                    anchor: .top
                )
            } animation: { _ in .easeInOut(duration: 0.45) }
            .position(x: shoulder.x, y: shoulder.y + length / 2)
    }
}

// MARK: - Avatar del encabezado

/// Cara del personaje en un círculo con el idioma activo debajo.
struct LanguageAvatar: View {
    var languageName: String
    var diameter: CGFloat = 70

    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(Color(hex: 0xEFAE59))
                .overlay {
                    GuideFace(expression: .happy)
                        .scaleEffect(diameter / 110)
                        .offset(y: diameter * 0.08)
                }
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 4))
                .frame(width: diameter, height: diameter)
                .shadow(color: Color(hex: 0x003D24, opacity: 0.38), radius: 4, y: 3)

            Text(languageName)
                .font(.rounded(12, weight: .heavy))
                .foregroundStyle(Color(hex: 0x24180E))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(hex: 0xFFF4D6), in: RoundedRectangle(cornerRadius: 7))
                .fixedSize()
                .offset(y: 17)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement()
        .accessibilityLabel(Text("Idioma: \(languageName)"))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Personaje", traits: .landscapeLeft) {
    HStack(spacing: 30) {
        ForEach([GuideCharacter.Pose.wave, .point, .celebrate, .think], id: \.self) { pose in
            GuideCharacter(pose: pose).frame(width: 160, height: 210)
        }
        LanguageAvatar(languageName: "Español")
    }
    .padding(40)
    .background(Palette.background)
}
