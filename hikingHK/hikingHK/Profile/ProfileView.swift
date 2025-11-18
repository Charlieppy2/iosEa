import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showSignOutConfirmation = false
    @State private var isShowingAchievements = false
    @StateObject private var servicesStatus = ServicesStatusViewModel()
    @StateObject private var apiChecker = APIConnectionChecker()
    @StateObject private var achievementViewModel = AchievementViewModel()

    private var plannedCount: Int {
        viewModel.savedHikes.filter { !$0.isCompleted }.count
    }

    private var favoritesCount: Int {
        viewModel.trails.filter { $0.isFavorite }.count
    }

    private var loggedDistance: Double {
        viewModel.savedHikes
            .filter { $0.isCompleted }
            .map(\.trail.lengthKm)
            .reduce(0, +)
    }
    
    // Goals tracking
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
                Section("Achievements") {
                    NavigationLink {
                        AchievementView()
                    } label: {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.hikingGreen)
                            Text("Achievements & Badges")
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
                        }
                    }
                }
                Section("Goals") {
                    goalRow(goal: ridgeLinesGoal)
                    goalRow(goal: monthlyDistanceGoal)
                }
                Section("Data & services") {
                    serviceStatusRow(
                        title: "HK Weather API",
                        icon: "cloud.sun",
                        status: servicesStatus.weatherServiceStatus
                    )
                    serviceStatusRow(
                        title: "GPS tracking",
                        icon: "location",
                        status: servicesStatus.gpsStatus
                    )
                    serviceStatusRow(
                        title: "Offline maps",
                        icon: "arrow.down.circle",
                        status: servicesStatus.offlineMapsStatus
                    )
                    apiStatusRow(
                        title: "Mapbox API",
                        icon: "map",
                        status: apiChecker.mapboxAPIStatus
                    )
                }
                Section("API Status") {
                    HStack {
                        Text("Last checked")
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                        Spacer()
                        if let lastCheck = apiChecker.lastCheckTime {
                            Text(lastCheck, style: .relative)
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        } else {
                            Text("Never")
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
                            Text("Check API Connection")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.hikingGreen)
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
            .navigationTitle("Profile")
            .onAppear {
                servicesStatus.refreshAllStatuses(
                    weatherError: viewModel.weatherError,
                    hasWeatherData: viewModel.weatherSnapshot.updatedAt > Date().addingTimeInterval(-3600),
                    context: modelContext
                )
                achievementViewModel.configureIfNeeded(context: modelContext)
                
                // Update achievements from hike records
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
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    sessionManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func updateAchievements() {
        // Update achievements from hike records
        Task {
            do {
                let recordStore = HikeRecordStore(context: modelContext)
                let hikeRecords = try recordStore.loadAllRecords()
                achievementViewModel.refreshAchievements(from: hikeRecords)
            } catch {
                // 如果沒有 HikeRecord，可以從 savedHikes 轉換
                // 這裡暫時忽略錯誤
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if let user = sessionManager.currentUser {
                HStack(spacing: 16) {
                    Image(systemName: user.avatarSymbol)
                        .font(.title3)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Sign out", role: .destructive) {
                showSignOutConfirmation = true
            }
        }
    }

    private var statsSection: some View {
        Section("Journey") {
            HStack {
                stat(value: "\(plannedCount)", label: "planned")
                stat(value: "\(favoritesCount)", label: "favorites")
                stat(value: "\(loggedDistance.formatted(.number.precision(.fractionLength(1)))) km", label: "logged")
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(label.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.hikingBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hikingTan.opacity(0.2))
        )
    }
    
    private func goalRow(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(goal.title, systemImage: goal.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.hikingGreen)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.hikingTan.opacity(0.3))
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
            
            Text(goal.progressText)
                .font(.caption.weight(.medium))
                .foregroundStyle(goal.isCompleted ? Color.hikingGreen : Color.hikingBrown)
        }
        .padding(.vertical, 6)
    }
    
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
                Text(status.description)
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
    
    private func getColorForAPIConnectionStatus(_ status: APIConnectionChecker.ConnectionStatus) -> Color {
        switch status {
        case .checking: return .orange
        case .connected: return Color.hikingGreen
        case .disconnected: return .red
        case .notConfigured: return Color.hikingStone
        case .error: return .red
        }
    }
    
    private func statusColor(for status: ServicesStatusViewModel.ServiceStatus) -> Color {
        switch status {
        case .connected: return Color.hikingGreen
        case .disconnected: return .red
        case .unavailable: return .orange
        case .unknown: return Color.hikingStone
        }
    }
    
    private func statusText(for status: ServicesStatusViewModel.ServiceStatus) -> String {
        switch status {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .unavailable: return "Unavailable"
        case .unknown: return "Unknown"
        }
    }

}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
        .environmentObject(SessionManager.previewSignedIn())
}
//
//  ProfileView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//


