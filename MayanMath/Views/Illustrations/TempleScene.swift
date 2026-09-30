//
//  TempleScene.swift
//  MayanMath
//
//  Paisaje con templo, sol y nubes (tarjeta de bienvenida) y la versión
//  pequeña con el personaje (tarjeta de nivel). Todo dibujado con código.
//

import SwiftUI

// MARK: - Templo

/// Silueta escalonada del templo (clip-path del Figma).
struct TempleShape: Shape {
    enum Style { case large, mini }
    var style: Style = .large

    func path(in rect: CGRect) -> Path {
        let points: [(CGFloat, CGFloat)] = switch style {
        case .large:
            [(33, 0), (67, 0), (72, 20), (82, 20), (87, 43), (95, 43), (100, 100),
             (0, 100), (5, 43), (13, 43), (18, 20), (28, 20)]
        case .mini:
            [(30, 0), (70, 0), (77, 25), (88, 25), (100, 100), (0, 100), (12, 25), (23, 25)]
        }
        var path = Path()
        for (index, point) in points.enumerated() {
            let p = CGPoint(x: rect.minX + rect.width * point.0 / 100,
                            y: rect.minY + rect.height * point.1 / 100)
            if index == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Templo con franjas de piedra y escalinatas.
struct TempleView: View {
    var style: TempleShape.Style = .large

    private var stone: Color { style == .large ? Color(hex: 0x9D8665) : Color(hex: 0xA38A68) }
    private var mortar: Color { style == .large ? Color(hex: 0xD0B88E) : Color(hex: 0xCCB791) }
    private let stairs = Color(hex: 0x5D5142)

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.clip(to: TempleShape(style: style).path(in: rect))

            // Franjas de piedra desde abajo (piedra 24 + junta 3 en el tamaño del Figma).
            let designHeight: CGFloat = style == .large ? 165 : 115
            let unit = size.height / designHeight
            let stoneHeight = (style == .large ? 24 : 18) * unit
            let jointHeight = 3 * unit
            context.fill(Path(rect), with: .color(mortar))
            var y = size.height
            while y > 0 {
                context.fill(Path(CGRect(x: 0, y: y - stoneHeight, width: size.width, height: stoneHeight)),
                             with: .color(stone))
                y -= stoneHeight + jointHeight
            }

            guard style == .large else { return }

            // Escalinata central y laterales inclinadas.
            let barWidth = size.width * 0.08
            context.fill(Path(CGRect(x: size.width * 0.46, y: 0, width: barWidth, height: size.height)),
                         with: .color(stairs))
            for (left, degrees) in [(0.27, 23.0), (0.65, -23.0)] {
                let bar = CGRect(x: size.width * left, y: size.height * 0.25,
                                 width: barWidth, height: size.height * 0.8)
                var copy = context
                copy.translateBy(x: bar.midX, y: bar.midY)
                copy.rotate(by: .degrees(degrees))
                copy.fill(Path(CGRect(x: -bar.width / 2, y: -bar.height / 2,
                                      width: bar.width, height: bar.height)),
                          with: .color(stairs))
            }
        }
        .shadow(color: Color(hex: 0x365B2D, opacity: 0.44), radius: 5, y: 8)
        .accessibilityHidden(true)
    }
}

// MARK: - Sol y nubes

struct SunView: View {
    var diameter: CGFloat = 55
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(Color(hex: 0xFFD15A))
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(Color(hex: 0xFFE792, opacity: 0.33))
                    .padding(-diameter * 0.22)
                    .phaseAnimator([false, true]) { halo, pulse in
                        halo.scaleEffect(pulse && animated && !reduceMotion ? 1.12 : 1)
                    } animation: { _ in .easeInOut(duration: 2.4) }
            )
            .accessibilityHidden(true)
    }
}

struct CloudView: View {
    var width: CGFloat = 90

    var body: some View {
        let s = width / 90
        ZStack(alignment: .bottomLeading) {
            Capsule().frame(width: 90 * s, height: 24 * s)
            Circle().frame(width: 35 * s, height: 35 * s).offset(x: 16 * s)
            Circle().frame(width: 45 * s, height: 45 * s).offset(x: (90 - 12 - 45) * s)
        }
        .foregroundStyle(.white.opacity(0.6))
        .frame(width: 90 * s, height: 45 * s, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }
}

/// Nube que se desliza suavemente de lado a lado.
private struct DriftingCloud: View {
    var width: CGFloat
    var distance: CGFloat
    var duration: Double
    var animated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CloudView(width: width)
            .phaseAnimator([false, true]) { cloud, moved in
                cloud.offset(x: moved && animated && !reduceMotion ? distance : 0)
            } animation: { _ in .easeInOut(duration: duration) }
    }
}

// MARK: - Escena grande (Inicio)

/// Paisaje de la tarjeta de bienvenida. Diseño de referencia: ~400 × 260.
struct TempleScene: View {
    var animated = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let s = h / 260

            ZStack(alignment: .topLeading) {
                // Cielo 60 % y pasto
                VStack(spacing: 0) {
                    Color(hex: 0xA9DEF2).frame(height: h * 0.6)
                    Color(hex: 0x9AC970)
                }

                SunView(diameter: 55 * s, animated: animated)
                    .position(x: w - (40 + 27.5) * s, y: (28 + 27.5) * s)

                DriftingCloud(width: 90 * s, distance: 18 * s, duration: 6, animated: animated)
                    .position(x: (30 + 45) * s, y: (53 + 10) * s)

                DriftingCloud(width: 63 * s, distance: -14 * s, duration: 7.5, animated: animated)
                    .position(x: w - (22 + 32) * s, y: (100 + 10) * s)

                TempleView(style: .large)
                    .frame(width: 200 * s, height: 165 * s)
                    .position(x: w / 2, y: h - (38 + 82.5) * s)

                // Colina en primer plano
                Ellipse()
                    .fill(Color(hex: 0x4E963F))
                    .frame(width: w * 1.1, height: 120 * s)
                    .position(x: w / 2, y: h - 64 * s + 60 * s)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(Text("Ilustración de un templo maya"))
    }
}

// MARK: - Escena pequeña (tarjeta de nivel)

/// Mini paisaje con templo y el personaje guía. Diseño de referencia: ~300 × 182.
struct MiniScene: View {
    var pose: GuideCharacter.Pose = .wave
    var animated = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let s = h / 182

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Color(hex: 0xBCE9F6).frame(height: h * 0.62)
                    Color(hex: 0x7CB85C)
                }

                CloudView(width: 60 * s)
                    .position(x: w * 0.72, y: 28 * s)

                TempleView(style: .mini)
                    .frame(width: 100 * s, height: 115 * s)
                    .position(x: w - w * 0.17 - 50 * s, y: h - (22 + 57.5) * s)

                GuideCharacter(pose: pose, animated: animated)
                    .frame(width: 130 * s, height: 170 * s)
                    .position(x: w * 0.2 + 55 * s, y: h - 170 * s / 2 + 18 * s)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview("Escenas", traits: .landscapeLeft) {
    HStack(spacing: 24) {
        TempleScene().frame(width: 420, height: 260)
        MiniScene().frame(width: 300, height: 182)
    }
    .padding()
}
