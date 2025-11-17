//
//  TrailMapView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import MapKit

struct TrailMapView: View {
    let trail: Trail
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition
    @State private var dynamicPolyline: MKPolyline?
    private let routeService = MapboxRouteService()

    init(trail: Trail) {
        self.trail = trail
        _position = State(initialValue: .region(trail.mapRegion))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interactive map")
                .font(.headline)
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
                    Annotation("Start", coordinate: startCoordinate) {
                        Image(systemName: "flag.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .shadow(radius: 3)
                    }
                }
                if let userCoordinate = locationManager.currentLocation?.coordinate {
                    Annotation("You", coordinate: userCoordinate) {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.blue)
                            .shadow(radius: 3)
                    }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .task {
                await loadDynamicRoute()
            }
            HStack {
                Label("Start \(trail.district)", systemImage: "mappin.and.ellipse")
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
                Text("Set MAPBOX_ACCESS_TOKEN to view live routing overlays.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var locationButtonTitle: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Center on me"
        case .denied, .restricted:
            return "Location disabled"
        default:
            return "Enable location"
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
        guard dynamicPolyline == nil,
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
}

#Preview {
    TrailMapView(trail: Trail.sampleData[0])
}

