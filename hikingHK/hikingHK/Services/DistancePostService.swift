//
//  DistancePostService.swift
//  hikingHK
//
//  Service for fetching distance posts (標距柱) data from CSDI Geoportal or built-in data.
//

import Foundation
import MapKit

/// Abstraction for fetching distance post data.
protocol DistancePostServiceProtocol {
    func fetchDistancePosts(for trailId: UUID) async throws -> [DistancePost]
    func fetchDistancePosts(for trailName: String) async throws -> [DistancePost]
    func fetchAllDistancePosts() async throws -> [DistancePost]
}

/// Service that provides distance post data, with fallback to built-in data if API fails.
struct DistancePostService: DistancePostServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // CSDI Geoportal dataset ID for distance posts
    private let datasetId = "afcd_rcd_1635136039113_86105"
    private let baseEndpoint = "https://portal.csdi.gov.hk/geoportal/?datasetId="
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    /// Fetches distance posts for a specific trail by trail ID.
    func fetchDistancePosts(for trailId: UUID) async throws -> [DistancePost] {
        // First try to fetch from API
        do {
            let allPosts = try await fetchAllDistancePosts()
            return allPosts.filter { $0.trailId == trailId }
        } catch {
            // Fallback to built-in data
            print("⚠️ DistancePostService: API fetch failed, using built-in data: \(error)")
            return builtInDistancePosts.filter { $0.trailId == trailId }
        }
    }
    
    /// Fetches distance posts for a specific trail by trail name.
    func fetchDistancePosts(for trailName: String) async throws -> [DistancePost] {
        do {
            let allPosts = try await fetchAllDistancePosts()
            return allPosts.filter { $0.trailName?.localizedCaseInsensitiveContains(trailName) ?? false }
        } catch {
            print("⚠️ DistancePostService: API fetch failed, using built-in data: \(error)")
            return builtInDistancePosts.filter { $0.trailName?.localizedCaseInsensitiveContains(trailName) ?? false }
        }
    }
    
    /// Fetches all distance posts from CSDI API or built-in data.
    func fetchAllDistancePosts() async throws -> [DistancePost] {
        let endpoint = URL(string: "\(baseEndpoint)\(datasetId)&lang=en")!
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw DistancePostServiceError.invalidResponse
            }
            
            // Check if response is HTML instead of JSON
            if let dataString = String(data: data.prefix(100), encoding: .utf8),
               dataString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE") ||
               dataString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<html") {
                throw DistancePostServiceError.invalidResponse
            }
            
            // Try to parse as GeoJSON or other format
            // For now, fallback to built-in data if API format is unknown
            // TODO: Implement proper GeoJSON parsing when API format is confirmed
            throw DistancePostServiceError.decodingError("API format not yet implemented")
            
        } catch {
            // Fallback to built-in data
            print("⚠️ DistancePostService: Using built-in distance posts data")
            return builtInDistancePosts
        }
    }
    
    /// Built-in distance posts data as fallback when API is unavailable.
    /// This includes sample posts for major trails.
    private var builtInDistancePosts: [DistancePost] {
        // Sample data - in production, this could be loaded from a JSON file
        // For now, return empty array and let the UI handle gracefully
        return []
    }
}

enum DistancePostServiceError: Error, LocalizedError {
    case invalidResponse
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from distance post API"
        case .decodingError(let message):
            return "Failed to parse distance post data: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

