//
//  PlannerView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData

/// Planner screen for scheduling upcoming hikes and jumping into the gear checklist.
struct PlannerView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTrail: Trail?
    @State private var plannedDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var note = ""
    @State private var showSaveSuccess = false
    @State private var isShowingGearChecklist = false
    @StateObject private var weatherAlertManager = WeatherAlertManager()
    @State private var isCheckingWeather = false
    @State private var weatherCheckResult: (isSafe: Bool, message: String)?

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
                    HStack {
                        Text(languageManager.localizedString(for: "planner.date"))
                        Spacer()
                        Text(formattedDate(plannedDate))
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("", selection: $plannedDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
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
                
                // Weather check section
                if selectedTrail != nil {
                    Section {
                        Button {
                            Task {
                                await checkWeatherBeforeHike()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "cloud.sun.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                Text(languageManager.localizedString(for: "weather.alert.pre.hike.check"))
                                    .foregroundStyle(Color.hikingDarkGreen)
                                Spacer()
                                if isCheckingWeather {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(isCheckingWeather)
                        
                        if let result = weatherCheckResult {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: result.isSafe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(result.isSafe ? Color.green : Color.orange)
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundStyle(result.isSafe ? Color.primary : Color.orange)
                            }
                            .padding(.vertical, 4)
                        }
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
            .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
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
                        guard let accountId = sessionManager.currentUser?.id else { return }
                        if let trail = selectedTrail {
                            viewModel.addSavedHike(for: trail, scheduledDate: plannedDate, note: note, accountId: accountId)
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
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
    }
    
    /// Format date in localized format
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Checks weather before the planned hike
    private func checkWeatherBeforeHike() async {
        isCheckingWeather = true
        let language = languageManager.currentLanguage.rawValue
        let result = await weatherAlertManager.checkWeatherBeforeHike(
            scheduledDate: plannedDate,
            language: language
        )
        weatherCheckResult = result
        isCheckingWeather = false
    }
}

/// Planner view with a pre-selected trail (used from recommendations)
struct PlannerViewWithTrail: View {
    let trail: Trail
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var plannedDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var note = ""
    @State private var showSaveSuccess = false
    @State private var isShowingGearChecklist = false
    @StateObject private var weatherAlertManager = WeatherAlertManager()
    @State private var isCheckingWeather = false
    @State private var weatherCheckResult: (isSafe: Bool, message: String)?

    var body: some View {
        Form {
            // Trail preview section (read-only since trail is pre-selected)
            Section(languageManager.localizedString(for: "planner.preview")) {
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
            }
            
            // Date and note section
            Section(languageManager.localizedString(for: "planner.schedule")) {
                HStack {
                    Text(languageManager.localizedString(for: "planner.date"))
                    Spacer()
                    Text(formattedDate(plannedDate))
                        .foregroundStyle(.secondary)
                }
                DatePicker("", selection: $plannedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
                TextField(languageManager.localizedString(for: "planner.note"), text: $note)
            }
            
            // Weather check section
            Section {
                Button {
                    Task {
                        await checkWeatherBeforeHike()
                    }
                } label: {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(Color.hikingGreen)
                        Text(languageManager.localizedString(for: "weather.alert.pre.hike.check"))
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        if isCheckingWeather {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isCheckingWeather)
                
                if let result = weatherCheckResult {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: result.isSafe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(result.isSafe ? Color.green : Color.orange)
                        Text(result.message)
                            .font(.caption)
                            .foregroundStyle(result.isSafe ? Color.primary : Color.orange)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Gear checklist entry point
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
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
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
            ToolbarItem(placement: .cancellationAction) {
                Button(languageManager.localizedString(for: "cancel")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(languageManager.localizedString(for: "save")) {
                    guard let accountId = sessionManager.currentUser?.id else { return }
                    viewModel.addSavedHike(for: trail, scheduledDate: plannedDate, note: note, accountId: accountId)
                    showSaveSuccess = true
                }
            }
        }
        .alert(languageManager.localizedString(for: "planner.saved"), isPresented: $showSaveSuccess) {
            Button(languageManager.localizedString(for: "ok"), role: .cancel) {
                dismiss()
            }
        } message: {
            Text(languageManager.localizedString(for: "planner.saved.message"))
        }
        .sheet(isPresented: $isShowingGearChecklist) {
            GearChecklistView(
                trail: trail,
                weather: viewModel.weatherSnapshot,
                scheduledDate: plannedDate
            )
        }
    }
    
    /// Format date in localized format
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Checks weather before the planned hike
    private func checkWeatherBeforeHike() async {
        isCheckingWeather = true
        let language = languageManager.currentLanguage.rawValue
        let result = await weatherAlertManager.checkWeatherBeforeHike(
            scheduledDate: plannedDate,
            language: language
        )
        weatherCheckResult = result
        isCheckingWeather = false
    }
}

#Preview {
    PlannerView()
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
        .modelContainer(for: [SavedHikeRecord.self, GearItem.self], inMemory: true)
}

