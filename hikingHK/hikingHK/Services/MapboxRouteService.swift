//
//  MapboxRouteService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import MapKit

/// Service responsible for requesting walking routes from Mapbox Directions.
struct MapboxRouteService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let accessToken: String

    /// Initialize the service with an access token and injectable URLSession / JSONDecoder.
    init(
        accessToken: String = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] ?? "",
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.accessToken = accessToken
        self.session = session
        self.decoder = decoder
    }

    /// Indicates whether a non-empty Mapbox access token is available.
    var isConfigured: Bool {
        !accessToken.isEmpty
    }

    /// Fetch a walking route polyline between two coordinates using Mapbox Directions.
    func fetchRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> MKPolyline? {
        guard isConfigured else { return nil }
        let coordinates = "\(start.longitude),\(start.latitude);\(end.longitude),\(end.latitude)"
        var components = URLComponents(string: "https://api.mapbox.com/directions/v5/mapbox/walking/\(coordinates)")!
        components.queryItems = [
            URLQueryItem(name: "geometries", value: "geojson"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]

        guard let url = components.url else {
            throw RouteServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw RouteServiceError.invalidResponse
        }

        let decoded = try decoder.decode(MapboxDirectionsResponse.self, from: data)
        guard let firstRoute = decoded.routes.first else {
            throw RouteServiceError.missingRoute
        }

        let coords = firstRoute.geometry.coordinates.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        return MKPolyline(coordinates: coords, count: coords.count)
    }
}

enum RouteServiceError: Error {
    case invalidURL
    case invalidResponse
    case missingRoute
}

// MARK: - DTO

struct MapboxDirectionsResponse: Decodable {
    let routes: [Route]

    struct Route: Decodable {
        let geometry: Geometry
    }

    struct Geometry: Decodable {
        let coordinates: [[Double]]
    }
}

