//
//  CSDIGeoportalService.swift
//  hikingHK
//
//  Created for CSDI Geoportal API integration
//

import Foundation

/// Abstraction for fetching trail data from the CSDI Geoportal service.
protocol CSDIGeoportalServiceProtocol {
    func fetchTrailData(datasetId: String, language: String) async throws -> Data
    func fetchTrails(datasetId: String, language: String) async throws -> [Trail]
}

struct CSDIGeoportalService: CSDIGeoportalServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private let baseEndpoint = "https://portal.csdi.gov.hk/geoportal/?datasetId="
    
    // Known dataset IDs
    enum DatasetID: String {
        case afcdTrails1 = "afcd_rcd_1665568199103_4360"
        case afcdTrails2 = "afcd_rcd_1635136039113_86105"
        case casTrails = "cas_rcd_1640314527589_15538"
    }
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    private func endpointURL(datasetId: String, language: String) -> URL {
        let langCode = language == "zh-Hant" ? "zh-hk" : "en"
        return URL(string: "\(baseEndpoint)\(datasetId)&lang=\(langCode)")!
    }
    
    func fetchTrailData(datasetId: String, language: String = "en") async throws -> Data {
        let endpoint = endpointURL(datasetId: datasetId, language: language)
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CSDIGeoportalServiceError.invalidResponse("Invalid response type")
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = "HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                print("❌ CSDIGeoportalService: API returned status \(httpResponse.statusCode) for dataset \(datasetId)")
                throw CSDIGeoportalServiceError.invalidResponse(errorMessage)
            }
            
            // Check if data is empty
            guard !data.isEmpty else {
                throw CSDIGeoportalServiceError.invalidResponse("Empty response from API")
            }
            
            // Check if response is HTML instead of JSON (common issue with CSDI Geoportal)
            if let dataString = String(data: data.prefix(100), encoding: .utf8),
               dataString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE") ||
               dataString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<html") {
                throw CSDIGeoportalServiceError.invalidResponse("API returned HTML instead of JSON. The endpoint may have changed or requires authentication.")
            }
            
            return data
        } catch let error as CSDIGeoportalServiceError {
            // Re-throw our custom errors
            throw error
        } catch {
            // Handle network errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw CSDIGeoportalServiceError.networkError("No internet connection")
                case .timedOut:
                    throw CSDIGeoportalServiceError.networkError("Request timed out")
                case .cannotFindHost, .cannotConnectToHost:
                    throw CSDIGeoportalServiceError.networkError("Cannot connect to CSDI Geoportal server")
                default:
                    throw CSDIGeoportalServiceError.networkError(urlError.localizedDescription)
                }
            }
            throw CSDIGeoportalServiceError.networkError(error.localizedDescription)
        }
    }
    
    func fetchTrails(datasetId: String, language: String = "en") async throws -> [Trail] {
        let data = try await fetchTrailData(datasetId: datasetId, language: language)
        return try CSDITrailParser.parseTrails(from: data, language: language)
    }
    
    func fetchAllTrailDatasets(language: String = "en") async throws -> [String: Data] {
        var results: [String: Data] = [:]
        
        let datasetIds = [
            DatasetID.afcdTrails1.rawValue,
            DatasetID.afcdTrails2.rawValue,
            DatasetID.casTrails.rawValue
        ]
        
        for datasetId in datasetIds {
            do {
                let data = try await fetchTrailData(datasetId: datasetId, language: language)
                results[datasetId] = data
            } catch {
                print("Failed to fetch dataset \(datasetId): \(error)")
                // Continue with other datasets even if one fails
            }
        }
        
        return results
    }
    
    /// Fetches trails from all known datasets and combines them.
    func fetchAllTrails(language: String = "en") async throws -> [Trail] {
        var allTrails: [Trail] = []
        
        let datasetIds = [
            DatasetID.afcdTrails1.rawValue,
            DatasetID.afcdTrails2.rawValue,
            DatasetID.casTrails.rawValue
        ]
        
        for datasetId in datasetIds {
            do {
                let trails = try await fetchTrails(datasetId: datasetId, language: language)
                allTrails.append(contentsOf: trails)
                print("✅ CSDIGeoportalService: Loaded \(trails.count) trails from dataset \(datasetId)")
            } catch {
                print("⚠️ CSDIGeoportalService: Failed to load trails from dataset \(datasetId): \(error)")
                // Continue with other datasets even if one fails
            }
        }
        
        return allTrails
    }
}

enum CSDIGeoportalServiceError: Error, LocalizedError {
    case invalidResponse(String)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid API response: \(message)"
        case .decodingError(let message):
            return "Failed to parse data: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
    
    var localizedDescription: String {
        return errorDescription ?? "Unknown error"
    }
}

