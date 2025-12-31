//
//  LocalizedMapView.swift
//  hikingHK
//
//  Helper to set map language based on app language settings
//

import SwiftUI
import MapKit

/// Extension to help set map language
extension View {
    /// Sets the map language based on the app's language setting
    /// Note: SwiftUI Map primarily uses system language, but we set the locale preference
    func mapLanguage(_ languageManager: LanguageManager) -> some View {
        self.environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
            .onAppear {
                // Set MKMapView locale preference when view appears
                setMapKitLocale(languageManager: languageManager)
            }
            .onChange(of: languageManager.currentLanguage) { oldValue, newValue in
                // Update MKMapView locale preference when language changes
                setMapKitLocale(languageManager: languageManager)
            }
    }
}

/// Sets the MapKit locale preference
/// Note: SwiftUI Map uses system language by default
/// For full control, we would need UIViewRepresentable with MKMapView.locale
private func setMapKitLocale(languageManager: LanguageManager) {
    let localeIdentifier = languageManager.currentLanguage == .traditionalChinese 
        ? "zh_Hant_HK" 
        : "en_US"
    
    // Store the locale preference for MapKit
    // Note: SwiftUI Map primarily uses system language
    // This preference can be used if we switch to UIViewRepresentable with MKMapView
    UserDefaults.standard.set(localeIdentifier, forKey: "AppPreferredMapLanguage")
    UserDefaults.standard.synchronize()
    
    // Note: For full control over map language, we would need to:
    // 1. Use UIViewRepresentable to wrap MKMapView
    // 2. Set MKMapView.locale property directly
    // However, SwiftUI Map should respect the system language setting
    // The best approach is to ensure the app's locale matches the desired map language
}

