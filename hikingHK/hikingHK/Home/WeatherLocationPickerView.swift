//
//  WeatherLocationPickerView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

struct WeatherLocationPickerView: View {
    let snapshots: [WeatherSnapshot]
    @Binding var selectedIndex: Int
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(snapshots.enumerated()), id: \.offset) { index, snapshot in
                    Button {
                        selectedIndex = index
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localizedLocation(snapshot.location))
                                    .font(.headline)
                                    .foregroundStyle(Color.hikingDarkGreen)
                                HStack(spacing: 16) {
                                    Label("\(String(format: "%.1f", snapshot.temperature))°C", systemImage: "thermometer")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.hikingBrown)
                                    Label("\(snapshot.humidity)%", systemImage: "drop")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.hikingBrown)
                                    Label("\(snapshot.uvIndex)", systemImage: "sun.max")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.hikingBrown)
                                }
                            }
                            Spacer()
                            if index == selectedIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.hikingBackground)
            .navigationTitle(languageManager.localizedString(for: "weather.select.location"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.hikingBackground)
    }
    
    private func localizedLocation(_ location: String) -> String {
        // Prefer Hong Kong Observatory label
        if location == "Hong Kong Observatory" {
            return languageManager.localizedString(for: "weather.location.hko")
        }
        // Localize other known locations
        let locationKey = "weather.location.\(location.lowercased().replacingOccurrences(of: " ", with: ".").replacingOccurrences(of: "'", with: ""))"
        let localized = languageManager.localizedString(for: locationKey)
        return localized != locationKey ? localized : location
    }
}

