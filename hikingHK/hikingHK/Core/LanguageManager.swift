//
//  LanguageManager.swift
//  hikingHK
//
//  Created for language switching functionality
//

import Foundation
import SwiftUI
import Combine

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

@MainActor
final class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    static let shared = LanguageManager()
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .english
        }
    }
    
    func localizedString(for key: String) -> String {
        return LocalizedStrings.shared.getString(for: key, language: currentLanguage)
    }
}

// Helper extension for easy access
extension String {
    var localized: String {
        LanguageManager.shared.localizedString(for: self)
    }
}

