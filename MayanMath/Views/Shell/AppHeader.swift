//
//  AppHeader.swift
//  MayanMath
//
//  Encabezado verde: logo, título de la sección, estrellas y avatar (idioma).
//

import SwiftUI

struct AppHeader: View {
    let section: AppSection
    var stars: Int
    @Binding var language: AppLanguage

    var body: some View {
        HStack(spacing: 28) {
            AppMark(size: 76)

            VStack(spacing: 4) {
                Text(section.title)
                    .font(.rounded(36, weight: .black))
                    .tracking(-0.6)
                Text(section.subtitle)
                    .font(.rounded(19, weight: .bold))
                    .opacity(0.96)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .id(section)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 8)),
                removal: .opacity
            ))

            HStack(spacing: 18) {
                StarPill(stars: stars)

                Menu {
                    Picker("Idioma", selection: $language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(verbatim: language.displayName).tag(language)
                        }
                    }
                } label: {
                    LanguageAvatar(languageName: language.displayName)
                        .padding(.bottom, 14) // espacio para la etiqueta del idioma
                }
                .menuIndicator(.hidden)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 44)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Palette.headerGradient.ignoresSafeArea(edges: .top))
    }
}

/// Píldora blanca con el total de estrellas.
struct StarPill: View {
    var stars: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 22))
                .foregroundStyle(Palette.star)
            Text(stars, format: .number)
                .font(.rounded(20, weight: .black))
                .foregroundStyle(Color(hex: 0x151515))
                .contentTransition(.numericText(value: Double(stars)))
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 110, minHeight: 52)
        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color(hex: 0x003D24, opacity: 0.38), radius: 4, y: 3)
        .animation(.spring(duration: 0.5), value: stars)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(stars) estrellas"))
    }
}
