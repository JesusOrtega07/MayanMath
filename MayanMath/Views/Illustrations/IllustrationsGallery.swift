//
//  IllustrationsGallery.swift
//  MayanMath
//
//  Catálogo para revisar en el Canvas de Xcode todas las ilustraciones
//  y estilos programados. No se usa en la app.
//

#if DEBUG
import SwiftUI

struct IllustrationsGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section("Encabezado") {
                    HStack(spacing: 24) {
                        AppMark()
                        Spacer()
                        LanguageAvatar(languageName: "Español")
                        LanguageAvatar(languageName: "English")
                        LanguageAvatar(languageName: "Mam")
                    }
                    .padding(28)
                    .background(Palette.headerGradient, in: RoundedRectangle(cornerRadius: 20))
                }

                section("Escenas") {
                    HStack(spacing: 24) {
                        TempleScene().frame(width: 420, height: 260)
                        MiniScene(pose: .wave).frame(width: 300, height: 182)
                    }
                }

                section("Personaje guía") {
                    HStack(spacing: 24) {
                        ForEach([GuideCharacter.Pose.wave, .point, .celebrate, .think], id: \.self) { pose in
                            GuideCharacter(pose: pose)
                                .frame(width: 150, height: 195)
                                .mmPanel()
                        }
                    }
                }

                section("Números mayas") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 16) {
                        ForEach(MayanDigit.all) { digit in
                            VStack(spacing: 6) {
                                MayanDigitGlyph(digit: digit, scale: 0.55)
                                    .frame(height: 80)
                                Text("\(digit.value)").font(.rounded(18, weight: .black))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Palette.tile, in: RoundedRectangle(cornerRadius: Metrics.tileRadius))
                        }
                    }
                    HStack(spacing: 30) {
                        MayanNumberGlyph(number: MayanNumber(315), scale: 0.6)
                        MayanNumberGlyph(number: MayanNumber(400), scale: 0.6)
                    }
                }

                section("Logros y botones") {
                    HStack(spacing: 24) {
                        BigMedalView()
                        MedalView(systemImage: "square.grid.3x3.fill", earned: true)
                        MedalView(systemImage: "lock.fill", earned: false)
                        Button("Continuar aprendiendo") {}
                            .buttonStyle(PrimaryButtonStyle())
                        Button {} label: { Image(systemName: "speaker.wave.2.fill") }
                            .buttonStyle(CircleButtonStyle())
                        CalculatorIcon(size: 36).foregroundStyle(Palette.green)
                    }
                }
            }
            .padding(Metrics.pagePadding)
        }
        .background(Palette.appBackground)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).mmEyebrow()
            content()
        }
    }
}

#Preview("Galería", traits: .landscapeLeft) {
    IllustrationsGallery()
}
#endif
