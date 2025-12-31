//
//  ProfileView.swift
//  hikingHK
//
//  Profile screen showing account info, hiking stats, goals,
//  achievements and the health/status of core services & APIs.
//

import SwiftUI

/// Main profile / settings screen for the user.
struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showSignOutConfirmation = false
    @State private var isShowingAchievements = false
    @StateObject private var servicesStatus = ServicesStatusViewModel()
    @StateObject private var apiChecker = APIConnectionChecker()
    @StateObject private var achievementViewModel = AchievementViewModel()
    @EnvironmentObject private var languageManager: LanguageManager

    /// Number of planned hikes that are not yet completed.
    private var plannedCount: Int {
        viewModel.savedHikes.filter { !$0.isCompleted }.count
    }

    /// Number of trails marked as favorites.
    private var favoritesCount: Int {
        viewModel.trails.filter { $0.isFavorite }.count
    }

    /// Total distance of all completed saved hikes.
    private var loggedDistance: Double {
        viewModel.savedHikes
            .filter { $0.isCompleted }
            .map(\.trail.lengthKm)
            .reduce(0, +)
    }
    
    // MARK: - Goal tracking helpers
    private var completedRidgeLines: Int {
        viewModel.savedHikes
            .filter { $0.isCompleted && $0.trail.difficulty == .challenging }
            .count
    }
    
    private var monthlyDistance: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        return viewModel.savedHikes
            .filter { hike in
                guard let completedAt = hike.completedAt else { return false }
                return hike.isCompleted && completedAt >= startOfMonth
            }
            .map(\.trail.lengthKm)
            .reduce(0, +)
    }
    
    private var ridgeLinesGoal: Goal {
        var goal = Goal.ridgeLines
        goal.current = Double(completedRidgeLines)
        return goal
    }
    
    private var monthlyDistanceGoal: Goal {
        var goal = Goal.monthlyDistance
        goal.current = monthlyDistance
        return goal
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                statsSection
                Section {
                    NavigationLink {
                        AchievementView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(Color.hikingGreen)
                                .frame(width: 32, height: 32)
                            Text(languageManager.localizedString(for: "profile.achievements.badges"))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.hikingDarkGreen)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("\(achievementViewModel.unlockedCount)")
                                    .font(.headline)
                                    .foregroundStyle(Color.hikingGreen)
                                Text("/")
                                    .foregroundStyle(Color.hikingStone)
                                Text("\(achievementViewModel.totalCount)")
                                    .foregroundStyle(Color.hikingStone)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(languageManager.localizedString(for: "profile.achievements"))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Section {
                    goalRow(goal: ridgeLinesGoal)
                    goalRow(goal: monthlyDistanceGoal)
                } header: {
                    Text(languageManager.localizedString(for: "profile.goals"))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Section {
                    apiStatusRow(
                        title: languageManager.localizedString(for: "service.weather.api"),
                        icon: "cloud.sun",
                        status: apiChecker.weatherAPIStatus
                    )
                    serviceStatusRow(
                        title: languageManager.localizedString(for: "service.gps.tracking"),
                        icon: "location",
                        status: servicesStatus.gpsStatus
                    )
                    serviceStatusRow(
                        title: languageManager.localizedString(for: "service.offline.maps"),
                        icon: "arrow.down.circle",
                        status: servicesStatus.offlineMapsStatus
                    )
                    apiStatusRow(
                        title: languageManager.localizedString(for: "service.mapbox.api"),
                        icon: "map",
                        status: apiChecker.mapboxAPIStatus
                    )
                    apiStatusRow(
                        title: languageManager.localizedString(for: "service.mtr.api"),
                        icon: "tram.fill",
                        status: apiChecker.mtrAPIStatus
                    )
                    apiStatusRow(
                        title: languageManager.localizedString(for: "service.bus.api"),
                        icon: "bus.fill",
                        status: apiChecker.busAPIStatus
                    )
                } header: {
                    Text(languageManager.localizedString(for: "profile.data.services"))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Section {
                    HStack {
                        Label(languageManager.localizedString(for: "profile.trails.total"), systemImage: "map.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        Text("\(viewModel.trails.count)")
                            .font(.headline)
                            .foregroundStyle(Color.hikingGreen)
                    }
                } header: {
                    Text(languageManager.localizedString(for: "profile.trails.data"))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Section {
                    languageSelectionRow
                } header: {
                    Text(languageManager.localizedString(for: "profile.language"))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Section {
                    HStack {
                        Text(languageManager.localizedString(for: "api.status.last.checked"))
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                        Spacer()
                        if let lastCheck = apiChecker.lastCheckTime {
                            Text(lastCheck, style: .relative)
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        } else {
                            Text(languageManager.localizedString(for: "api.status.never"))
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        }
                    }
                    Button {
                        Task {
                            await apiChecker.checkAllAPIs()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(languageManager.localizedString(for: "api.status.check.connection"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.hikingGreen)
                } header: {
                    Text(languageManager.localizedString(for: "api.status.title"))
                        .foregroundStyle(Color.hikingDarkGreen)
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
            .navigationTitle(languageManager.localizedString(for: "profile.title"))
            .onAppear {
                // Refresh service statuses based on current weather data and context
                servicesStatus.refreshAllStatuses(
                    weatherError: viewModel.weatherError,
                    hasWeatherData: viewModel.weatherSnapshot.updatedAt > Date().addingTimeInterval(-3600),
                    context: modelContext,
                    accountId: sessionManager.currentUser?.id
                )
                if let accountId = sessionManager.currentUser?.id {
                    achievementViewModel.configureIfNeeded(context: modelContext, accountId: accountId)
                }
                
                // Update achievements based on the latest hike records
                Task {
                    await apiChecker.checkAllAPIs()
                    updateAchievements()
                }
            }
            .onChange(of: viewModel.savedHikes) { _, _ in
                updateAchievements()
            }
            .onChange(of: viewModel.weatherError) { _ in
                servicesStatus.checkWeatherServiceStatus(
                    weatherError: viewModel.weatherError,
                    hasWeatherData: viewModel.weatherSnapshot.updatedAt > Date().addingTimeInterval(-3600)
                )
            }
            .confirmationDialog(languageManager.localizedString(for: "profile.sign.out"), isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button(languageManager.localizedString(for: "profile.sign.out"), role: .destructive) {
                    sessionManager.signOut()
                }
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) {}
            } message: {
                Text(languageManager.localizedString(for: "profile.sign.out.confirm"))
            }
        }
    }
    
    /// Refreshes achievements using persisted hike records.
    private func updateAchievements() {
        // Update achievements from hike records
        guard let accountId = sessionManager.currentUser?.id else { return }
        Task {
            do {
                let recordStore = HikeRecordStore(context: modelContext)
                let hikeRecords = try recordStore.loadAllRecords(accountId: accountId)
                achievementViewModel.refreshAchievements(from: hikeRecords)
            } catch {
                // If there are no HikeRecord entries, we could derive progress from savedHikes.
                // For now we silently ignore errors to avoid blocking the profile screen.
            }
        }
    }

    /// Account information and sign-out controls.
    private var accountSection: some View {
        Section {
            if let user = sessionManager.currentUser {
                HStack(spacing: 16) {
                    Image(systemName: user.avatarSymbol)
                        .font(.title3)
                        .foregroundStyle(Color.hikingGreen)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.hikingCardGradient)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                            .foregroundStyle(Color.hikingDarkGreen)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingStone)
                    }
                }
                .padding(.vertical, 4)
            }
            Button(languageManager.localizedString(for: "profile.sign.out"), role: .destructive) {
                showSignOutConfirmation = true
            }
        } header: {
            Text(languageManager.localizedString(for: "profile.account"))
                .foregroundStyle(Color.hikingDarkGreen)
        }
    }

    /// High-level stats for planned hikes, favorites, and logged distance.
    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                stat(value: "\(plannedCount)", label: languageManager.localizedString(for: "stats.planned"))
                stat(value: "\(favoritesCount)", label: languageManager.localizedString(for: "stats.favorites"))
                stat(value: "\(loggedDistance.formatted(.number.precision(.fractionLength(1)))) km", label: languageManager.localizedString(for: "stats.logged"))
            }
        } header: {
            Text(languageManager.localizedString(for: "profile.stats"))
                .foregroundStyle(Color.hikingDarkGreen)
        }
    }

    /// Single stat pill used inside the stats section.
    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.hikingGreen)
            Text(label.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.hikingDarkGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.hikingCardGradient)
                .shadow(color: Color.hikingGreen.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    /// Renders a single goal row with a progress bar and value text.
    private func goalRow(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .foregroundStyle(Color.hikingGreen)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.localizedTitle(languageManager: languageManager))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.hikingDarkGreen)
                    
                    // Progress bar for the specific goal
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.hikingStone.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: goal.isCompleted ? 
                                            [Color.hikingGreen, Color.hikingDarkGreen] :
                                            [Color.hikingGreen.opacity(0.7), Color.hikingGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * goal.progress, height: 8)
                                .animation(.spring(response: 0.3), value: goal.progress)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(goal.progressText(languageManager: languageManager))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(goal.isCompleted ? Color.hikingGreen : Color.hikingStone)
                }
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.hikingGreen)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.hikingCardGradient)
                .shadow(color: Color.hikingGreen.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
    
    /// Row displaying the status of an internal service (GPS, offline maps, etc.).
    private func serviceStatusRow(title: String, icon: String, status: ServicesStatusViewModel.ServiceStatus) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.hikingDarkGreen)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .foregroundStyle(statusColor(for: status))
                    .font(.caption)
                Text(statusText(for: status))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor(for: status))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor(for: status).opacity(0.1))
            )
        }
    }
    
    /// Row displaying the status of an external API connection.
    private func apiStatusRow(title: String, icon: String, status: APIConnectionChecker.ConnectionStatus) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.hikingDarkGreen)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .foregroundStyle(getColorForAPIConnectionStatus(status))
                    .font(.caption)
                Text(status.localizedDescription(languageManager: languageManager))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(getColorForAPIConnectionStatus(status))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(getColorForAPIConnectionStatus(status).opacity(0.1))
            )
        }
    }
    
    /// Color helper for API connection status tags.
    private func getColorForAPIConnectionStatus(_ status: APIConnectionChecker.ConnectionStatus) -> Color {
        switch status {
        case .checking: return .orange
        case .connected: return Color.hikingGreen
        case .disconnected: return .red
        case .notConfigured: return Color.hikingStone
        case .error: return .red
        }
    }
    
    /// Color helper for internal service status tags.
    private func statusColor(for status: ServicesStatusViewModel.ServiceStatus) -> Color {
        switch status {
        case .connected: return Color.hikingGreen
        case .disconnected: return .red
        case .unavailable: return .orange
        case .unknown: return Color.hikingStone
        }
    }
    
    /// Localized text helper for internal service status.
    private func statusText(for status: ServicesStatusViewModel.ServiceStatus) -> String {
        switch status {
        case .connected: return languageManager.localizedString(for: "service.status.connected")
        case .disconnected: return languageManager.localizedString(for: "service.status.disconnected")
        case .unavailable: return languageManager.localizedString(for: "service.status.unavailable")
        case .unknown: return languageManager.localizedString(for: "service.status.unknown")
        }
    }
    
    /// Language selection row allowing the user to switch app language.
    private var languageSelectionRow: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundStyle(Color.hikingGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.localizedString(for: "profile.language"))
                    .foregroundStyle(Color.hikingDarkGreen)
                Text(languageManager.localizedString(for: "profile.language.description"))
                    .font(.caption)
                    .foregroundStyle(Color.hikingStone)
            }
            Spacer()
            Picker("", selection: $languageManager.currentLanguage) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    HStack {
                        Text(language.flag)
                        Text(language.displayName)
                    }
                    .tag(language)
                }
            }
            .pickerStyle(.menu)
        }
    }

}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
        .environmentObject(SessionManager.previewSignedIn())
        .environmentObject(LanguageManager.shared)
}
