import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.modelContext) private var modelContext
    @State private var showSignOutConfirmation = false
    @StateObject private var servicesStatus = ServicesStatusViewModel()

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
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                servicesStatus.refreshAllStatuses(
                    weatherError: viewModel.weatherError,
                    hasWeatherData: viewModel.weatherSnapshot.updatedAt > Date().addingTimeInterval(-3600),
                    context: modelContext
                )
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
        VStack {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func goalRow(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(goal.title, systemImage: goal.icon)
                    .font(.subheadline.weight(.medium))
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.isCompleted ? Color.green : Color.accentColor)
                        .frame(width: geometry.size.width * goal.progress, height: 6)
                        .animation(.spring(response: 0.3), value: goal.progress)
                }
            }
            .frame(height: 6)
            
            Text(goal.progressText)
                .font(.caption)
                .foregroundStyle(goal.isCompleted ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func serviceStatusRow(title: String, icon: String, status: ServicesStatusViewModel.ServiceStatus) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .foregroundStyle(statusColor(for: status))
                    .font(.caption)
                Text(statusText(for: status))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func statusColor(for status: ServicesStatusViewModel.ServiceStatus) -> Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .red
        case .unavailable: return .orange
        case .unknown: return .gray
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


