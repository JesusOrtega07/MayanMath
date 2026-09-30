//
//  HomeView.swift
//  MayanMath
//
//  Inicio (Figma "Mundo Maya"): tarjeta de bienvenida con el templo,
//  "¿Qué quieres aprender hoy?" y el progreso de los retos.
//

import SwiftUI

struct HomeView: View {
    var completedChallenges: Int
    var totalChallenges: Int
    var onContinue: () -> Void
    var onOpen: (AppSection) -> Void

    @State private var appeared = false

    private struct Activity: Identifiable {
        let section: AppSection
        let title: LocalizedStringKey
        let text: LocalizedStringKey
        let tint: Color
        var id: AppSection { section }
    }

    private let activities: [Activity] = [
        Activity(section: .numbers, title: "Números mayas",
                 text: "Descubre cómo se forman los números del 1 al 30 con puntos y barras.",
                 tint: Palette.activityGreen),
        Activity(section: .challenges, title: "Retos",
                 text: "Convierte números como el 23 a números mayas y gana estrellas.",
                 tint: Palette.activityOrange),
        Activity(section: .calculator, title: "Calculadora maya",
                 text: "Suma, resta, multiplica y divide usando símbolos mayas.",
                 tint: Color(hex: 0xE6F1F7)),
        Activity(section: .achievements, title: "Mis logros",
                 text: "Mira tus medallas y todo lo que has aprendido.",
                 tint: Palette.activityYellow)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                welcomeCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                heading
                    .padding(.top, 32)
                    .padding(.bottom, 16)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                          spacing: 18) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        activityCard(activity)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.12 + Double(index) * 0.06),
                                       value: appeared)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.25)) { appeared = true }
        }
    }

    // MARK: - Bienvenida

    private var welcomeCard: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Tu aventura continúa")
                    .mmEyebrow()
                Text("Aprende a contar\ncomo los antiguos mayas")
                    .font(.rounded(46, weight: .black))
                    .tracking(-1.4)
                    .foregroundStyle(Palette.heading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                Text("Supera retos, gana estrellas y descubre una de las formas de contar más ingeniosas del mundo.")
                    .font(.rounded(17, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
                Button("Continuar aprendiendo", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TempleScene()
                .frame(width: 380, height: 260)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [.white, Color(hex: 0xEEF8E9)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color(hex: 0x4D3515, opacity: 0.08), radius: 8, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color(hex: 0xDEDED1), lineWidth: 1)
        )
    }

    // MARK: - Encabezado de actividades

    private var heading: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Elige una actividad").mmEyebrow()
                Text("¿Qué quieres aprender hoy?")
                    .font(.rounded(28, weight: .black))
                    .foregroundStyle(Palette.heading)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(completedChallenges) de \(totalChallenges)")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Palette.green)
                    .contentTransition(.numericText(value: Double(completedChallenges)))
                Text("retos completados")
                    .font(.rounded(15, weight: .semibold))
                    .foregroundStyle(Palette.textMuted)
                ProgressView(value: Double(completedChallenges), total: Double(max(totalChallenges, 1)))
                    .tint(Palette.greenBright)
                    .frame(width: 160)
            }
        }
    }

    // MARK: - Tarjeta de actividad

    private func activityCard(_ activity: Activity) -> some View {
        Button {
            onOpen(activity.section)
        } label: {
            HStack(spacing: 18) {
                activity.section.icon(size: 36)
                    .foregroundStyle(Palette.navActiveText)
                    .frame(width: 69, height: 69)
                    .background(activity.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(activity.title)
                        .font(.rounded(20, weight: .black))
                        .foregroundStyle(Palette.ink)
                    Text(activity.text)
                        .font(.rounded(14, weight: .semibold))
                        .foregroundStyle(Palette.textMuted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Palette.greenBright, in: Circle())
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 124)
            .background(.white, in: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(Color(hex: 0xE6DACE), lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x4C3210, opacity: 0.06), radius: 4, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: Metrics.cardRadius))
        }
        .buttonStyle(LiftButtonStyle())
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView(completedChallenges: 3, totalChallenges: 30, onContinue: {}, onOpen: { _ in })
        .background(Palette.appBackground)
}
