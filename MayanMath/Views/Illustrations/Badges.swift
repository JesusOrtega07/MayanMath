//
//  Badges.swift
//  MayanMath
//
//  Logo de la app, medallas de logros e íconos que no existen en SF Symbols.
//

import SwiftUI

// MARK: - Logo (tablilla con ●●● ▬ + − ×)

struct AppMark: View {
    var size: CGFloat = 84

    var body: some View {
        let s = size / 84
        VStack(spacing: 4 * s) {
            HStack(spacing: 4 * s) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().frame(width: 10 * s, height: 10 * s)
                }
            }
            Capsule().frame(width: 48 * s, height: 6 * s)
            HStack(spacing: 5 * s) {
                Text("+"); Text("−"); Text("×")
            }
            .font(.rounded(12 * s, weight: .black))
            .foregroundStyle(Color(hex: 0x006A3B))
        }
        .foregroundStyle(Color(hex: 0x182018))
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: 22 * s, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFDCA3), Color(hex: 0xEDB86F)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19 * s, style: .continuous)
                .strokeBorder(Color(hex: 0xFFE8BD), lineWidth: 3 * s)
                .padding(3 * s)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22 * s, style: .continuous)
                .strokeBorder(Color(hex: 0x49270B, opacity: 0.55), lineWidth: 3 * s)
        )
        .shadow(color: Color(hex: 0x003E24, opacity: 0.4), radius: 6 * s, y: 5 * s)
        .accessibilityHidden(true)
    }
}

// MARK: - Medallas

/// Medalla de una tarjeta de logro (72 pt en el Figma).
struct MedalView: View {
    var systemImage: String
    var earned: Bool
    var size: CGFloat = 72

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(earned ? Color(hex: 0x00713F) : Palette.medalLockedIcon)
            .frame(width: size, height: size)
            .background(Circle().fill(earned ? Palette.medalEarned : Palette.medalLocked))
            .overlay {
                if earned {
                    Circle().strokeBorder(Palette.medalEarnedRing, lineWidth: 6 * size / 72)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if earned {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: size / 3, height: size / 3)
                        .background(Circle().fill(Palette.medalCheck))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: 3, y: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.5, bounce: 0.5), value: earned)
            .accessibilityHidden(true)
    }
}

/// Medalla grande del encabezado de Logros (105 pt).
struct BigMedalView: View {
    var size: CGFloat = 105

    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: size * 0.46, weight: .bold))
            .foregroundStyle(Color(hex: 0x006E3D))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Palette.bigMedal)
                    .shadow(color: Palette.bigMedalShadow, radius: 0, y: 5)
            )
            .overlay(Circle().strokeBorder(Palette.medalEarnedRing, lineWidth: 8 * size / 105))
            .accessibilityHidden(true)
    }
}

// MARK: - Ícono de calculadora (no hay uno igual en SF Symbols)

struct CalculatorIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Lienzo de 24 × 24 del SVG original.
        let s = min(rect.width, rect.height) / 24
        let o = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }

        var path = Path()
        path.addRoundedRect(in: CGRect(origin: p(4, 2.5), size: CGSize(width: 16 * s, height: 19 * s)),
                            cornerSize: CGSize(width: 2.5 * s, height: 2.5 * s))
        path.move(to: p(7, 6)); path.addLine(to: p(17, 6))
        for y: CGFloat in [11, 15, 19] {
            for x: CGFloat in [7.5, 12, 16.5] {
                path.move(to: p(x, y)); path.addLine(to: p(x + 1, y))
            }
        }
        return path
    }
}

struct CalculatorIcon: View {
    var size: CGFloat = 28

    var body: some View {
        CalculatorIconShape()
            .stroke(style: StrokeStyle(lineWidth: 2.1 * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview("Insignias", traits: .landscapeLeft) {
    HStack(spacing: 30) {
        AppMark()
        MedalView(systemImage: "star.fill", earned: true)
        MedalView(systemImage: "lock.fill", earned: false)
        BigMedalView()
        CalculatorIcon(size: 40).foregroundStyle(Palette.green)
    }
    .padding(40)
    .background(Palette.background)
}
