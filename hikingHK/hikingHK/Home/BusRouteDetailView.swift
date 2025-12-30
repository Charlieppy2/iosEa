//
//  BusRouteDetailView.swift
//  hikingHK
//
//  Created on 30/12/2025.
//

import SwiftUI

/// Detail view showing all stops and real-time ETAs for a bus route
struct BusRouteDetailView: View {
    let route: KMBRoute
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var routeStops: [KMBStop] = []
    @State private var busETAs: [KMBETA] = []
    @State private var isLoading = false
    @State private var error: String?
    
    private let kmbService = KMBService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Route header with improved design
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        // Route number badge
                        Text(route.route)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Direction indicator with destination - more prominent
                            HStack(spacing: 8) {
                                Image(systemName: route.bound == "O" ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(route.bound == "O" ? languageManager.localizedString(for: "transport.bus.outbound") : languageManager.localizedString(for: "transport.bus.inbound"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(route.bound == "O" ? route.localizedDestination(languageManager: languageManager) : route.localizedOrigin(languageManager: languageManager))
                                        .font(.headline)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            
                            // Origin and destination with labels
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(languageManager.localizedString(for: "trail.start.point"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(route.localizedOrigin(languageManager: languageManager))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "flag.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(languageManager.localizedString(for: "trail.end.point"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(route.localizedDestination(languageManager: languageManager))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                } else if !routeStops.isEmpty {
                    // Show stops with ETA in scrollable single page
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.localizedString(for: "transport.bus.real.time.eta"))
                            .font(.headline.bold())
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                        
                        // Scrollable list of all stops
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(routeStops) { stop in
                                    stopETACard(stop: stop)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(route.route)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRouteStopsAndETA()
        }
    }
    
    private func loadRouteStopsAndETA() {
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🌐 Fetching route stops...")
                let stops = try await kmbService.fetchRouteStops(
                    route: route.route,
                    direction: route.bound,
                    serviceType: route.service_type
                )
                await MainActor.run {
                    self.routeStops = stops
                    print("✅ Loaded \(self.routeStops.count) stops for route \(route.route)")
                }
                
                // Load ETA for first 10 stops initially, then load more as needed
                if !stops.isEmpty {
                    let initialStopsToLoad = Array(stops.prefix(10))
                    await loadETAsForStopsParallel(stops: initialStopsToLoad)
                    
                    // Load remaining stops in background
                    if stops.count > 10 {
                        let remainingStops = Array(stops.dropFirst(10))
                        Task {
                            await loadETAsForStopsParallel(stops: remainingStops)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading route stops: \(error.localizedDescription)")
                    self.error = languageManager.localizedString(for: "transport.bus.error.load.failed")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadETAsForStopsParallel(stops: [KMBStop]) async {
        print("🚀 Loading ETAs for \(stops.count) stops in parallel...")
        let startTime = Date()
        
        await withTaskGroup(of: (stopId: String, etas: [KMBETA]?).self) { group in
            for stop in stops {
                group.addTask {
                    do {
                        let etas = try await kmbService.fetchETA(
                            stopId: stop.stop,
                            route: route.route,
                            serviceType: route.service_type
                        )
                        return (stopId: stop.stop, etas: etas)
                    } catch {
                        print("⚠️ Failed to load ETA for stop \(stop.stop): \(error.localizedDescription)")
                        return (stopId: stop.stop, etas: nil)
                    }
                }
            }
            
            var allETAs: [KMBETA] = []
            for await result in group {
                if let etas = result.etas {
                    allETAs.append(contentsOf: etas)
                }
            }
            
            let loadTime = Date().timeIntervalSince(startTime)
            await MainActor.run {
                self.busETAs.append(contentsOf: allETAs)
                self.isLoading = false
                print("✅ Loaded \(allETAs.count) ETAs for route \(route.route) in \(String(format: "%.2f", loadTime))s")
            }
        }
    }
    
    private func stopETACard(stop: KMBStop) -> some View {
        // Filter ETAs by stop ID
        let stopETAs = busETAs.filter { eta in
            if let etaStop = eta.stop {
                return etaStop == stop.stop
            }
            return false
        }
        let isLoading = routeStops.contains(where: { $0.id == stop.id }) && stopETAs.isEmpty && !isLoading
        
        return VStack(alignment: .leading, spacing: 12) {
            // Stop name with icon - more prominent
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.localizedName(languageManager: languageManager))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let stopCode = stop.stop.split(separator: "(").last?.replacingOccurrences(of: ")", with: ""), !stopCode.isEmpty {
                        Text("(\(stopCode))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !stopETAs.isEmpty {
                // Group ETAs by destination for clearer display
                let groupedETAs = Dictionary(grouping: stopETAs.prefix(2)) { eta in
                    eta.localizedDestination(languageManager: languageManager)
                }
                
                ForEach(Array(groupedETAs.keys.sorted()), id: \.self) { destination in
                    if let etas = groupedETAs[destination] {
                        VStack(alignment: .leading, spacing: 8) {
                            // Destination with clear label
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(languageManager.localizedString(for: "trail.end.point"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(destination)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                }
                            }
                            
                            // ETA times with label
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageManager.localizedString(for: "transport.bus.eta"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    ForEach(etas.prefix(2)) { eta in
                                        ETABadge(time: eta.formattedETA)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
            } else if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(languageManager.localizedString(for: "transport.bus.loading.eta"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(languageManager.localizedString(for: "transport.bus.no.eta.found"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func ETABadge(time: String) -> some View {
        Text(time)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        time.contains("已過") ? Color.gray :
                        time.contains("即將到站") ? Color.green :
                        Color.orange
                    )
            )
    }
}

