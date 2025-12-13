//
//  CSDIGeoportalService.swift
//  hikingHK
//
//  Created for CSDI Geoportal API integration
//

import Foundation

protocol CSDIGeoportalServiceProtocol {
    func fetchTrailData(datasetId: String, language: String) async throws -> Data
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
        let (data, response) = try await session.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw CSDIGeoportalServiceError.invalidResponse
        }
        
        return data
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
}

enum CSDIGeoportalServiceError: Error {
    case invalidResponse
    case decodingError
    case networkError
}

