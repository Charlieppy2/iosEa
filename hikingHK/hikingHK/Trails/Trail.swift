//
//  Trail.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import MapKit

struct Trail: Identifiable, Hashable {
    let id: UUID
    var name: String
    var district: String
    var difficulty: Difficulty
    var lengthKm: Double
    var elevationGain: Int
    var estimatedDurationMinutes: Int
    var summary: String
    var highlights: [String]
    var facilities: [Facility]
    var transportation: String
    var imageName: String
    var isFavorite: Bool
    var checkpoints: [Checkpoint]
    var mapCenter: CLLocationCoordinate2D
    var mapSpan: MKCoordinateSpan
    var routeCoordinates: [TrailCoordinate]

    init(
        id: UUID = UUID(),
        name: String,
        district: String,
        difficulty: Difficulty,
        lengthKm: Double,
        elevationGain: Int,
        estimatedDurationMinutes: Int,
        summary: String,
        highlights: [String],
        facilities: [Facility],
        transportation: String,
        imageName: String,
        isFavorite: Bool = false,
        checkpoints: [Checkpoint] = [],
        mapCenter: CLLocationCoordinate2D,
        mapSpan: MKCoordinateSpan = .init(latitudeDelta: 0.08, longitudeDelta: 0.08),
        routeCoordinates: [TrailCoordinate] = []
    ) {
        self.id = id
        self.name = name
        self.district = district
        self.difficulty = difficulty
        self.lengthKm = lengthKm
        self.elevationGain = elevationGain
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.summary = summary
        self.highlights = highlights
        self.facilities = facilities
        self.transportation = transportation
        self.imageName = imageName
        self.isFavorite = isFavorite
        self.checkpoints = checkpoints
        self.mapCenter = mapCenter
        self.mapSpan = mapSpan
        self.routeCoordinates = routeCoordinates
    }
}

extension Trail {
    static func == (lhs: Trail, rhs: Trail) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Trail {
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case moderate = "Moderate"
        case challenging = "Challenging"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .easy: return "leaf"
            case .moderate: return "figure.walk"
            case .challenging: return "mountain.2"
            }
        }

        var colorName: String {
            switch self {
            case .easy: return "green"
            case .moderate: return "orange"
            case .challenging: return "red"
            }
        }
    }

    struct Facility: Hashable {
        let name: String
        let systemImage: String
    }

    struct Checkpoint: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let subtitle: String
        let distanceKm: Double
        let altitude: Int
    }

    struct TrailCoordinate: Identifiable, Hashable {
        let id = UUID()
        let latitude: Double
        let longitude: Double

        var location: CLLocationCoordinate2D {
            .init(latitude: latitude, longitude: longitude)
        }
    }
}

extension Trail {
    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: mapCenter, span: mapSpan)
    }

    var routeLocations: [CLLocationCoordinate2D] {
        routeCoordinates.map(\.location)
    }

    var mkPolyline: MKPolyline? {
        guard !routeLocations.isEmpty else { return nil }
        return MKPolyline(coordinates: routeLocations, count: routeLocations.count)
    }
}

extension Trail {
    static let sampleData: [Trail] = [
        Trail(
            id: UUID(uuidString: "0C8C0A67-9B84-4D4E-8F1C-2B7B4E3EB7A0")!,
            name: "MacLehose Section 4",
            district: "Sai Kung",
            difficulty: .challenging,
            lengthKm: 12.7,
            elevationGain: 720,
            estimatedDurationMinutes: 320,
            summary: "Iconic ridge walk from Kei Ling Ha to Tate's Cairn with panoramic views of Port Shelter.",
            highlights: [
                "Sharp Peak vista",
                "Ma On Shan country park geology",
                "Golden hour sunrise spot"
            ],
            facilities: [
                .init(name: "Country park toilet", systemImage: "toilet"),
                .init(name: "Pavilion shelter", systemImage: "house")
            ],
            transportation: "Bus 99/99R to Kei Ling Ha; return via bus/minibus from Tate's Cairn tunnel portal.",
            imageName: "maclehose",
            checkpoints: [
                .init(title: "Kei Ling Ha", subtitle: "Trailhead", distanceKm: 0, altitude: 5),
                .init(title: "Kai Kung Shan", subtitle: "Viewpoint", distanceKm: 5.1, altitude: 399),
                .init(title: "Tate's Cairn", subtitle: "Finish", distanceKm: 12.7, altitude: 583)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.383, longitude: 114.263),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15),
            routeCoordinates: [
                .init(latitude: 22.3829, longitude: 114.2816),
                .init(latitude: 22.3810, longitude: 114.2723),
                .init(latitude: 22.3798, longitude: 114.2635),
                .init(latitude: 22.3882, longitude: 114.2488),
                .init(latitude: 22.3889, longitude: 114.2366)
            ]
        ),
        Trail(
            id: UUID(uuidString: "7D62F08B-24AF-4DA4-95BB-818E0C1CD2B5")!,
            name: "Dragon's Back",
            district: "Hong Kong Island",
            difficulty: .moderate,
            lengthKm: 8.5,
            elevationGain: 310,
            estimatedDurationMinutes: 150,
            summary: "Most beloved half-day hike featuring coastal scenery overlooking Shek O, Big Wave Bay, and Tai Tam Bay.",
            highlights: [
                "Shek O Peninsula lookout",
                "Paragliding take-off site",
                "Surfing beach finale"
            ],
            facilities: [
                .init(name: "Big Wave Bay showers", systemImage: "shower.handheld"),
                .init(name: "Water kiosks", systemImage: "drop.triangle")
            ],
            transportation: "MTR Shau Kei Wan → Bus 9 to To Tei Wan; depart via bus/minibus from Big Wave Bay.",
            imageName: "dragonsback",
            checkpoints: [
                .init(title: "To Tei Wan", subtitle: "Trailhead", distanceKm: 0, altitude: 105),
                .init(title: "Dragon's Back Ridge", subtitle: "Photo spot", distanceKm: 2.6, altitude: 284),
                .init(title: "Big Wave Bay", subtitle: "Finish", distanceKm: 8.5, altitude: 15)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.2477, longitude: 114.2401),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08),
            routeCoordinates: [
                .init(latitude: 22.2469, longitude: 114.2423),
                .init(latitude: 22.2442, longitude: 114.2390),
                .init(latitude: 22.2424, longitude: 114.2366),
                .init(latitude: 22.2402, longitude: 114.2361),
                .init(latitude: 22.2380, longitude: 114.2351)
            ]
        ),
        Trail(
            id: UUID(uuidString: "B0F98FDF-2F2F-4C19-A032-654B2C73E0B7")!,
            name: "Tai Mo Shan Waterfalls",
            district: "Tsuen Wan",
            difficulty: .easy,
            lengthKm: 5.5,
            elevationGain: 190,
            estimatedDurationMinutes: 120,
            summary: "Family friendly nature trail showcasing four major cascades from the Ng Tung Chai waterfall series.",
            highlights: [
                "Main Fall 35 m drop",
                "Shaded bamboo forest",
                "Stream play area"
            ],
            facilities: [
                .init(name: "Village stores", systemImage: "cart"),
                .init(name: "Taxi stand", systemImage: "car")
            ],
            transportation: "Bus 64K/64P to Ng Tung Chai village; return identical route.",
            imageName: "taimoshan",
            checkpoints: [
                .init(title: "Ng Tung Chai", subtitle: "Trailhead", distanceKm: 0, altitude: 80),
                .init(title: "Bottom Fall", subtitle: "Photo stop", distanceKm: 1.3, altitude: 160),
                .init(title: "Main Fall", subtitle: "Halfway point", distanceKm: 2.8, altitude: 340)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.4205, longitude: 114.1234),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06),
            routeCoordinates: [
                .init(latitude: 22.4168, longitude: 114.1198),
                .init(latitude: 22.4181, longitude: 114.1214),
                .init(latitude: 22.4196, longitude: 114.1236),
                .init(latitude: 22.4211, longitude: 114.1259),
                .init(latitude: 22.4228, longitude: 114.1274)
            ]
        )
    ]
}

