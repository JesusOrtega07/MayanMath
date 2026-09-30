//
//  ContentView.swift
//  MayanMath
//
//  Vista principal: encabezado + barra lateral + sección activa.
//  La app abre en la Calculadora.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var section: AppSection = .calculator
    /// Los ViewModels viven aquí para conservar su estado al cambiar de sección.
    @State private var calculator = CalculatorViewModel()
    @State private var challenge = ChallengeViewModel()

    @AppStorage("appLanguage") private var language: AppLanguage = .spanish
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [ChallengeRecord]

    private var totalStars: Int { records.reduce(0) { $0 + $1.stars } }
    private var completedNumbers: Set<Int> { Set(records.map(\.number)) }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(section: section, stars: totalStars, language: $language)

            HStack(spacing: 0) {
                AppSidebar(selection: $section)

                Group {
                    switch section {
                    case .calculator:
                        CalculatorView(viewModel: calculator)
                    case .home:
                        HomeView(
                            completedChallenges: completedNumbers.count,
                            totalChallenges: ChallengeCatalog.numbers.count,
                            onContinue: {
                                challenge.select(ChallengeCatalog.firstPending(completed: completedNumbers))
                                go(to: .challenges)
                            },
                            onOpen: { go(to: $0) }
                        )
                    case .numbers:
                        NumbersView(onPractice: { number in
                            challenge.select(number)
                            go(to: .challenges)
                        })
                    case .challenges:
                        ChallengesView(viewModel: challenge)
                    case .operations, .achievements:
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
        .onAppear {
            challenge.attach(ProgressRepository(context: modelContext))
        }
    }

    private func go(to newSection: AppSection) {
        withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
            section = newSection
        }
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
        .modelContainer(for: ChallengeRecord.self, inMemory: true)
}
