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
                        // Route number badge - fixed width for 5 characters (digits/letters)
                        Text(route.route)
                            .font(.system(size: 24, weight: .bold)) // Reduced font size to ensure 5 characters fit
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7) // Allow text to scale down if needed
                            .frame(width: 70, height: 60, alignment: .center) // Fixed width for 5 characters
                            .background(
                                Color.hikingGradient,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .shadow(color: Color.hikingGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Direction indicator with destination - same line as route number
                            HStack(spacing: 8) {
                                Image(systemName: route.bound == "O" ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                    .font(.title3)
                                Text(route.bound == "O" ? 
                                     "\(languageManager.localizedString(for: "transport.bus.outbound")) \(route.localizedDestination(languageManager: languageManager))" :
                                     "\(languageManager.localizedString(for: "transport.bus.inbound")) \(route.localizedOrigin(languageManager: languageManager))")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color.hikingDarkGreen)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: false)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Origin and destination with labels
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(Color.hikingGreen)
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
                                        .foregroundStyle(Color.hikingBrown)
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
                .hikingCard()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.hikingBrown)
                        .padding()
                } else if !routeStops.isEmpty {
                    // Show stops with ETA in scrollable single page
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.localizedString(for: "transport.bus.real.time.eta"))
                            .font(.headline.bold())
                            .foregroundStyle(Color.hikingDarkGreen)
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
        .hikingBackground()
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
                
                // Load ETA for first 10 stops initially for faster display, then load more
                if !stops.isEmpty {
                    let initialStopsToLoad = Array(stops.prefix(10))
                    await loadETAsForStopsParallel(stops: initialStopsToLoad)
                    
                    // Load remaining stops in background immediately (don't wait)
                    if stops.count > 10 {
                        let remainingStops = Array(stops.dropFirst(10))
                        Task.detached(priority: .userInitiated) {
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
                group.addTask(priority: .userInitiated) {
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
            var processedCount = 0
            // Process results as they come in for faster UI updates
            for await result in group {
                if let etas = result.etas {
                    allETAs.append(contentsOf: etas)
                    processedCount += 1
                    // Update UI incrementally for better perceived performance - increased to 10
                    if processedCount <= 10 {
                        await MainActor.run {
                            self.busETAs.append(contentsOf: etas)
                        }
                    }
                }
            }
            
            let loadTime = Date().timeIntervalSince(startTime)
            await MainActor.run {
                // Only append remaining ETAs if we didn't already add them incrementally
                if processedCount > 5 {
                    let newETAs = allETAs.filter { eta in
                        !self.busETAs.contains { $0.id == eta.id }
                    }
                    self.busETAs.append(contentsOf: newETAs)
                }
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
        
        return VStack(alignment: .leading, spacing: 0) {
            // Stop name header with icon - compact
            HStack(spacing: 10) {
                // Station icon badge - smaller
                ZStack {
                    Circle()
                        .fill(Color.hikingGradient)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.hikingGreen.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.white)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.localizedName(languageManager: languageManager))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let stopCode = stop.stop.split(separator: "(").last?.replacingOccurrences(of: ")", with: ""), !stopCode.isEmpty {
                        Text("(\(stopCode))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Color.hikingCardGradient
            )
            
            if !stopETAs.isEmpty {
                // Group ETAs by destination
                let groupedETAs = Dictionary(grouping: stopETAs.prefix(2)) { eta in
                    eta.localizedDestination(languageManager: languageManager)
                }
                
                ForEach(Array(groupedETAs.keys.sorted()), id: \.self) { destination in
                    if let etas = groupedETAs[destination] {
                        VStack(alignment: .leading, spacing: 8) {
                            // Destination header - compact
                            HStack(spacing: 6) {
                                Image(systemName: "flag.circle.fill")
                                    .foregroundStyle(Color.hikingBrown)
                                    .font(.subheadline)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(languageManager.localizedString(for: "trail.end.point"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(destination)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                            }
                            
                            // ETA times section - compact
                            HStack(spacing: 8) {
                                Text(languageManager.localizedString(for: "transport.bus.eta"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                // ETA badges in a row
                                ForEach(etas.prefix(2)) { eta in
                                    ETABadge(time: eta.formattedETA(languageManager: languageManager))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.hikingCardGradient)
                    }
                }
            } else if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(languageManager.localizedString(for: "transport.bus.loading.eta"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.hikingCardGradient)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.hikingBrown)
                        .font(.subheadline)
                    Text(languageManager.localizedString(for: "transport.bus.no.eta.found"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.hikingCardGradient)
            }
        }
        .hikingCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.hikingGreen.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func ETABadge(time: String) -> some View {
        let backgroundColor: Color
        let icon: String
        
        // Check for "Passed" status (both Chinese and English)
        if time.contains("已過") || time.contains("Passed") {
            backgroundColor = Color.gray.opacity(0.7) // Gray for passed buses
            icon = "clock.arrow.circlepath"
        } else if time.contains("即將到站") || time.contains("Arriving") {
            backgroundColor = Color.orange // Orange for arriving buses
            icon = "bolt.fill"
        } else {
            backgroundColor = Color.hikingGreen // Green for normal ETA times
            icon = "clock.fill"
        }
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(time)
                .font(.subheadline.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: backgroundColor.opacity(0.3), radius: 3, x: 0, y: 1)
        )
    }
}

