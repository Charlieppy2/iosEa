//
//  Trail.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import MapKit

/// Domain model representing a hiking trail with metadata, route and map information.
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
    enum Difficulty: String, CaseIterable, Identifiable, Codable {
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
    
    func localizedName(languageManager: LanguageManager) -> String {
        let key = "trail.\(id.uuidString.lowercased()).name"
        let localized = languageManager.localizedString(for: key)
        // If no localization found, return original name
        return localized != key ? localized : name
    }
    
    func localizedSummary(languageManager: LanguageManager) -> String {
        let key = "trail.\(id.uuidString.lowercased()).summary"
        let localized = languageManager.localizedString(for: key)
        // If no localization found, return original summary
        return localized != key ? localized : summary
    }
    
    func localizedDistrict(languageManager: LanguageManager) -> String {
        let key = "trail.district.\(district.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : district
    }
}

extension Trail.Difficulty {
    func localizedRawValue(languageManager: LanguageManager) -> String {
        let key = "trail.difficulty.\(rawValue.lowercased())"
        return languageManager.localizedString(for: key)
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
        ),
        // MacLehose Trail sections
        Trail(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            name: "MacLehose Section 1",
            district: "Sai Kung",
            difficulty: .easy,
            lengthKm: 10.6,
            elevationGain: 100,
            estimatedDurationMinutes: 180,
            summary: "Easy coastal walk from Pak Tam Chung to Long Ke Wan with reservoir views.",
            highlights: ["High Island Reservoir", "Long Ke Beach", "Coastal views"],
            facilities: [.init(name: "Toilet", systemImage: "toilet"), .init(name: "BBQ area", systemImage: "flame")],
            transportation: "Bus 94/96R to Pak Tam Chung",
            imageName: "maclehose1",
            checkpoints: [
                .init(title: "Pak Tam Chung", subtitle: "Start", distanceKm: 0, altitude: 10),
                .init(title: "Long Ke", subtitle: "Finish", distanceKm: 10.6, altitude: 5)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.350, longitude: 114.370),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F23456789012")!,
            name: "MacLehose Section 2",
            district: "Sai Kung",
            difficulty: .moderate,
            lengthKm: 13.5,
            elevationGain: 400,
            estimatedDurationMinutes: 240,
            summary: "Scenic route from Long Ke to Pak Tam Au via Sai Wan and Ham Tin.",
            highlights: ["Sai Wan Beach", "Ham Tin Beach", "Mountain views"],
            facilities: [.init(name: "Camping site", systemImage: "tent"), .init(name: "Village store", systemImage: "cart")],
            transportation: "Start from Section 1 end; Bus 94 from Pak Tam Au",
            imageName: "maclehose2",
            checkpoints: [
                .init(title: "Long Ke", subtitle: "Start", distanceKm: 0, altitude: 5),
                .init(title: "Sai Wan", subtitle: "Beach", distanceKm: 4.5, altitude: 50),
                .init(title: "Pak Tam Au", subtitle: "Finish", distanceKm: 13.5, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.380, longitude: 114.380),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        ),
        Trail(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-345678901234")!,
            name: "MacLehose Section 3",
            district: "Sai Kung",
            difficulty: .challenging,
            lengthKm: 10.2,
            elevationGain: 600,
            estimatedDurationMinutes: 300,
            summary: "Challenging climb from Pak Tam Au to Kei Ling Ha over Kai Kung Shan.",
            highlights: ["Kai Kung Shan", "Mountain ridge", "Panoramic views"],
            facilities: [.init(name: "Shelter", systemImage: "house")],
            transportation: "Bus 94 to Pak Tam Au; Bus 99 from Kei Ling Ha",
            imageName: "maclehose3",
            checkpoints: [
                .init(title: "Pak Tam Au", subtitle: "Start", distanceKm: 0, altitude: 200),
                .init(title: "Kai Kung Shan", subtitle: "Peak", distanceKm: 5.1, altitude: 399),
                .init(title: "Kei Ling Ha", subtitle: "Finish", distanceKm: 10.2, altitude: 5)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.383, longitude: 114.280),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEF0-456789012345")!,
            name: "MacLehose Section 5",
            district: "Sha Tin",
            difficulty: .moderate,
            lengthKm: 10.6,
            elevationGain: 450,
            estimatedDurationMinutes: 240,
            summary: "From Tate's Cairn to Tai Po Road via Lion Rock and Beacon Hill.",
            highlights: ["Lion Rock", "Beacon Hill", "City views"],
            facilities: [.init(name: "Pavilion", systemImage: "house"), .init(name: "Toilet", systemImage: "toilet")],
            transportation: "MTR Wong Tai Sin; Bus 72 from Tai Po Road",
            imageName: "maclehose5",
            checkpoints: [
                .init(title: "Tate's Cairn", subtitle: "Start", distanceKm: 0, altitude: 583),
                .init(title: "Lion Rock", subtitle: "Peak", distanceKm: 3.5, altitude: 495),
                .init(title: "Tai Po Road", subtitle: "Finish", distanceKm: 10.6, altitude: 150)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.350, longitude: 114.200),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EF01-567890123456")!,
            name: "MacLehose Section 8",
            district: "Tai Mo Shan",
            difficulty: .challenging,
            lengthKm: 9.7,
            elevationGain: 800,
            estimatedDurationMinutes: 300,
            summary: "Climb to Hong Kong's highest peak Tai Mo Shan from Lead Mine Pass.",
            highlights: ["Tai Mo Shan (957m)", "Highest peak", "Cloud sea views"],
            facilities: [.init(name: "Visitor center", systemImage: "building"), .init(name: "Toilet", systemImage: "toilet")],
            transportation: "Bus 51 to Lead Mine Pass; Bus 51 from Tai Mo Shan",
            imageName: "maclehose8",
            checkpoints: [
                .init(title: "Lead Mine Pass", subtitle: "Start", distanceKm: 0, altitude: 400),
                .init(title: "Tai Mo Shan", subtitle: "Peak", distanceKm: 4.8, altitude: 957),
                .init(title: "Route Twisk", subtitle: "Finish", distanceKm: 9.7, altitude: 500)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.408, longitude: 114.121),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        // Wilson Trail sections
        Trail(
            id: UUID(uuidString: "F6A7B8C9-D0E1-2345-F012-678901234567")!,
            name: "Wilson Trail Section 1",
            district: "Hong Kong Island",
            difficulty: .moderate,
            lengthKm: 4.8,
            elevationGain: 350,
            estimatedDurationMinutes: 150,
            summary: "From Stanley Gap Road to Tsz Lo Lan Shan via Violet Hill and The Twins.",
            highlights: ["Violet Hill", "The Twins", "Repulse Bay views"],
            facilities: [.init(name: "Shelter", systemImage: "house")],
            transportation: "Bus 6/6X/260 to Stanley Gap; Bus 6 from Tsz Lo Lan",
            imageName: "wilson1",
            checkpoints: [
                .init(title: "Stanley Gap", subtitle: "Start", distanceKm: 0, altitude: 200),
                .init(title: "Violet Hill", subtitle: "Peak", distanceKm: 2.0, altitude: 433),
                .init(title: "Tsz Lo Lan", subtitle: "Finish", distanceKm: 4.8, altitude: 250)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.240, longitude: 114.200),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        Trail(
            id: UUID(uuidString: "A7B8C9D0-E1F2-3456-0123-789012345678")!,
            name: "Wilson Trail Section 2",
            district: "Hong Kong Island",
            difficulty: .challenging,
            lengthKm: 6.6,
            elevationGain: 550,
            estimatedDurationMinutes: 240,
            summary: "From Tsz Lo Lan to Quarry Bay via Mount Butler and Jardine's Lookout.",
            highlights: ["Mount Butler", "Jardine's Lookout", "City skyline"],
            facilities: [.init(name: "Pavilion", systemImage: "house")],
            transportation: "Bus 6 to Tsz Lo Lan; MTR Quarry Bay",
            imageName: "wilson2",
            checkpoints: [
                .init(title: "Tsz Lo Lan", subtitle: "Start", distanceKm: 0, altitude: 250),
                .init(title: "Mount Butler", subtitle: "Peak", distanceKm: 2.5, altitude: 436),
                .init(title: "Quarry Bay", subtitle: "Finish", distanceKm: 6.6, altitude: 50)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.280, longitude: 114.220),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        // Lantau Trail sections
        Trail(
            id: UUID(uuidString: "B8C9D0E1-F2A3-4567-1234-890123456789")!,
            name: "Lantau Trail Section 2",
            district: "Lantau Island",
            difficulty: .challenging,
            lengthKm: 6.5,
            elevationGain: 750,
            estimatedDurationMinutes: 300,
            summary: "From Nam Shan to Pak Kung Au via Sunset Peak, Hong Kong's third highest peak.",
            highlights: ["Sunset Peak (869m)", "Mountain huts", "Sunset views"],
            facilities: [.init(name: "Mountain huts", systemImage: "house"), .init(name: "Camping", systemImage: "tent")],
            transportation: "Bus 3M/11 to Nam Shan; Bus 3M/11 from Pak Kung Au",
            imageName: "lantau2",
            checkpoints: [
                .init(title: "Nam Shan", subtitle: "Start", distanceKm: 0, altitude: 200),
                .init(title: "Sunset Peak", subtitle: "Peak", distanceKm: 3.2, altitude: 869),
                .init(title: "Pak Kung Au", subtitle: "Finish", distanceKm: 6.5, altitude: 400)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.255, longitude: 113.965),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "C9D0E1F2-A3B4-5678-2345-901234567890")!,
            name: "Lantau Trail Section 3",
            district: "Lantau Island",
            difficulty: .challenging,
            lengthKm: 4.5,
            elevationGain: 600,
            estimatedDurationMinutes: 240,
            summary: "From Pak Kung Au to Ngong Ping via Lantau Peak, Hong Kong's second highest peak.",
            highlights: ["Lantau Peak (934m)", "Big Buddha views", "Ngong Ping"],
            facilities: [.init(name: "Ngong Ping village", systemImage: "building"), .init(name: "Cable car", systemImage: "cablecar")],
            transportation: "Bus 3M/11 to Pak Kung Au; Cable car or bus from Ngong Ping",
            imageName: "lantau3",
            checkpoints: [
                .init(title: "Pak Kung Au", subtitle: "Start", distanceKm: 0, altitude: 400),
                .init(title: "Lantau Peak", subtitle: "Peak", distanceKm: 2.2, altitude: 934),
                .init(title: "Ngong Ping", subtitle: "Finish", distanceKm: 4.5, altitude: 460)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.270, longitude: 113.900),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        // Hong Kong Trail sections
        Trail(
            id: UUID(uuidString: "D0E1F2A3-B4C5-6789-3456-012345678901")!,
            name: "Hong Kong Trail Section 1",
            district: "Hong Kong Island",
            difficulty: .easy,
            lengthKm: 7.0,
            elevationGain: 200,
            estimatedDurationMinutes: 150,
            summary: "From The Peak to Pok Fu Lam Reservoir via Lugard Road and Harlech Road.",
            highlights: ["Peak views", "Pok Fu Lam Reservoir", "Easy walk"],
            facilities: [.init(name: "Peak Tower", systemImage: "building"), .init(name: "Toilet", systemImage: "toilet")],
            transportation: "Peak Tram or bus 15 to The Peak; Bus 7/71 from Pok Fu Lam",
            imageName: "hktrail1",
            checkpoints: [
                .init(title: "The Peak", subtitle: "Start", distanceKm: 0, altitude: 552),
                .init(title: "Pok Fu Lam", subtitle: "Finish", distanceKm: 7.0, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.270, longitude: 114.150),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        Trail(
            id: UUID(uuidString: "E1F2A3B4-C5D6-7890-4567-123456789012")!,
            name: "Hong Kong Trail Section 4",
            district: "Hong Kong Island",
            difficulty: .moderate,
            lengthKm: 7.5,
            elevationGain: 400,
            estimatedDurationMinutes: 210,
            summary: "From Wan Chai Gap to Wong Nai Chung Gap via Black's Link and Jardine's Lookout.",
            highlights: ["Black's Link", "Jardine's Lookout", "City views"],
            facilities: [.init(name: "Shelter", systemImage: "house")],
            transportation: "Bus 15 to Wan Chai Gap; Bus 6/41A from Wong Nai Chung",
            imageName: "hktrail4",
            checkpoints: [
                .init(title: "Wan Chai Gap", subtitle: "Start", distanceKm: 0, altitude: 200),
                .init(title: "Jardine's Lookout", subtitle: "Peak", distanceKm: 3.5, altitude: 433),
                .init(title: "Wong Nai Chung", subtitle: "Finish", distanceKm: 7.5, altitude: 150)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.260, longitude: 114.200),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        // Other iconic routes around Hong Kong
        Trail(
            id: UUID(uuidString: "F2A3B4C5-D6E7-8901-5678-234567890123")!,
            name: "Lion Rock",
            district: "Kowloon",
            difficulty: .challenging,
            lengthKm: 5.0,
            elevationGain: 450,
            estimatedDurationMinutes: 180,
            summary: "Iconic peak hike with panoramic views of Kowloon and Hong Kong Island.",
            highlights: ["Lion Rock (495m)", "Iconic landmark", "City panorama"],
            facilities: [.init(name: "Pavilion", systemImage: "house")],
            transportation: "MTR Wong Tai Sin; Bus 1/7M from Lion Rock Park",
            imageName: "lionrock",
            checkpoints: [
                .init(title: "Lion Rock Park", subtitle: "Start", distanceKm: 0, altitude: 100),
                .init(title: "Lion Rock", subtitle: "Peak", distanceKm: 2.5, altitude: 495),
                .init(title: "Sha Tin Pass", subtitle: "Finish", distanceKm: 5.0, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.344, longitude: 114.185),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        ),
        Trail(
            id: UUID(uuidString: "A3B4C5D6-E7F8-9012-6789-345678901234")!,
            name: "Sunset Peak",
            district: "Lantau Island",
            difficulty: .challenging,
            lengthKm: 8.0,
            elevationGain: 850,
            estimatedDurationMinutes: 360,
            summary: "Climb to Sunset Peak via Mui Wo, famous for sunrise and sunset views.",
            highlights: ["Sunset Peak (869m)", "Mountain huts", "Sunset views"],
            facilities: [.init(name: "Mountain huts", systemImage: "house"), .init(name: "Camping", systemImage: "tent")],
            transportation: "Ferry to Mui Wo; Bus 3M from Pak Kung Au",
            imageName: "sunsetpeak",
            checkpoints: [
                .init(title: "Mui Wo", subtitle: "Start", distanceKm: 0, altitude: 10),
                .init(title: "Sunset Peak", subtitle: "Peak", distanceKm: 4.0, altitude: 869),
                .init(title: "Pak Kung Au", subtitle: "Finish", distanceKm: 8.0, altitude: 400)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.255, longitude: 113.965),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        ),
        Trail(
            id: UUID(uuidString: "B4C5D6E7-F8A9-0123-7890-456789012345")!,
            name: "Sharp Peak",
            district: "Sai Kung",
            difficulty: .challenging,
            lengthKm: 12.0,
            elevationGain: 650,
            estimatedDurationMinutes: 360,
            summary: "Challenging peak in Sai Kung East Country Park with distinctive pyramid shape.",
            highlights: ["Sharp Peak (468m)", "Pyramid shape", "Coastal views"],
            facilities: [.init(name: "Camping", systemImage: "tent")],
            transportation: "Bus 94 to Pak Tam Chung; Taxi to High Island Reservoir",
            imageName: "sharppeak",
            checkpoints: [
                .init(title: "High Island Reservoir", subtitle: "Start", distanceKm: 0, altitude: 50),
                .init(title: "Sharp Peak", subtitle: "Peak", distanceKm: 6.0, altitude: 468),
                .init(title: "Tai Long Wan", subtitle: "Finish", distanceKm: 12.0, altitude: 10)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.425, longitude: 114.350),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        ),
        Trail(
            id: UUID(uuidString: "C5D6E7F8-A9B0-1234-8901-567890123456")!,
            name: "Tai Mo Shan",
            district: "Tai Mo Shan",
            difficulty: .moderate,
            lengthKm: 6.0,
            elevationGain: 500,
            estimatedDurationMinutes: 180,
            summary: "Hong Kong's highest peak at 957m, accessible via multiple routes.",
            highlights: ["Tai Mo Shan (957m)", "Highest peak", "Cloud sea"],
            facilities: [.init(name: "Visitor center", systemImage: "building"), .init(name: "Toilet", systemImage: "toilet")],
            transportation: "Bus 51 to Route Twisk; Bus 51 from Tai Mo Shan",
            imageName: "taimoshan",
            checkpoints: [
                .init(title: "Route Twisk", subtitle: "Start", distanceKm: 0, altitude: 500),
                .init(title: "Tai Mo Shan", subtitle: "Peak", distanceKm: 3.0, altitude: 957),
                .init(title: "Lead Mine Pass", subtitle: "Finish", distanceKm: 6.0, altitude: 400)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.408, longitude: 114.121),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        Trail(
            id: UUID(uuidString: "D6E7F8A9-B0C1-2345-9012-678901234567")!,
            name: "The Peak Circle Walk",
            district: "Hong Kong Island",
            difficulty: .easy,
            lengthKm: 3.5,
            elevationGain: 50,
            estimatedDurationMinutes: 90,
            summary: "Easy circular walk around The Peak with stunning city and harbor views.",
            highlights: ["Peak views", "Harbor panorama", "Easy walk"],
            facilities: [.init(name: "Peak Tower", systemImage: "building"), .init(name: "Restaurants", systemImage: "fork.knife")],
            transportation: "Peak Tram or bus 15 to The Peak",
            imageName: "peakcircle",
            checkpoints: [
                .init(title: "The Peak", subtitle: "Start/Finish", distanceKm: 0, altitude: 552),
                .init(title: "Lugard Road", subtitle: "Viewpoint", distanceKm: 1.5, altitude: 500)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.270, longitude: 114.150),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ),
        Trail(
            id: UUID(uuidString: "E7F8A9B0-C1D2-3456-0123-789012345678")!,
            name: "Tai Tam Reservoir",
            district: "Hong Kong Island",
            difficulty: .easy,
            lengthKm: 5.0,
            elevationGain: 150,
            estimatedDurationMinutes: 120,
            summary: "Scenic walk around Tai Tam Reservoir with historic dam structures.",
            highlights: ["Historic dams", "Reservoir views", "Family friendly"],
            facilities: [.init(name: "BBQ area", systemImage: "flame"), .init(name: "Toilet", systemImage: "toilet")],
            transportation: "Bus 14 to Tai Tam; Bus 6/63 from Stanley",
            imageName: "taitam",
            checkpoints: [
                .init(title: "Tai Tam", subtitle: "Start", distanceKm: 0, altitude: 50),
                .init(title: "Tai Tam Upper", subtitle: "Reservoir", distanceKm: 2.5, altitude: 100),
                .init(title: "Stanley", subtitle: "Finish", distanceKm: 5.0, altitude: 30)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.250, longitude: 114.230),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    ]
}

