//
//  Landmark.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import CoreLocation

/// Static geographic landmark used for AR overlays and map annotations.
struct Landmark: Identifiable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let elevation: Int // meters
    let description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        elevation: Int,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.elevation = elevation
        self.description = description
    }
    
    static func == (lhs: Landmark, rhs: Landmark) -> Bool {
        lhs.id == rhs.id
    }
    
    func distance(from location: CLLocation) -> Double {
        let landmarkLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: landmarkLocation) / 1000.0 // Convert to km
    }
    
    func bearing(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let dLon = (coordinate.longitude - location.coordinate.longitude) * .pi / 180
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Landmark {
    static let hongKongLandmarks: [Landmark] = [
        Landmark(
            name: "Lion Rock",
            coordinate: CLLocationCoordinate2D(latitude: 22.3500, longitude: 114.1833),
            elevation: 495,
            description: "Iconic peak offering panoramic views of Kowloon and Hong Kong Island"
        ),
        Landmark(
            name: "Sharp Peak",
            coordinate: CLLocationCoordinate2D(latitude: 22.3833, longitude: 114.3667),
            elevation: 468,
            description: "Dramatic pyramid-shaped peak in Sai Kung East Country Park"
        ),
        Landmark(
            name: "Tai Mo Shan",
            coordinate: CLLocationCoordinate2D(latitude: 22.4083, longitude: 114.1233),
            elevation: 957,
            description: "Hong Kong's highest peak, often shrouded in mist"
        ),
        Landmark(
            name: "Sunset Peak",
            coordinate: CLLocationCoordinate2D(latitude: 22.2667, longitude: 113.9833),
            elevation: 869,
            description: "Second highest peak on Lantau Island, famous for sunrise views"
        ),
        Landmark(
            name: "Lantau Peak",
            coordinate: CLLocationCoordinate2D(latitude: 22.2583, longitude: 113.9500),
            elevation: 934,
            description: "Highest peak on Lantau Island, challenging ascent"
        ),
        Landmark(
            name: "Ma On Shan",
            coordinate: CLLocationCoordinate2D(latitude: 22.4000, longitude: 114.2500),
            elevation: 702,
            description: "Prominent peak in the New Territories with iron-rich red rocks"
        )
    ]
}

