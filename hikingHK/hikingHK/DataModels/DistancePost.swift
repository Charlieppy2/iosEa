//
//  DistancePost.swift
//  hikingHK
//
//  Created for distance post (標距柱) functionality
//

import Foundation
import MapKit

/// Represents a distance post marker along a hiking trail or mountain bike trail.
struct DistancePost: Identifiable, Codable {
    let id: UUID
    let postNumber: String  // 標距柱編號，例如 "M001", "M002"
    let coordinate: CLLocationCoordinate2D
    let distanceFromStart: Double  // 距離起點的距離（公里）
    let trailName: String?  // 所屬路線名稱（可選）
    let trailId: UUID?  // 所屬路線 ID（可選）
    
    init(
        id: UUID = UUID(),
        postNumber: String,
        coordinate: CLLocationCoordinate2D,
        distanceFromStart: Double,
        trailName: String? = nil,
        trailId: UUID? = nil
    ) {
        self.id = id
        self.postNumber = postNumber
        self.coordinate = coordinate
        self.distanceFromStart = distanceFromStart
        self.trailName = trailName
        self.trailId = trailId
    }
}

// MARK: - Codable Support for CLLocationCoordinate2D

extension DistancePost {
    enum CodingKeys: String, CodingKey {
        case id
        case postNumber
        case latitude
        case longitude
        case distanceFromStart
        case trailName
        case trailId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        postNumber = try container.decode(String.self, forKey: .postNumber)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        distanceFromStart = try container.decode(Double.self, forKey: .distanceFromStart)
        trailName = try container.decodeIfPresent(String.self, forKey: .trailName)
        trailId = try container.decodeIfPresent(UUID.self, forKey: .trailId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(postNumber, forKey: .postNumber)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(distanceFromStart, forKey: .distanceFromStart)
        try container.encodeIfPresent(trailName, forKey: .trailName)
        try container.encodeIfPresent(trailId, forKey: .trailId)
    }
}

