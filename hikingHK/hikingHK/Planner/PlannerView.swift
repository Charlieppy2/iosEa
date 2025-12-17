//
//  PlannerView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData

/// Planner screen for scheduling upcoming hikes and jumping into the gear checklist.
struct PlannerView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedTrail: Trail?
    @State private var plannedDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var note = ""
    @State private var showSaveSuccess = false
    @State private var isShowingGearChecklist = false

    var body: some View {
        NavigationStack {
            Form {
                // Trail selection section
                Section(languageManager.localizedString(for: "planner.choose.trail")) {
                    Picker(languageManager.localizedString(for: "trails.title"), selection: $selectedTrail) {
                        ForEach(viewModel.trails) { trail in
                            Text(trail.localizedName(languageManager: languageManager)).tag(Optional(trail))
                        }
                    }
                }
                // Date and note section
                Section(languageManager.localizedString(for: "planner.schedule")) {
                    DatePicker(languageManager.localizedString(for: "planner.date"), selection: $plannedDate, displayedComponents: .date)
                    TextField(languageManager.localizedString(for: "planner.note"), text: $note)
                }
                // Preview of the selected trail and basic stats
                Section(languageManager.localizedString(for: "planner.preview")) {
                    if let trail = selectedTrail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trail.localizedName(languageManager: languageManager))
                                .font(.headline)
                            Label(trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.and.ellipse")
                            Label {
                                Text("\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km • \(trail.estimatedDurationMinutes / 60) h")
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }
                    } else {
                        Text(languageManager.localizedString(for: "planner.select.trail"))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Optional gear checklist entry point once a trail is selected
                if selectedTrail != nil {
                    Section {
                        Button {
                            isShowingGearChecklist = true
                        } label: {
                            HStack {
                                Image(systemName: "backpack.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                Text(languageManager.localizedString(for: "gear.view.checklist"))
                                    .foregroundStyle(Color.hikingDarkGreen)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .navigationTitle(languageManager.localizedString(for: "planner.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "save")) {
                        if let trail = selectedTrail {
                            viewModel.addSavedHike(for: trail, scheduledDate: plannedDate, note: note)
                            // Reset the form to a fresh state after saving a plan
                            note = ""
                            selectedTrail = nil
                            plannedDate = Date().addingTimeInterval(60 * 60 * 24)
                            showSaveSuccess = true
                        }
                    }
                    .disabled(selectedTrail == nil)
                }
            }
            .alert(languageManager.localizedString(for: "planner.saved"), isPresented: $showSaveSuccess) {
                Button(languageManager.localizedString(for: "ok"), role: .cancel) {}
            } message: {
                Text(languageManager.localizedString(for: "planner.saved.message"))
            }
            .sheet(isPresented: $isShowingGearChecklist) {
                if let trail = selectedTrail {
                    GearChecklistView(
                        trail: trail,
                        weather: viewModel.weatherSnapshot,
                        scheduledDate: plannedDate
                    )
                }
            }
        }
    }
}

#Preview {
    PlannerView()
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
        .modelContainer(for: [SavedHikeRecord.self, GearItem.self], inMemory: true)
}

