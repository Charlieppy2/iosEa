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

struct TrailMapView: View {
    let trail: Trail
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.modelContext) private var modelContext
    @State private var position: MapCameraPosition
    @State private var dynamicPolyline: MKPolyline?
    @State private var offlineMapRegion: OfflineMapRegion?
    @State private var isOfflineMode: Bool = false
    @State private var hasOfflineMap: Bool = false
    @State private var networkMonitor: NWPathMonitor?
    @State private var networkStatus: NWPath.Status = .satisfied
    
    private let routeService = MapboxRouteService()
    private let offlineMapLoader = OfflineMapLoader()
    private var offlineMapsStore: OfflineMapsStore?

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
                // 离线地图状态指示器
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
                
                // 离线模式提示
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
        // 离线模式下不加载动态路线
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
    
    // 检查离线地图可用性
    private func checkOfflineMapAvailability() async {
        // 初始化 store
        if offlineMapsStore == nil {
            offlineMapsStore = OfflineMapsStore(context: modelContext)
        }
        
        guard let store = offlineMapsStore else { return }
        
        // 加载所有离线地图区域
        guard let allRegions = try? store.loadAllRegions() else { return }
        
        // 检查路线坐标是否在任何已下载的区域内
        for region in allRegions where region.downloadStatus == .downloaded {
            let regionBounds = region.coordinateRegion
            
            // 检查路线的起点和终点是否在区域内
            var isTrailInRegion = false
            if let start = trail.routeLocations.first,
               let end = trail.routeLocations.last {
                isTrailInRegion = regionBounds.contains(start) || regionBounds.contains(end)
                
                // 也检查路线中心点
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
        
        // 更新离线模式状态
        updateOfflineModeStatus()
    }
    
    // 设置网络监控
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [self] path in
            DispatchQueue.main.async {
                networkStatus = path.status
                updateOfflineModeStatus()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        networkMonitor = monitor
    }
    
    // 停止网络监控
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    // 更新离线模式状态
    private func updateOfflineModeStatus() {
        // 如果网络不可用且有离线地图，启用离线模式
        isOfflineMode = (networkStatus != .satisfied) && hasOfflineMap
    }
}

#Preview {
    TrailMapView(trail: Trail.sampleData[0])
}

