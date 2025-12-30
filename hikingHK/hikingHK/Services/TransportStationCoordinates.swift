//
//  TransportStationCoordinates.swift
//  hikingHK
//
//  Created on 31/12/2025.
//

import Foundation
import CoreLocation

/// Station coordinate data for MTR and Bus stations
struct TransportStationCoordinates {
    /// MTR station coordinates (major stations in Hong Kong)
    static let mtrStations: [String: CLLocationCoordinate2D] = [
        // Island Line
        "中環": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1581),
        "Central": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1581),
        "金鐘": CLLocationCoordinate2D(latitude: 22.2781, longitude: 114.1664),
        "Admiralty": CLLocationCoordinate2D(latitude: 22.2781, longitude: 114.1664),
        "灣仔": CLLocationCoordinate2D(latitude: 22.2775, longitude: 114.1719),
        "Wan Chai": CLLocationCoordinate2D(latitude: 22.2775, longitude: 114.1719),
        "銅鑼灣": CLLocationCoordinate2D(latitude: 22.2800, longitude: 114.1850),
        "Causeway Bay": CLLocationCoordinate2D(latitude: 22.2800, longitude: 114.1850),
        "天后": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.1919),
        "Tin Hau": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.1919),
        "炮台山": CLLocationCoordinate2D(latitude: 22.2881, longitude: 114.1950),
        "Fortress Hill": CLLocationCoordinate2D(latitude: 22.2881, longitude: 114.1950),
        "北角": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2019),
        "North Point": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2019),
        "鰂魚涌": CLLocationCoordinate2D(latitude: 22.2869, longitude: 114.2100),
        "Quarry Bay": CLLocationCoordinate2D(latitude: 22.2869, longitude: 114.2100),
        "太古城": CLLocationCoordinate2D(latitude: 22.2881, longitude: 114.2181),
        "Tai Koo": CLLocationCoordinate2D(latitude: 22.2881, longitude: 114.2181),
        "西灣河": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.2250),
        "Sai Wan Ho": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.2250),
        "筲箕灣": CLLocationCoordinate2D(latitude: 22.2806, longitude: 114.2319),
        "Shau Kei Wan": CLLocationCoordinate2D(latitude: 22.2806, longitude: 114.2319),
        "杏花邨": CLLocationCoordinate2D(latitude: 22.2750, longitude: 114.2400),
        "Heng Fa Chuen": CLLocationCoordinate2D(latitude: 22.2750, longitude: 114.2400),
        "柴灣": CLLocationCoordinate2D(latitude: 22.2656, longitude: 114.2450),
        "Chai Wan": CLLocationCoordinate2D(latitude: 22.2656, longitude: 114.2450),
        
        // Tsuen Wan Line
        "荃灣": CLLocationCoordinate2D(latitude: 22.3706, longitude: 114.1131),
        "Tsuen Wan": CLLocationCoordinate2D(latitude: 22.3706, longitude: 114.1131),
        "大窩口": CLLocationCoordinate2D(latitude: 22.3681, longitude: 114.1231),
        "Tai Wo Hau": CLLocationCoordinate2D(latitude: 22.3681, longitude: 114.1231),
        "葵興": CLLocationCoordinate2D(latitude: 22.3656, longitude: 114.1300),
        "Kwai Hing": CLLocationCoordinate2D(latitude: 22.3656, longitude: 114.1300),
        "葵芳": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1250),
        "Kwai Fong": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1250),
        "荔景": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1319),
        "Lai King": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1319),
        "美孚": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1381),
        "Mei Foo": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1381),
        "荔枝角": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1450),
        "Lai Chi Kok": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1450),
        "長沙灣": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.1519),
        "Cheung Sha Wan": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.1519),
        "深水埗": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1581),
        "Sham Shui Po": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1581),
        "太子": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.1650),
        "Prince Edward": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.1650),
        "旺角": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.1700),
        "Mong Kok": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.1700),
        "油麻地": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.1750),
        "Yau Ma Tei": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.1750),
        "佐敦": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1800),
        "Jordan": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1800),
        "尖沙咀": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1850),
        "Tsim Sha Tsui": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1850),
        
        // Kwun Tong Line
        "黃大仙": CLLocationCoordinate2D(latitude: 22.3431, longitude: 114.1950),
        "Wong Tai Sin": CLLocationCoordinate2D(latitude: 22.3431, longitude: 114.1950),
        "鑽石山": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.2019),
        "Diamond Hill": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.2019),
        "彩虹": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.2081),
        "Choi Hung": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.2081),
        "九龍灣": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.2131),
        "Kowloon Bay": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.2131),
        "牛頭角": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.2181),
        "Ngau Tau Kok": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.2181),
        "觀塘": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2250),
        "Kwun Tong": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2250),
        "藍田": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2319),
        "Lam Tin": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2319),
        "油塘": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.2381),
        "Yau Tong": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.2381),
        "調景嶺": CLLocationCoordinate2D(latitude: 22.2981, longitude: 114.2450),
        "Tiu Keng Leng": CLLocationCoordinate2D(latitude: 22.2981, longitude: 114.2450),
        
        // East Rail Line
        "紅磡": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1800),
        "Hung Hom": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1800),
        "尖東": CLLocationCoordinate2D(latitude: 22.2981, longitude: 114.1750),
        "East Tsim Sha Tsui": CLLocationCoordinate2D(latitude: 22.2981, longitude: 114.1750),
        "旺角東": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.1750),
        "Mong Kok East": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.1750),
        "九龍塘": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1750),
        "Kowloon Tong": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1750),
        "大圍": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1800),
        "Tai Wai": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1800),
        "沙田": CLLocationCoordinate2D(latitude: 22.3781, longitude: 114.1881),
        "Sha Tin": CLLocationCoordinate2D(latitude: 22.3781, longitude: 114.1881),
        "火炭": CLLocationCoordinate2D(latitude: 22.3931, longitude: 114.1950),
        "Fo Tan": CLLocationCoordinate2D(latitude: 22.3931, longitude: 114.1950),
        "大學": CLLocationCoordinate2D(latitude: 22.4131, longitude: 114.2050),
        "University": CLLocationCoordinate2D(latitude: 22.4131, longitude: 114.2050),
        "大埔墟": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.1681),
        "Tai Po Market": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.1681),
        "太和": CLLocationCoordinate2D(latitude: 22.4531, longitude: 114.1631),
        "Tai Wo": CLLocationCoordinate2D(latitude: 22.4531, longitude: 114.1631),
        "粉嶺": CLLocationCoordinate2D(latitude: 22.4931, longitude: 114.1431),
        "Fanling": CLLocationCoordinate2D(latitude: 22.4931, longitude: 114.1431),
        "上水": CLLocationCoordinate2D(latitude: 22.5031, longitude: 114.1281),
        "Sheung Shui": CLLocationCoordinate2D(latitude: 22.5031, longitude: 114.1281),
        "羅湖": CLLocationCoordinate2D(latitude: 22.5281, longitude: 114.1131),
        "Lo Wu": CLLocationCoordinate2D(latitude: 22.5281, longitude: 114.1131),
        "落馬洲": CLLocationCoordinate2D(latitude: 22.5131, longitude: 114.0681),
        "Lok Ma Chau": CLLocationCoordinate2D(latitude: 22.5131, longitude: 114.0681),
        
        // Tuen Ma Line
        "屯門": CLLocationCoordinate2D(latitude: 22.3931, longitude: 113.9750),
        "Tuen Mun": CLLocationCoordinate2D(latitude: 22.3931, longitude: 113.9750),
        "兆康": CLLocationCoordinate2D(latitude: 22.4081, longitude: 113.9781),
        "Siu Hong": CLLocationCoordinate2D(latitude: 22.4081, longitude: 113.9781),
        "天水圍": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0031),
        "Tin Shui Wai": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0031),
        "元朗": CLLocationCoordinate2D(latitude: 22.4431, longitude: 114.0331),
        "Yuen Long": CLLocationCoordinate2D(latitude: 22.4431, longitude: 114.0331),
        "錦上路": CLLocationCoordinate2D(latitude: 22.4281, longitude: 114.0631),
        "Kam Sheung Road": CLLocationCoordinate2D(latitude: 22.4281, longitude: 114.0631),
        "朗屏": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0281),
        "Long Ping": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0281),
        "何文田": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1831),
        "Ho Man Tin": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1831),
        "香港": CLLocationCoordinate2D(latitude: 22.2850, longitude: 114.1581),
        "Hong Kong": CLLocationCoordinate2D(latitude: 22.2850, longitude: 114.1581),
        "九龍": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1600),
        "Kowloon": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1600),
        "柯士甸": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1650),
        "Austin": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1650),
        "會展": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1731),
        "Exhibition Centre": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1731),
        "南昌": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1531),
        "Nam Cheong": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1531),
        
        // Tung Chung Line
        "東涌": CLLocationCoordinate2D(latitude: 22.2881, longitude: 113.9431),
        "Tung Chung": CLLocationCoordinate2D(latitude: 22.2881, longitude: 113.9431),
        "欣澳": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.0081),
        "Sunny Bay": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.0081),
        "青衣": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1081),
        "Tsing Yi": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1081),
        
        // Tseung Kwan O Line
        "將軍澳": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2581),
        "Tseung Kwan O": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2581),
        "坑口": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2650),
        "Hang Hau": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2650),
        "寶琳": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.2581),
        "Po Lam": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.2581),
        "康城": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2731),
        "LOHAS Park": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2731),
        
        // South Island Line
        "海洋公園": CLLocationCoordinate2D(latitude: 22.2481, longitude: 114.1750),
        "Ocean Park": CLLocationCoordinate2D(latitude: 22.2481, longitude: 114.1750),
        "黃竹坑": CLLocationCoordinate2D(latitude: 22.2531, longitude: 114.1681),
        "Wong Chuk Hang": CLLocationCoordinate2D(latitude: 22.2531, longitude: 114.1681),
        "利東": CLLocationCoordinate2D(latitude: 22.2431, longitude: 114.1631),
        "Lei Tung": CLLocationCoordinate2D(latitude: 22.2431, longitude: 114.1631),
        "海怡半島": CLLocationCoordinate2D(latitude: 22.2381, longitude: 114.1581),
        "South Horizons": CLLocationCoordinate2D(latitude: 22.2381, longitude: 114.1581),
        
        // Other
        "堅尼地城": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.1281),
        "Kennedy Town": CLLocationCoordinate2D(latitude: 22.2831, longitude: 114.1281),
    ]
    
    /// Major bus stations coordinates (主要巴士站坐标)
    static let busStations: [String: CLLocationCoordinate2D] = [
        // Hong Kong Island
        "中環": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1581),
        "Central": CLLocationCoordinate2D(latitude: 22.2819, longitude: 114.1581),
        "金鐘": CLLocationCoordinate2D(latitude: 22.2781, longitude: 114.1664),
        "Admiralty": CLLocationCoordinate2D(latitude: 22.2781, longitude: 114.1664),
        "銅鑼灣": CLLocationCoordinate2D(latitude: 22.2800, longitude: 114.1850),
        "Causeway Bay": CLLocationCoordinate2D(latitude: 22.2800, longitude: 114.1850),
        "北角": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2019),
        "North Point": CLLocationCoordinate2D(latitude: 22.2931, longitude: 114.2019),
        "柴灣": CLLocationCoordinate2D(latitude: 22.2656, longitude: 114.2450),
        "Chai Wan": CLLocationCoordinate2D(latitude: 22.2656, longitude: 114.2450),
        "香港仔": CLLocationCoordinate2D(latitude: 22.2481, longitude: 114.1550),
        "Aberdeen": CLLocationCoordinate2D(latitude: 22.2481, longitude: 114.1550),
        "赤柱": CLLocationCoordinate2D(latitude: 22.2181, longitude: 114.2131),
        "Stanley": CLLocationCoordinate2D(latitude: 22.2181, longitude: 114.2131),
        
        // Kowloon
        "尖沙咀": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1850),
        "Tsim Sha Tsui": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.1850),
        "佐敦": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1800),
        "Jordan": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.1800),
        "旺角": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.1700),
        "Mong Kok": CLLocationCoordinate2D(latitude: 22.3181, longitude: 114.1700),
        "深水埗": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1581),
        "Sham Shui Po": CLLocationCoordinate2D(latitude: 22.3281, longitude: 114.1581),
        "長沙灣": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.1519),
        "Cheung Sha Wan": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.1519),
        "美孚": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1381),
        "Mei Foo": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1381),
        "九龍塘": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1750),
        "Kowloon Tong": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.1750),
        "黃大仙": CLLocationCoordinate2D(latitude: 22.3431, longitude: 114.1950),
        "Wong Tai Sin": CLLocationCoordinate2D(latitude: 22.3431, longitude: 114.1950),
        "鑽石山": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.2019),
        "Diamond Hill": CLLocationCoordinate2D(latitude: 22.3381, longitude: 114.2019),
        "彩虹": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.2081),
        "Choi Hung": CLLocationCoordinate2D(latitude: 22.3331, longitude: 114.2081),
        "九龍灣": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.2131),
        "Kowloon Bay": CLLocationCoordinate2D(latitude: 22.3231, longitude: 114.2131),
        "觀塘": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2250),
        "Kwun Tong": CLLocationCoordinate2D(latitude: 22.3131, longitude: 114.2250),
        "藍田": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2319),
        "Lam Tin": CLLocationCoordinate2D(latitude: 22.3081, longitude: 114.2319),
        "油塘": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.2381),
        "Yau Tong": CLLocationCoordinate2D(latitude: 22.3031, longitude: 114.2381),
        
        // New Territories
        "沙田": CLLocationCoordinate2D(latitude: 22.3781, longitude: 114.1881),
        "Sha Tin": CLLocationCoordinate2D(latitude: 22.3781, longitude: 114.1881),
        "大圍": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1800),
        "Tai Wai": CLLocationCoordinate2D(latitude: 22.3481, longitude: 114.1800),
        "大埔": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.1681),
        "Tai Po": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.1681),
        "上水": CLLocationCoordinate2D(latitude: 22.5031, longitude: 114.1281),
        "Sheung Shui": CLLocationCoordinate2D(latitude: 22.5031, longitude: 114.1281),
        "粉嶺": CLLocationCoordinate2D(latitude: 22.4931, longitude: 114.1431),
        "Fanling": CLLocationCoordinate2D(latitude: 22.4931, longitude: 114.1431),
        "屯門": CLLocationCoordinate2D(latitude: 22.3931, longitude: 113.9750),
        "Tuen Mun": CLLocationCoordinate2D(latitude: 22.3931, longitude: 113.9750),
        "元朗": CLLocationCoordinate2D(latitude: 22.4431, longitude: 114.0331),
        "Yuen Long": CLLocationCoordinate2D(latitude: 22.4431, longitude: 114.0331),
        "天水圍": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0031),
        "Tin Shui Wai": CLLocationCoordinate2D(latitude: 22.4481, longitude: 114.0031),
        "荃灣": CLLocationCoordinate2D(latitude: 22.3706, longitude: 114.1131),
        "Tsuen Wan": CLLocationCoordinate2D(latitude: 22.3706, longitude: 114.1131),
        "葵涌": CLLocationCoordinate2D(latitude: 22.3656, longitude: 114.1300),
        "Kwai Chung": CLLocationCoordinate2D(latitude: 22.3656, longitude: 114.1300),
        "青衣": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1081),
        "Tsing Yi": CLLocationCoordinate2D(latitude: 22.3581, longitude: 114.1081),
        "東涌": CLLocationCoordinate2D(latitude: 22.2881, longitude: 113.9431),
        "Tung Chung": CLLocationCoordinate2D(latitude: 22.2881, longitude: 113.9431),
    ]
    
    /// Calculate distance from current location to a station
    static func distance(from location: CLLocation, to stationName: String) -> Double? {
        guard let stationCoord = mtrStations[stationName] else { return nil }
        let stationLocation = CLLocation(
            latitude: stationCoord.latitude,
            longitude: stationCoord.longitude
        )
        return location.distance(from: stationLocation) / 1000.0 // Convert to km
    }
    
    /// Get nearby MTR stations sorted by distance
    static func nearbyMTRStations(from location: CLLocation, limit: Int = 5, preferChinese: Bool = true) -> [(name: String, distance: Double)] {
        // Group stations by coordinates to handle same station with different names
        // Use string key for coordinates since CLLocationCoordinate2D is not Hashable
        var coordinateToStations: [String: [(name: String, distance: Double)]] = [:]
        
        for (name, coordinate) in mtrStations {
            let stationLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            let distance = location.distance(from: stationLocation) / 1000.0 // Convert to km
            
            // Round coordinates to avoid floating point precision issues and use as key
            let roundedLat = round(coordinate.latitude * 10000) / 10000
            let roundedLon = round(coordinate.longitude * 10000) / 10000
            let coordKey = "\(roundedLat),\(roundedLon)"
            
            if coordinateToStations[coordKey] == nil {
                coordinateToStations[coordKey] = []
            }
            coordinateToStations[coordKey]?.append((name: name, distance: distance))
        }
        
        // For each coordinate, pick the best name based on language preference
        var uniqueStations: [(name: String, distance: Double)] = []
        for (_, stationList) in coordinateToStations {
            // Find the minimum distance for this coordinate
            let minDistance = stationList.map { $0.distance }.min() ?? 0
            
            // Choose name based on language preference
            let preferredName: String
            if preferChinese {
                // Prefer Traditional Chinese name, fallback to English
                preferredName = stationList.first { station in
                    // Check if name contains Chinese characters
                    station.name.unicodeScalars.contains { scalar in
                        (0x4E00...0x9FFF).contains(scalar.value) ||
                        (0x3400...0x4DBF).contains(scalar.value)
                    }
                }?.name ?? stationList.first?.name ?? ""
            } else {
                // Prefer English name, fallback to Chinese
                preferredName = stationList.first { station in
                    // Check if name does NOT contain Chinese characters
                    !station.name.unicodeScalars.contains { scalar in
                        (0x4E00...0x9FFF).contains(scalar.value) ||
                        (0x3400...0x4DBF).contains(scalar.value)
                    }
                }?.name ?? stationList.first?.name ?? ""
            }
            
            if !preferredName.isEmpty {
                uniqueStations.append((name: preferredName, distance: minDistance))
            }
        }
        
        return uniqueStations
            .sorted { $0.distance < $1.distance }
            .prefix(limit)
            .map { (name: $0.name, distance: $0.distance) }
    }
    
    /// Get nearby bus stations sorted by distance
    static func nearbyBusStations(from location: CLLocation, limit: Int = 3, preferChinese: Bool = true) -> [(name: String, distance: Double)] {
        // Group stations by coordinates to handle same station with different names
        // Use string key for coordinates since CLLocationCoordinate2D is not Hashable
        var coordinateToStations: [String: [(name: String, distance: Double)]] = [:]
        
        for (name, coordinate) in busStations {
            let stationLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            let distance = location.distance(from: stationLocation) / 1000.0 // Convert to km
            
            // Round coordinates to avoid floating point precision issues and use as key
            let roundedLat = round(coordinate.latitude * 10000) / 10000
            let roundedLon = round(coordinate.longitude * 10000) / 10000
            let coordKey = "\(roundedLat),\(roundedLon)"
            
            if coordinateToStations[coordKey] == nil {
                coordinateToStations[coordKey] = []
            }
            coordinateToStations[coordKey]?.append((name: name, distance: distance))
        }
        
        // For each coordinate, pick the best name (prefer Traditional Chinese)
        var uniqueStations: [(name: String, distance: Double)] = []
        for (_, stationList) in coordinateToStations {
            // Find the minimum distance for this coordinate
            let minDistance = stationList.map { $0.distance }.min() ?? 0
            
            // Choose name based on language preference
            let preferredName: String
            if preferChinese {
                // Prefer Traditional Chinese name, fallback to English
                preferredName = stationList.first { station in
                    // Check if name contains Chinese characters
                    station.name.unicodeScalars.contains { scalar in
                        (0x4E00...0x9FFF).contains(scalar.value) ||
                        (0x3400...0x4DBF).contains(scalar.value)
                    }
                }?.name ?? stationList.first?.name ?? ""
            } else {
                // Prefer English name, fallback to Chinese
                preferredName = stationList.first { station in
                    // Check if name does NOT contain Chinese characters
                    !station.name.unicodeScalars.contains { scalar in
                        (0x4E00...0x9FFF).contains(scalar.value) ||
                        (0x3400...0x4DBF).contains(scalar.value)
                    }
                }?.name ?? stationList.first?.name ?? ""
            }
            
            if !preferredName.isEmpty {
                uniqueStations.append((name: preferredName, distance: minDistance))
            }
        }
        
        return uniqueStations
            .sorted { $0.distance < $1.distance }
            .prefix(limit)
            .map { (name: $0.name, distance: $0.distance) }
    }
}

