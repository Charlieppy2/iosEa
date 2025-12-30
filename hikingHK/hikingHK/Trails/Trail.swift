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
    var startPointTransport: String? // 起點交通
    var endPointTransport: String? // 終點交通
    var supplyPoints: [String] // 補給點
    var exitRoutes: [String] // 退出路線
    var notes: String? // 注意事項
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
        startPointTransport: String? = nil,
        endPointTransport: String? = nil,
        supplyPoints: [String] = [],
        exitRoutes: [String] = [],
        notes: String? = nil,
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
        self.startPointTransport = startPointTransport
        self.endPointTransport = endPointTransport
        self.supplyPoints = supplyPoints
        self.exitRoutes = exitRoutes
        self.notes = notes
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
            lengthKm: 13.5,
            elevationGain: 720,
            estimatedDurationMinutes: 300, // 5 hours
            summary: "從水浪窩出發，繞過巍峨的馬鞍山，經過大金鐘，抵達昂平高原後，踏上位處黃牛山山腹的古道，走至大老山。",
            highlights: [
                "馬鞍山",
                "大金鐘",
                "昂平高原",
                "黃牛山"
            ],
            facilities: [
                .init(name: "郊野公園洗手間", systemImage: "toilet"),
                .init(name: "涼亭", systemImage: "house")
            ],
            transportation: "從水浪窩乘巴士 99；從大老山乘巴士或小巴",
            startPointTransport: "巴士 99/99R 到水浪窩",
            endPointTransport: "從大老山乘巴士或小巴返回",
            supplyPoints: [
                "水浪窩有士多",
                "昂平高原附近有補給點"
            ],
            exitRoutes: [
                "可在昂平高原退出，返回馬鞍山",
                "大老山隧道口可乘車離開"
            ],
            notes: "此路段較為困難，需攀越多個山峰，建議帶備充足食水和體力。部分路段較為陡峭，需注意安全。",
            imageName: "maclehose",
            checkpoints: [
                .init(title: "水浪窩", subtitle: "起點", distanceKm: 0, altitude: 5),
                .init(title: "馬鞍山", subtitle: "山峰", distanceKm: 5.0, altitude: 702),
                .init(title: "昂平高原", subtitle: "高原", distanceKm: 9.0, altitude: 400),
                .init(title: "大老山", subtitle: "終點", distanceKm: 13.5, altitude: 583)
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
            summary: "最受歡迎的半日行山路線，可欣賞石澳、大浪灣和赤柱的沿海風景。",
            highlights: [
                "石澳半島觀景台",
                "滑翔傘起飛點",
                "衝浪海灘終點"
            ],
            facilities: [
                .init(name: "大浪灣淋浴設施", systemImage: "shower.handheld"),
                .init(name: "水站", systemImage: "drop.triangle")
            ],
            transportation: "港鐵筲箕灣站 → 9號巴士至土地灣；回程從大浪灣乘巴士/小巴離開。",
            startPointTransport: "港鐵筲箕灣站 → 9號巴士至土地灣",
            endPointTransport: "從大浪灣乘巴士/小巴離開",
            supplyPoints: [
                "土地灣有士多",
                "大浪灣有商店和餐廳"
            ],
            exitRoutes: [
                "可在龍脊中途退出，返回土地灣",
                "大浪灣可乘車離開"
            ],
            notes: "此路線較為受歡迎，週末可能較為擁擠。建議帶備充足食水，部分路段較為暴露，需注意防曬。",
            imageName: "dragonsback",
            checkpoints: [
                .init(title: "土地灣", subtitle: "起點", distanceKm: 0, altitude: 105),
                .init(title: "龍脊", subtitle: "拍照點", distanceKm: 2.6, altitude: 284),
                .init(title: "大浪灣", subtitle: "終點", distanceKm: 8.5, altitude: 15)
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
            summary: "適合家庭的自然步道，展示梧桐寨瀑布群的四個主要瀑布。",
            highlights: [
                "主瀑布 35 米落差",
                "陰涼竹林",
                "溪流遊樂區"
            ],
            facilities: [
                .init(name: "村莊商店", systemImage: "cart"),
                .init(name: "的士站", systemImage: "car")
            ],
            transportation: "乘搭 64K/64P 巴士前往梧桐寨村；回程路線相同。",
            startPointTransport: "巴士 64K/64P 到梧桐寨村",
            endPointTransport: "從梧桐寨村乘巴士 64K/64P 返回",
            supplyPoints: [
                "梧桐寨村有士多",
                "沿途有溪水可補充"
            ],
            exitRoutes: [
                "可在中途退出，返回梧桐寨村",
                "原路返回起點"
            ],
            notes: "適合家庭遊覽，部分路段較為濕滑，建議穿著防滑鞋。瀑布附近石頭濕滑，需注意安全。",
            imageName: "taimoshan",
            checkpoints: [
                .init(title: "梧桐寨", subtitle: "起點", distanceKm: 0, altitude: 80),
                .init(title: "下瀑布", subtitle: "拍照點", distanceKm: 1.3, altitude: 160),
                .init(title: "主瀑布", subtitle: "中點", distanceKm: 2.8, altitude: 340)
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
        // MacLehose Trail sections (Updated based on oasistrek.com)
        Trail(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            name: "MacLehose Section 1",
            district: "Sai Kung",
            difficulty: .easy,
            lengthKm: 11.0,
            elevationGain: 100,
            estimatedDurationMinutes: 210, // 3.5 hours
            summary: "從西貢北潭涌出發，沿萬宜水庫旁的車道行走，抵達水清沙幼的浪茄灣。",
            highlights: ["萬宜水庫", "浪茄灣", "水清沙幼"],
            facilities: [.init(name: "洗手間", systemImage: "toilet"), .init(name: "燒烤場", systemImage: "flame")],
            transportation: "巴士 94/96R 到北潭涌",
            startPointTransport: "巴士 94/96R 到北潭涌",
            endPointTransport: "從浪茄需原路返回或繼續第二段",
            supplyPoints: [
                "北潭涌有補給點",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，返回北潭涌",
                "浪茄灣可繼續第二段或原路返回"
            ],
            notes: "此路段較為輕鬆，主要沿車道行走。部分路段較為暴露，需注意防曬。浪茄灣為沙灘，可在此休息。",
            imageName: "maclehose1",
            checkpoints: [
                .init(title: "北潭涌", subtitle: "起點", distanceKm: 0, altitude: 10),
                .init(title: "浪茄", subtitle: "終點", distanceKm: 11.0, altitude: 5)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.350, longitude: 114.370),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F23456789012")!,
            name: "MacLehose Section 2",
            district: "Sai Kung",
            difficulty: .moderate,
            lengthKm: 14.0,
            elevationGain: 400,
            estimatedDurationMinutes: 270, // 4.5 hours
            summary: "從浪茄出發，攀越西灣山後下降至香港最優美的沙灘大浪灣，繼而上走至北潭凹。",
            highlights: ["西灣山", "大浪灣", "香港最優美沙灘"],
            facilities: [.init(name: "露營場地", systemImage: "tent"), .init(name: "村莊商店", systemImage: "cart")],
            transportation: "從第一段終點開始；從北潭凹乘巴士 94",
            startPointTransport: "從第一段終點浪茄開始",
            endPointTransport: "從北潭凹乘巴士 94 返回",
            supplyPoints: [
                "西灣有士多和餐廳",
                "鹹田有士多",
                "大浪灣有補給點"
            ],
            exitRoutes: [
                "可在西灣退出，乘船離開",
                "可在鹹田退出，乘船離開",
                "可在大浪灣退出，乘船離開",
                "北潭凹可乘巴士離開"
            ],
            notes: "此路段需攀越西灣山，較為費力。沿途有多個沙灘，可在此休息。部分路段較為暴露，需注意防曬。建議帶備充足食水。",
            imageName: "maclehose2",
            checkpoints: [
                .init(title: "浪茄", subtitle: "起點", distanceKm: 0, altitude: 5),
                .init(title: "西灣山", subtitle: "山峰", distanceKm: 4.5, altitude: 314),
                .init(title: "大浪灣", subtitle: "沙灘", distanceKm: 8.0, altitude: 10),
                .init(title: "北潭凹", subtitle: "終點", distanceKm: 14.0, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.380, longitude: 114.380),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        ),
        Trail(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-345678901234")!,
            name: "MacLehose Section 3",
            district: "Sai Kung",
            difficulty: .challenging,
            lengthKm: 9.0,
            elevationGain: 600,
            estimatedDurationMinutes: 210, // 3.5 hours
            summary: "從北潭凹出發，跨越西貢西部數個山峰，包括畫眉山與雞公山。",
            highlights: ["畫眉山", "雞公山", "西貢西部山峰"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "從北潭凹乘巴士 94；從水浪窩乘巴士 99",
            startPointTransport: "從北潭凹乘巴士 94",
            endPointTransport: "從水浪窩乘巴士 99 返回",
            supplyPoints: [
                "水浪窩有士多",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "水浪窩可乘巴士離開"
            ],
            notes: "此路段較為困難，需攀越多個山峰。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。沿途有涼亭可休息。",
            imageName: "maclehose3",
            checkpoints: [
                .init(title: "北潭凹", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "畫眉山", subtitle: "山峰", distanceKm: 3.0, altitude: 300),
                .init(title: "雞公山", subtitle: "山峰", distanceKm: 6.0, altitude: 399),
                .init(title: "水浪窩", subtitle: "終點", distanceKm: 9.0, altitude: 5)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.383, longitude: 114.280),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEF0-456789012345")!,
            name: "MacLehose Section 5",
            district: "Kowloon",
            difficulty: .moderate,
            lengthKm: 11.0,
            elevationGain: 450,
            estimatedDurationMinutes: 210, // 3.5 hours
            summary: "從大老山出發，先後繞行九龍的獅子山和登上筆架山，再下走至九龍水塘。",
            highlights: ["獅子山", "筆架山", "九龍水塘", "城市景觀"],
            facilities: [.init(name: "涼亭", systemImage: "house"), .init(name: "洗手間", systemImage: "toilet")],
            transportation: "從大老山乘巴士；從大埔公路乘巴士 72",
            startPointTransport: "從大老山隧道口乘巴士或小巴",
            endPointTransport: "從大埔公路乘巴士 72 返回",
            supplyPoints: [
                "獅子山公園有補給點",
                "沿途有涼亭可休息"
            ],
            exitRoutes: [
                "可在獅子山公園退出",
                "可在筆架山退出",
                "大埔公路可乘巴士離開"
            ],
            notes: "此路段可欣賞九龍和香港島的城市景觀。部分路段較為暴露，需注意防曬。獅子山為香港地標，可在此拍照。",
            imageName: "maclehose5",
            checkpoints: [
                .init(title: "大老山", subtitle: "起點", distanceKm: 0, altitude: 583),
                .init(title: "獅子山", subtitle: "山峰", distanceKm: 3.5, altitude: 495),
                .init(title: "筆架山", subtitle: "山峰", distanceKm: 7.0, altitude: 457),
                .init(title: "大埔公路", subtitle: "終點", distanceKm: 11.0, altitude: 150)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.350, longitude: 114.200),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "F1A2B3C4-D5E6-7890-ABCD-EF1234567890")!,
            name: "MacLehose Section 6",
            district: "New Territories Central",
            difficulty: .easy,
            lengthKm: 4.0,
            elevationGain: 200,
            estimatedDurationMinutes: 90, // 1.5 hours
            summary: "從大埔公路出發，邁向新界中部，走過城門水塘。",
            highlights: ["城門水塘", "新界中部", "水塘景觀"],
            facilities: [.init(name: "洗手間", systemImage: "toilet"), .init(name: "燒烤場", systemImage: "flame")],
            transportation: "從大埔公路乘巴士；從城門水塘乘巴士",
            startPointTransport: "從大埔公路乘巴士 72",
            endPointTransport: "從城門水塘乘巴士返回",
            supplyPoints: [
                "城門水塘有補給點",
                "沿途有燒烤場"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "城門水塘可乘巴士離開"
            ],
            notes: "此路段較為輕鬆，主要沿水塘行走。適合家庭遊覽。沿途有燒烤場和洗手間。",
            imageName: "maclehose6",
            checkpoints: [
                .init(title: "大埔公路", subtitle: "起點", distanceKm: 0, altitude: 150),
                .init(title: "城門水塘", subtitle: "終點", distanceKm: 4.0, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.380, longitude: 114.150),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        Trail(
            id: UUID(uuidString: "F2A3B4C5-D6E7-8901-BCDE-F23456789012")!,
            name: "MacLehose Section 7",
            district: "New Territories Central",
            difficulty: .challenging,
            lengthKm: 7.0,
            elevationGain: 600,
            estimatedDurationMinutes: 210, // 3.5 hours
            summary: "從城門水塘出發，急攀針山與草山後，下降至鉛礦坳。",
            highlights: ["針山", "草山", "急攀路段"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "從城門水塘乘巴士；從鉛礦坳乘巴士 51",
            startPointTransport: "從城門水塘乘巴士",
            endPointTransport: "從鉛礦坳乘巴士 51 返回",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "鉛礦坳有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "鉛礦坳可乘巴士離開"
            ],
            notes: "此路段需急攀針山和草山，較為困難。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。沿途有涼亭可休息。",
            imageName: "maclehose7",
            checkpoints: [
                .init(title: "城門水塘", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "針山", subtitle: "山峰", distanceKm: 2.5, altitude: 532),
                .init(title: "草山", subtitle: "山峰", distanceKm: 5.0, altitude: 647),
                .init(title: "鉛礦坳", subtitle: "終點", distanceKm: 7.0, altitude: 400)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.400, longitude: 114.130),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EF01-567890123456")!,
            name: "MacLehose Section 8",
            district: "Tai Mo Shan",
            difficulty: .challenging,
            lengthKm: 9.5,
            elevationGain: 800,
            estimatedDurationMinutes: 210, // 3.5 hours
            summary: "從鉛礦坳出發，登上香港的最高峰大帽山，再下走至荃錦坳。",
            highlights: ["大帽山 (957m)", "香港最高峰", "雲海景觀"],
            facilities: [.init(name: "遊客中心", systemImage: "building"), .init(name: "洗手間", systemImage: "toilet")],
            transportation: "從鉛礦坳乘巴士 51；從荃錦公路乘巴士 51",
            startPointTransport: "從鉛礦坳乘巴士 51",
            endPointTransport: "從荃錦公路乘巴士 51 返回",
            supplyPoints: [
                "大帽山遊客中心有補給點",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "荃錦公路可乘巴士離開"
            ],
            notes: "此路段需登上香港最高峰大帽山，較為困難。山頂經常被雲霧籠罩，需注意保暖。建議帶備充足食水和體力。部分路段較為陡峭，需注意安全。",
            imageName: "maclehose8",
            checkpoints: [
                .init(title: "鉛礦坳", subtitle: "起點", distanceKm: 0, altitude: 400),
                .init(title: "大帽山", subtitle: "山峰", distanceKm: 4.8, altitude: 957),
                .init(title: "荃錦公路", subtitle: "終點", distanceKm: 9.5, altitude: 500)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.408, longitude: 114.121),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ),
        Trail(
            id: UUID(uuidString: "F3A4B5C6-D7E8-9012-CDEF-345678901234")!,
            name: "MacLehose Section 9",
            district: "New Territories Northwest",
            difficulty: .easy,
            lengthKm: 6.0,
            elevationGain: 100,
            estimatedDurationMinutes: 90, // 1.5 hours
            summary: "從荃錦公路出發，進入大欖郊野公園的植林區，往田夫仔進發。",
            highlights: ["大欖郊野公園", "植林區", "田夫仔"],
            facilities: [.init(name: "露營場地", systemImage: "tent")],
            transportation: "從荃錦公路乘巴士 51；從田夫仔步行或乘車",
            startPointTransport: "從荃錦公路乘巴士 51",
            endPointTransport: "從田夫仔需步行或乘車離開",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "田夫仔有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "田夫仔可繼續第十段或離開"
            ],
            notes: "此路段較為輕鬆，主要穿過植林區。適合家庭遊覽。沿途有露營場地。",
            imageName: "maclehose9",
            checkpoints: [
                .init(title: "荃錦公路", subtitle: "起點", distanceKm: 0, altitude: 500),
                .init(title: "田夫仔", subtitle: "終點", distanceKm: 6.0, altitude: 200)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.420, longitude: 114.100),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ),
        Trail(
            id: UUID(uuidString: "F4A5B6C7-D8E9-0123-DEF0-456789012345")!,
            name: "MacLehose Section 10",
            district: "Tuen Mun",
            difficulty: .moderate,
            lengthKm: 15.5,
            elevationGain: 300,
            estimatedDurationMinutes: 300, // 5 hours
            summary: "從田夫仔出發，穿越土地較貧瘠的新界西部，以屯門為終站。",
            highlights: ["新界西部", "屯門", "麥理浩徑終點"],
            facilities: [.init(name: "Toilet", systemImage: "toilet")],
            transportation: "從田夫仔步行；從屯門乘港鐵或巴士",
            startPointTransport: "從田夫仔開始（需從荃錦公路步行或乘車到達）",
            endPointTransport: "從屯門乘港鐵或巴士返回",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "屯門有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "屯門為麥理浩徑終點，可乘港鐵或巴士離開"
            ],
            notes: "此路段為麥理浩徑最後一段，距離較長。沿途土地較為貧瘠，需帶備充足食水。屯門為終點，可在此慶祝完成整條麥理浩徑。",
            imageName: "maclehose10",
            checkpoints: [
                .init(title: "田夫仔", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "屯門", subtitle: "終點", distanceKm: 15.5, altitude: 10)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.400, longitude: 113.980),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
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
            summary: "從赤柱峽道到紫羅蘭山，途經紫崗橋和孖崗山。",
            highlights: ["紫羅蘭山", "孖崗山", "淺水灣景色"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "巴士 6/6X/260 到赤柱峽；從紫羅蘭山乘巴士 6",
            startPointTransport: "巴士 6/6X/260 到赤柱峽",
            endPointTransport: "從紫羅蘭山乘巴士 6 返回",
            supplyPoints: [
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "紫羅蘭山可乘巴士離開"
            ],
            notes: "此路段需攀越紫羅蘭山和孖崗山，較為費力。可欣賞淺水灣和南灣的景色。部分路段較為陡峭，需注意安全。",
            imageName: "wilson1",
            checkpoints: [
                .init(title: "赤柱峽", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "紫羅蘭山", subtitle: "山峰", distanceKm: 2.0, altitude: 433),
                .init(title: "紫羅蘭山", subtitle: "終點", distanceKm: 4.8, altitude: 250)
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
            summary: "從紫羅蘭山到鰂魚涌，途經畢拿山和渣甸山。",
            highlights: ["畢拿山", "渣甸山", "城市天際線"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "從紫羅蘭山乘巴士 6；從鰂魚涌乘港鐵",
            startPointTransport: "從紫羅蘭山乘巴士 6",
            endPointTransport: "從鰂魚涌乘港鐵返回",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "鰂魚涌有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "鰂魚涌可乘港鐵離開"
            ],
            notes: "此路段需攀越畢拿山和渣甸山，較為困難。可欣賞香港島的城市景觀。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。",
            imageName: "wilson2",
            checkpoints: [
                .init(title: "紫羅蘭山", subtitle: "起點", distanceKm: 0, altitude: 250),
                .init(title: "畢拿山", subtitle: "山峰", distanceKm: 2.5, altitude: 436),
                .init(title: "鰂魚涌", subtitle: "終點", distanceKm: 6.6, altitude: 50)
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
            summary: "從南山到伯公坳，途經香港第三高峰鳳凰山。",
            highlights: ["鳳凰山 (869m)", "山屋", "日落景色"],
            facilities: [.init(name: "山屋", systemImage: "house"), .init(name: "露營", systemImage: "tent")],
            transportation: "從南山乘巴士 3M/11；從伯公坳乘巴士 3M/11",
            startPointTransport: "從南山乘巴士 3M/11",
            endPointTransport: "從伯公坳乘巴士 3M/11 返回",
            supplyPoints: [
                "大東山有山屋可休息",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "伯公坳可乘巴士離開"
            ],
            notes: "此路段需攀越香港第三高峰大東山，較為困難。山頂有山屋可休息。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。大東山以日落景色聞名。",
            imageName: "lantau2",
            checkpoints: [
                .init(title: "南山", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "鳳凰山", subtitle: "山峰", distanceKm: 3.2, altitude: 869),
                .init(title: "伯公坳", subtitle: "終點", distanceKm: 6.5, altitude: 400)
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
            summary: "從伯公坳到昂坪，途經香港第二高峰大東山。",
            highlights: ["大東山 (934m)", "大佛景色", "昂坪"],
            facilities: [.init(name: "昂坪村", systemImage: "building"), .init(name: "纜車", systemImage: "cablecar")],
            transportation: "從伯公坳乘巴士 3M/11；從昂坪乘纜車或巴士",
            startPointTransport: "從伯公坳乘巴士 3M/11",
            endPointTransport: "從昂坪乘纜車或巴士返回",
            supplyPoints: [
                "昂坪有補給點和餐廳",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "昂坪可乘纜車或巴士離開"
            ],
            notes: "此路段需攀越香港第二高峰鳳凰山，較為困難。山頂可欣賞大佛和昂坪的景色。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。昂坪有補給點和餐廳。",
            imageName: "lantau3",
            checkpoints: [
                .init(title: "伯公坳", subtitle: "起點", distanceKm: 0, altitude: 400),
                .init(title: "大東山", subtitle: "山峰", distanceKm: 2.2, altitude: 934),
                .init(title: "昂坪", subtitle: "終點", distanceKm: 4.5, altitude: 460)
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
            summary: "從山頂到薄扶林水塘，途經盧吉道和夏力道。",
            highlights: ["山頂景色", "薄扶林水塘", "輕鬆步行"],
            facilities: [.init(name: "山頂廣場", systemImage: "building"), .init(name: "洗手間", systemImage: "toilet")],
            transportation: "山頂纜車或巴士 15 到山頂；從薄扶林乘巴士 7/71",
            startPointTransport: "山頂纜車或巴士 15 到山頂",
            endPointTransport: "從薄扶林水塘乘巴士 7/71 返回",
            supplyPoints: [
                "山頂有補給點和餐廳",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "薄扶林水塘可乘巴士離開"
            ],
            notes: "此路段較為輕鬆，主要沿山頂和薄扶林水塘行走。可欣賞香港島和維多利亞港的景色。適合家庭遊覽。",
            imageName: "hktrail1",
            checkpoints: [
                .init(title: "山頂", subtitle: "起點", distanceKm: 0, altitude: 552),
                .init(title: "薄扶林", subtitle: "終點", distanceKm: 7.0, altitude: 200)
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
            summary: "從灣仔峽到黃泥涌峽，途經布力徑和渣甸山。",
            highlights: ["布力徑", "渣甸山", "城市景色"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "從灣仔峽乘巴士 15；從黃泥涌峽乘巴士 6/41A",
            startPointTransport: "從灣仔峽乘巴士 15",
            endPointTransport: "從黃泥涌峽乘巴士 6/41A 返回",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "黃泥涌峽有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "黃泥涌峽可乘巴士離開"
            ],
            notes: "此路段需攀越渣甸山，較為費力。可欣賞香港島的城市景觀。部分路段較為暴露，需注意防曬。沿途有涼亭可休息。",
            imageName: "hktrail4",
            checkpoints: [
                .init(title: "灣仔峽", subtitle: "起點", distanceKm: 0, altitude: 200),
                .init(title: "渣甸山", subtitle: "山峰", distanceKm: 3.5, altitude: 433),
                .init(title: "黃泥涌峽", subtitle: "終點", distanceKm: 7.5, altitude: 150)
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
            summary: "標誌性的山峰行山路線，可欣賞九龍和香港島的全景。",
            highlights: ["獅子山 (495m)", "標誌性地標", "城市全景"],
            facilities: [.init(name: "涼亭", systemImage: "house")],
            transportation: "港鐵黃大仙站；從獅子山公園乘巴士 1/7M",
            startPointTransport: "港鐵黃大仙站，步行至獅子山公園",
            endPointTransport: "從獅子山公園乘巴士 1/7M 返回",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "獅子山公園有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "獅子山公園可乘巴士離開"
            ],
            notes: "此路線為香港地標獅子山，較為困難。山頂可欣賞九龍和香港島的全景。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。",
            imageName: "lionrock",
            checkpoints: [
                .init(title: "獅子山公園", subtitle: "起點", distanceKm: 0, altitude: 100),
                .init(title: "獅子山", subtitle: "山峰", distanceKm: 2.5, altitude: 495),
                .init(title: "沙田坳", subtitle: "終點", distanceKm: 5.0, altitude: 200)
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
            summary: "從梅窩攀登至鳳凰山，以日出和日落景色聞名。",
            highlights: ["鳳凰山 (869m)", "山屋", "日落景色"],
            facilities: [.init(name: "山屋", systemImage: "house"), .init(name: "露營", systemImage: "tent")],
            transportation: "從中環乘渡輪到梅窩；從伯公坳乘巴士 3M",
            startPointTransport: "從中環乘渡輪到梅窩",
            endPointTransport: "從伯公坳乘巴士 3M 返回",
            supplyPoints: [
                "梅窩有補給點",
                "大東山有山屋可休息",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "伯公坳可乘巴士離開"
            ],
            notes: "此路線需攀越香港第三高峰大東山，較為困難。山頂有山屋可休息。大東山以日落和日出景色聞名。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。",
            imageName: "sunsetpeak",
            checkpoints: [
                .init(title: "梅窩", subtitle: "起點", distanceKm: 0, altitude: 10),
                .init(title: "鳳凰山", subtitle: "山峰", distanceKm: 4.0, altitude: 869),
                .init(title: "伯公坳", subtitle: "終點", distanceKm: 8.0, altitude: 400)
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
            summary: "西貢東郊野公園的挑戰性山峰，具有獨特的金字塔形狀。",
            highlights: ["蚺蛇尖 (468m)", "金字塔形狀", "海岸景色"],
            facilities: [.init(name: "露營", systemImage: "tent")],
            transportation: "從北潭涌乘巴士 94；轉乘的士到萬宜水庫",
            startPointTransport: "從北潭涌乘巴士 94，再轉乘的士到萬宜水庫",
            endPointTransport: "從大浪灣需原路返回或乘船離開",
            supplyPoints: [
                "沿途無補給，需自備食水",
                "大浪灣有補給點"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "大浪灣可乘船離開或原路返回"
            ],
            notes: "此路線為香港最困難的路線之一，需攀越蚺蛇尖。蚺蛇尖以金字塔形狀聞名，部分路段極為陡峭，需手腳並用。建議帶備充足食水和體力，並注意安全。不適合初學者。",
            imageName: "sharppeak",
            checkpoints: [
                .init(title: "萬宜水庫", subtitle: "起點", distanceKm: 0, altitude: 50),
                .init(title: "蚺蛇尖", subtitle: "山峰", distanceKm: 6.0, altitude: 468),
                .init(title: "大浪灣", subtitle: "終點", distanceKm: 12.0, altitude: 10)
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
            summary: "香港最高峰，海拔957米，可通過多條路線到達。",
            highlights: ["大帽山 (957m)", "最高峰", "雲海"],
            facilities: [.init(name: "遊客中心", systemImage: "building"), .init(name: "洗手間", systemImage: "toilet")],
            transportation: "從荃錦公路乘巴士 51；從大帽山遊客中心乘巴士 51",
            startPointTransport: "從荃錦公路乘巴士 51",
            endPointTransport: "從大帽山遊客中心乘巴士 51 返回",
            supplyPoints: [
                "大帽山遊客中心有補給點",
                "沿途無補給，需自備食水"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "大帽山遊客中心可乘巴士離開"
            ],
            notes: "此路線需登上香港最高峰大帽山。山頂經常被雲霧籠罩，需注意保暖。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。大帽山以雲海景觀聞名。",
            imageName: "taimoshan",
            checkpoints: [
                .init(title: "荃錦公路", subtitle: "起點", distanceKm: 0, altitude: 500),
                .init(title: "大帽山", subtitle: "山峰", distanceKm: 3.0, altitude: 957),
                .init(title: "鉛礦坳", subtitle: "終點", distanceKm: 6.0, altitude: 400)
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
            summary: "圍繞山頂的輕鬆環形步道，可欣賞城市和海港的壯麗景色。",
            highlights: ["山頂景色", "海港全景", "輕鬆步行"],
            facilities: [.init(name: "山頂廣場", systemImage: "building"), .init(name: "餐廳", systemImage: "fork.knife")],
            transportation: "山頂纜車或巴士 15 到山頂",
            startPointTransport: "山頂纜車或巴士 15 到山頂",
            endPointTransport: "從山頂乘山頂纜車或巴士 15 返回",
            supplyPoints: [
                "山頂有補給點和餐廳",
                "沿途有餐廳和商店"
            ],
            exitRoutes: [
                "可在任何時候退出，返回山頂",
                "山頂可乘纜車或巴士離開"
            ],
            notes: "此路線為環迴步行徑，較為輕鬆。可欣賞香港島和維多利亞港的全景。適合家庭遊覽。沿途有餐廳和商店。",
            imageName: "peakcircle",
            checkpoints: [
                .init(title: "山頂", subtitle: "起點/終點", distanceKm: 0, altitude: 552),
                .init(title: "盧吉道", subtitle: "觀景點", distanceKm: 1.5, altitude: 500)
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
            summary: "圍繞大潭水塘的風景步道，有歷史悠久的堤壩建築。",
            highlights: ["歷史堤壩", "水塘景色", "適合家庭"],
            facilities: [.init(name: "燒烤場", systemImage: "flame"), .init(name: "洗手間", systemImage: "toilet")],
            transportation: "從大潭乘巴士 14；從赤柱乘巴士 6/63",
            startPointTransport: "從大潭乘巴士 14",
            endPointTransport: "從赤柱乘巴士 6/63 返回",
            supplyPoints: [
                "沿途有燒烤場",
                "赤柱有補給點和餐廳"
            ],
            exitRoutes: [
                "可在中途退出，但較為困難",
                "赤柱可乘巴士離開"
            ],
            notes: "此路線較為輕鬆，主要沿水塘行走。可欣賞歷史水壩建築。適合家庭遊覽。沿途有燒烤場和洗手間。",
            imageName: "taitam",
            checkpoints: [
                .init(title: "大潭", subtitle: "起點", distanceKm: 0, altitude: 50),
                .init(title: "大潭上水塘", subtitle: "水塘", distanceKm: 2.5, altitude: 100),
                .init(title: "赤柱", subtitle: "終點", distanceKm: 5.0, altitude: 30)
            ],
            mapCenter: CLLocationCoordinate2D(latitude: 22.250, longitude: 114.230),
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    ]
}

