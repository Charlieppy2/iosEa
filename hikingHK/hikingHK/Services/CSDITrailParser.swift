//
//  CSDITrailParser.swift
//  hikingHK
//
//  Created for parsing CSDI Geoportal API trail data
//

import Foundation
import MapKit

/// Parser for converting CSDI Geoportal API responses into Trail models.
struct CSDITrailParser {
    /// Parses CSDI Geoportal API response data into Trail models.
    /// - Parameters:
    ///   - data: Raw JSON data from the API
    ///   - language: Language code for localized content
    /// - Returns: Array of Trail models
    static func parseTrails(from data: Data, language: String = "en") throws -> [Trail] {
        // Try to parse as GeoJSON format first
        if let geoJSON = try? JSONDecoder().decode(GeoJSONResponse.self, from: data) {
            return geoJSON.toTrails(language: language)
        }
        
        // Try to parse as simple JSON array
        if let features = try? JSONDecoder().decode([CSDITrailFeature].self, from: data) {
            return features.compactMap { $0.toTrail(language: language) }
        }
        
        // Try to parse as GeoJSON FeatureCollection
        if let featureCollection = try? JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data) {
            return featureCollection.features.compactMap { $0.toTrail(language: language) }
        }
        
        // Try to get a sample of the data for debugging
        let dataPreview = String(data: data.prefix(200), encoding: .utf8) ?? "Unable to decode data preview"
        throw CSDIGeoportalServiceError.decodingError("Unable to parse trail data. Data preview: \(dataPreview)")
    }
}

// MARK: - GeoJSON Models

/// GeoJSON Feature Collection structure
struct GeoJSONFeatureCollection: Codable {
    let type: String
    let features: [GeoJSONFeature]
}

/// GeoJSON Feature structure
struct GeoJSONFeature: Codable {
    let type: String
    let properties: [String: AnyCodable]
    let geometry: GeoJSONGeometry?
    
    func toTrail(language: String) -> Trail? {
        guard let name = properties["name"]?.stringValue ?? properties["NAME"]?.stringValue ?? properties["Name"]?.stringValue else {
            return nil
        }
        
        // Extract properties
        let district = properties["district"]?.stringValue ?? properties["DISTRICT"]?.stringValue ?? properties["District"]?.stringValue ?? "Unknown"
        let lengthKm = properties["length"]?.doubleValue ?? properties["LENGTH"]?.doubleValue ?? properties["Length"]?.doubleValue ?? 0.0
        let difficulty = parseDifficulty(from: properties)
        
        // Calculate map center from geometry
        let mapCenter = geometry?.center ?? CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694) // Default to HK center
        let routeCoordinates = geometry?.toTrailCoordinates() ?? []
        
        // Estimate duration based on length (assuming average speed of 3 km/h)
        let estimatedDurationMinutes = Int((lengthKm / 3.0) * 60)
        
        // Create summary from available properties
        let summary = properties["description"]?.stringValue ?? 
                     properties["DESCRIPTION"]?.stringValue ?? 
                     properties["summary"]?.stringValue ?? 
                     "A hiking trail in \(district)"
        
        return Trail(
            id: UUID(),
            name: name,
            district: district,
            difficulty: difficulty,
            lengthKm: lengthKm,
            elevationGain: properties["elevation"]?.intValue ?? properties["ELEVATION"]?.intValue ?? 0,
            estimatedDurationMinutes: estimatedDurationMinutes,
            summary: summary,
            highlights: extractHighlights(from: properties),
            facilities: [],
            transportation: properties["transportation"]?.stringValue ?? properties["TRANSPORTATION"]?.stringValue ?? "",
            imageName: "trail_default",
            isFavorite: false,
            checkpoints: [],
            mapCenter: mapCenter,
            mapSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1),
            routeCoordinates: routeCoordinates
        )
    }
    
    private func parseDifficulty(from properties: [String: AnyCodable]) -> Trail.Difficulty {
        let difficultyStr = properties["difficulty"]?.stringValue ?? 
                           properties["DIFFICULTY"]?.stringValue ?? 
                           properties["level"]?.stringValue ?? 
                           ""
        
        switch difficultyStr.lowercased() {
        case "easy", "1", "初級", "easy":
            return .easy
        case "moderate", "2", "中級", "medium":
            return .moderate
        case "challenging", "hard", "3", "高級", "difficult":
            return .challenging
        default:
            // Default to moderate if unknown
            return .moderate
        }
    }
    
    private func extractHighlights(from properties: [String: AnyCodable]) -> [String] {
        var highlights: [String] = []
        
        if let highlight = properties["highlight"]?.stringValue {
            highlights.append(highlight)
        }
        if let features = properties["features"]?.stringValue {
            highlights.append(features)
        }
        
        return highlights.isEmpty ? ["Scenic views", "Country park trail"] : highlights
    }
}

/// GeoJSON Geometry structure
struct GeoJSONGeometry: Codable {
    let type: String
    let coordinates: AnyCodable
    
    var center: CLLocationCoordinate2D {
        switch type {
        case "Point":
            if let coords = coordinates.arrayValue, coords.count >= 2 {
                let lon = coords[0].doubleValue ?? 0
                let lat = coords[1].doubleValue ?? 0
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        case "LineString", "MultiLineString":
            return calculateLineStringCenter()
        case "Polygon", "MultiPolygon":
            return calculatePolygonCenter()
        default:
            break
        }
        return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
    }
    
    func toTrailCoordinates() -> [Trail.TrailCoordinate] {
        var coords: [Trail.TrailCoordinate] = []
        
        switch type {
        case "LineString":
            if let lineCoords = coordinates.arrayValue {
                coords = parseCoordinateArray(lineCoords)
            }
        case "MultiLineString":
            if let multiCoords = coordinates.arrayValue {
                for line in multiCoords {
                    if let lineArray = line.arrayValue {
                        coords.append(contentsOf: parseCoordinateArray(lineArray))
                    }
                }
            }
        case "Polygon":
            if let polygonCoords = coordinates.arrayValue, 
               let firstRing = polygonCoords.first,
               let firstRingArray = firstRing.arrayValue {
                coords = parseCoordinateArray(firstRingArray)
            }
        default:
            break
        }
        
        return coords
    }
    
    private func parseCoordinateArray(_ array: [AnyCodable]) -> [Trail.TrailCoordinate] {
        return array.compactMap { coord in
            // Handle nested arrays (coordinates are typically [lon, lat] or [lat, lon])
            if let coordArray = coord.arrayValue, coordArray.count >= 2 {
                let first = coordArray[0].doubleValue ?? 0
                let second = coordArray[1].doubleValue ?? 0
                // Determine order: if first > 90, it's likely longitude (HK is around 114)
                let lat = (first > 90 || first < -90) ? second : first
                let lon = (first > 90 || first < -90) ? first : second
                return Trail.TrailCoordinate(latitude: lat, longitude: lon)
            }
            // Handle direct coordinate values
            if let dict = coord.dictionaryValue {
                if let lat = dict["lat"]?.doubleValue ?? dict["latitude"]?.doubleValue,
                   let lon = dict["lon"]?.doubleValue ?? dict["longitude"]?.doubleValue {
                    return Trail.TrailCoordinate(latitude: lat, longitude: lon)
                }
            }
            return nil
        }
    }
    
    private func calculateLineStringCenter() -> CLLocationCoordinate2D {
        guard let coords = coordinates.arrayValue else {
            return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        }
        
        let trailCoords = parseCoordinateArray(coords)
        guard !trailCoords.isEmpty else {
            return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        }
        
        let midIndex = trailCoords.count / 2
        return trailCoords[midIndex].location
    }
    
    private func calculatePolygonCenter() -> CLLocationCoordinate2D {
        guard let polygonCoords = coordinates.arrayValue,
              let firstRing = polygonCoords.first,
              let firstRingArray = firstRing.arrayValue else {
            return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        }
        
        let trailCoords = parseCoordinateArray(firstRingArray)
        guard !trailCoords.isEmpty else {
            return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        }
        
        // Calculate centroid
        let sumLat = trailCoords.reduce(0.0) { $0 + $1.latitude }
        let sumLon = trailCoords.reduce(0.0) { $0 + $1.longitude }
        let count = Double(trailCoords.count)
        
        return CLLocationCoordinate2D(
            latitude: sumLat / count,
            longitude: sumLon / count
        )
    }
}

/// Alternative simple feature structure
struct CSDITrailFeature: Codable {
    let name: String?
    let district: String?
    let length: Double?
    let difficulty: String?
    let description: String?
    let geometry: [Double]?
    
    func toTrail(language: String) -> Trail? {
        guard let name = name else { return nil }
        
        let difficulty = parseDifficulty(from: difficulty ?? "")
        let lengthKm = length ?? 0.0
        let district = district ?? "Unknown"
        
        // Parse geometry if available (assuming [lat, lon] or [lon, lat] format)
        var mapCenter = CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        if let geom = geometry, geom.count >= 2 {
            // Try both orders
            mapCenter = CLLocationCoordinate2D(
                latitude: geom[0] > 90 ? geom[1] : geom[0], // If first > 90, it's probably lon
                longitude: geom[0] > 90 ? geom[0] : geom[1]
            )
        }
        
        return Trail(
            id: UUID(),
            name: name,
            district: district,
            difficulty: difficulty,
            lengthKm: lengthKm,
            elevationGain: 0,
            estimatedDurationMinutes: Int((lengthKm / 3.0) * 60),
            summary: description ?? "A hiking trail in \(district)",
            highlights: [],
            facilities: [],
            transportation: "",
            imageName: "trail_default",
            isFavorite: false,
            checkpoints: [],
            mapCenter: mapCenter,
            routeCoordinates: []
        )
    }
    
    private func parseDifficulty(from str: String) -> Trail.Difficulty {
        switch str.lowercased() {
        case "easy", "1", "初級":
            return .easy
        case "moderate", "2", "中級", "medium":
            return .moderate
        case "challenging", "hard", "3", "高級", "difficult":
            return .challenging
        default:
            return .moderate
        }
    }
}

/// Generic GeoJSON response wrapper
struct GeoJSONResponse: Codable {
    let type: String?
    let features: [GeoJSONFeature]?
    
    func toTrails(language: String) -> [Trail] {
        return features?.compactMap { $0.toTrail(language: language) } ?? []
    }
}

// MARK: - AnyCodable Helper

/// Helper type for decoding dynamic JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [AnyCodable]:
            try container.encode(array)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
    
    var stringValue: String? {
        value as? String
    }
    
    var intValue: Int? {
        if let int = value as? Int {
            return int
        }
        if let double = value as? Double {
            return Int(double)
        }
        return nil
    }
    
    var doubleValue: Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        return nil
    }
    
    var arrayValue: [AnyCodable]? {
        value as? [AnyCodable]
    }
    
    var dictionaryValue: [String: AnyCodable]? {
        value as? [String: AnyCodable]
    }
}

