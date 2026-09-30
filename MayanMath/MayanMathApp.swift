//
//  MayanMathApp.swift
//  MayanMath
//
//  Created by Jesus Ortega on 30/09/26.
//

import SwiftData
import SwiftUI

@main
struct MayanMathApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ChallengeRecord.self)
    }
}
