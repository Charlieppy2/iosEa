//
//  WeatherLocationSearchView.swift
//  hikingHK
//
//  Allows users to search hiking trails and view weather forecast for any location.
//

import SwiftUI

struct WeatherLocationSearchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    
    var onTrailSelected: (Trail) -> Void
    
    private var filteredTrails: [Trail] {
        guard !searchText.isEmpty else { return appViewModel.trails }
        return appViewModel.trails.filter { trail in
            let name = trail.localizedName(languageManager: languageManager)
            let district = trail.localizedDistrict(languageManager: languageManager)
            return name.localizedCaseInsensitiveContains(searchText) ||
                   district.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTrails) { trail in
                    Button {
                        onTrailSelected(trail)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trail.localizedName(languageManager: languageManager))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(trail.localizedDistrict(languageManager: languageManager))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.hikingGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "weather.region"))
            .searchable(text: $searchText, prompt: languageManager.localizedString(for: "trails.search.prompt"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}


