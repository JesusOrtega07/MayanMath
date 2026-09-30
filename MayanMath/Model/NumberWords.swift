//
//  NumberWords.swift
//  MayanMath
//
//  Nombre del número en letras ("Veintitrés") y lectura en voz alta.
//  El Mam no tiene voz ni nombres en el sistema: devuelve nil hasta tener traducciones validadas.
//

import AVFoundation
import Foundation

nonisolated enum NumberWords {
    static func word(for value: Int, language: AppLanguage) -> String? {
        guard let identifier = language.speechLocaleIdentifier else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: identifier)
        guard let word = formatter.string(from: NSNumber(value: value)) else { return nil }
        return word.prefix(1).uppercased() + word.dropFirst()
    }
}

nonisolated extension AppLanguage {
    /// Idioma para nombres de números y voz. `nil` en Mam.
    var speechLocaleIdentifier: String? {
        switch self {
        case .spanish: "es-MX"
        case .english: "en-US"
        case .mam: nil
        }
    }
}

/// Lee números en voz alta con la voz del sistema.
final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func canSpeak(in language: AppLanguage) -> Bool {
        language.speechLocaleIdentifier != nil
    }

    func speak(number value: Int, language: AppLanguage) {
        guard let identifier = language.speechLocaleIdentifier,
              let word = NumberWords.word(for: value, language: language) else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }
}
