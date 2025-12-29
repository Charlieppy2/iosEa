//
//  TrailMapView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import MapKit
import SwiftData
import Network
import Combine

/// Simple network status monitor used to detect online/offline status.
class NetworkStatusMonitor: ObservableObject {
    @Published var status: NWPath.Status = .satisfied
    private var monitor: NWPathMonitor?
    
    func startMonitoring() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        self.monitor = monitor
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}

/// Interactive map view for a single trail, showing route, user location,
/// and whether an offline map is available or currently in use.
struct TrailMapView: View {
    let trail: Trail
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkStatusMonitor()
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.modelContext) private var modelContext
    @State private var position: MapCameraPosition
    @State private var dynamicPolyline: MKPolyline?
    @State private var offlineMapRegion: OfflineMapRegion?
    @State private var isOfflineMode: Bool = false
    @State private var hasOfflineMap: Bool = false
    
    private let routeService = MapboxRouteService()
    private let offlineMapLoader = OfflineMapLoader()

    init(trail: Trail) {
        self.trail = trail
        _position = State(initialValue: .region(trail.mapRegion))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageManager.localizedString(for: "map.interactive"))
                    .font(.headline)
                Spacer()
                // Offline map status indicator
                if hasOfflineMap {
                    HStack(spacing: 4) {
                        Image(systemName: isOfflineMode ? "wifi.slash" : "map.fill")
                            .font(.caption)
                            .foregroundStyle(isOfflineMode ? .orange : .green)
                        Text(isOfflineMode ? languageManager.localizedString(for: "map.offline.mode") : languageManager.localizedString(for: "map.offline.available"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            ZStack(alignment: .topTrailing) {
                Map(position: $position, interactionModes: .all) {
                    if let polyline = trail.mkPolyline {
                        MapPolyline(polyline)
                            .stroke(.green, lineWidth: 4)
                    }
                    if let dynamicPolyline {
                        MapPolyline(dynamicPolyline)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
                    }
                    if let startCoordinate = trail.routeLocations.first {
                        Annotation(languageManager.localizedString(for: "map.start"), coordinate: startCoordinate) {
                            Image(systemName: "flag.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .shadow(radius: 3)
                        }
                    }
                    if let userCoordinate = locationManager.currentLocation?.coordinate {
                        Annotation(languageManager.localizedString(for: "map.you"), coordinate: userCoordinate) {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.blue)
                                .shadow(radius: 3)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                // Offline mode banner when using downloaded maps without connectivity.
                if isOfflineMode && hasOfflineMap {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                            Text(languageManager.localizedString(for: "map.using.offline"))
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        
                        if let region = offlineMapRegion {
                            Text(region.name)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                }
            }
            .task {
                await checkOfflineMapAvailability()
                await loadDynamicRoute()
            }
            .onAppear {
                setupNetworkMonitoring()
            }
            .onDisappear {
                stopNetworkMonitoring()
            }
            .onChange(of: networkMonitor.status) { _, _ in
                updateOfflineModeStatus()
            }
            HStack {
                Label(localizedStartLocation, systemImage: "mappin.and.ellipse")
                Spacer()
                Button {
                    handleLocationAction()
                } label: {
                    Label(locationButtonTitle, systemImage: locationButtonIcon)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !routeService.isConfigured {
                Text(languageManager.localizedString(for: "map.mapbox.token.required"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    

    private var localizedStartLocation: String {
        let district = trail.localizedDistrict(languageManager: languageManager)
        let template = languageManager.localizedString(for: "map.start.location")
        return template.replacingOccurrences(of: "{district}", with: district)
    }
    
    private var locationButtonTitle: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return languageManager.localizedString(for: "map.center.on.me")
        case .denied, .restricted:
            return languageManager.localizedString(for: "map.location.disabled")
        default:
            return languageManager.localizedString(for: "map.enable.location")
        }
    }

    private var locationButtonIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "location.fill"
        case .denied, .restricted:
            return "exclamationmark.triangle"
        default:
            return "location"
        }
    }

    private func handleLocationAction() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .authorizedAlways, .authorizedWhenInUse:
            if let current = locationManager.currentLocation {
                position = .region(MKCoordinateRegion(center: current.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
            } else {
                locationManager.startUpdates()
            }
        default:
            // prompt user to enable in settings; here we simply log
            print("Location access denied or restricted.")
        }
    }

    private func loadDynamicRoute() async {
        // Skip dynamic Mapbox routing when running in offline mode.
        guard !isOfflineMode,
              dynamicPolyline == nil,
              routeService.isConfigured,
              let start = trail.routeLocations.first,
              let end = trail.routeLocations.last
        else { return }
        do {
            dynamicPolyline = try await routeService.fetchRoute(from: start, to: end)
        } catch {
            print("Mapbox route error: \(error)")
        }
    }
    
    // Check whether any downloaded offline map region covers this trail.
    private func checkOfflineMapAvailability() async {
        // Skip checks while running inside Xcode previews.
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        
        // Create the store (requires a ModelContext).
        let store = OfflineMapsStore(context: modelContext)
        
        // Load all offline map regions.
        guard let allRegions = try? store.loadAllRegions() else { return }
        
        // Check whether the trail's coordinates fall inside any downloaded region.
        for region in allRegions where region.downloadStatus == .downloaded {
            let regionBounds = region.coordinateRegion
            
            // Check whether the start or end of the trail lies inside this region.
            var isTrailInRegion = false
            if let start = trail.routeLocations.first,
               let end = trail.routeLocations.last {
                isTrailInRegion = regionBounds.contains(start) || regionBounds.contains(end)
                
                // Also check the trail's map center point.
                if !isTrailInRegion {
                    let trailCenter = trail.mapCenter
                    isTrailInRegion = regionBounds.contains(trailCenter)
                }
            }
            
            if isTrailInRegion {
                offlineMapRegion = region
                hasOfflineMap = true
                break
            }
        }
        
        // Update offline mode status after checking regions.
        updateOfflineModeStatus()
    }
    
    // Start listening for network status changes.
    private func setupNetworkMonitoring() {
        networkMonitor.startMonitoring()
    }
    
    // Stop listening for network status changes.
    private func stopNetworkMonitoring() {
        networkMonitor.stopMonitoring()
    }
    
    // Update offline mode state based on connectivity and offline map presence.
    private func updateOfflineModeStatus() {
        // Enable offline mode only when network is unavailable and offline maps exist.
        isOfflineMode = (networkMonitor.status != .satisfied) && hasOfflineMap
    }
}

#Preview {
    TrailMapView(trail: Trail.sampleData[0])
        .environmentObject(LanguageManager.shared)
        .modelContainer(for: [OfflineMapRegion.self], inMemory: true)
}

