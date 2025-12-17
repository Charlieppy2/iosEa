//
//  LanguageManager.swift
//  hikingHK
//
//  Created for language switching functionality
//

import Foundation
import SwiftUI
import Combine

/// Supported application languages.
enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .traditionalChinese:
            return "繁體中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇬🇧"
        case .traditionalChinese:
            return "🇭🇰"
        }
    }
}

/// Global language controller used to switch between English and Traditional Chinese.
@MainActor
final class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    /// Shared singleton instance used across the whole app.
    static let shared = LanguageManager()
    
    /// Reads the saved language from UserDefaults or falls back to English.
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .english
        }
    }
    
    /// Returns the localized string for the given key in the current language.
    nonisolated func localizedString(for key: String) -> String {
        // Access currentLanguage safely – it's only read, not modified
        let language = MainActor.assumeIsolated { currentLanguage }
        return LocalizedStrings.shared.getString(for: key, language: language)
    }
}

// Helper extension for easy access.
// Note: This extension doesn't trigger view updates automatically.
// For views that need to update when language changes, use LocalizedText or observe LanguageManager directly.
extension String {
    var localized: String {
        LanguageManager.shared.localizedString(for: self)
    }
}

// A view that automatically updates whenever the app language changes.
struct LocalizedText: View {
    let key: String
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Text(languageManager.localizedString(for: key))
    }
}

