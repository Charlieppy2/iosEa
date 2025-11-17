//
//  OfflineMapsDownloadService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

protocol OfflineMapsDownloadServiceProtocol {
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws
    func getEstimatedSize(for region: String) -> Int64
}

struct OfflineMapsDownloadService: OfflineMapsDownloadServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getEstimatedSize(for region: String) -> Int64 {
        // Estimated sizes in bytes (simulated)
        let sizes: [String: Int64] = [
            "Hong Kong Island": 45 * 1024 * 1024, // 45 MB
            "Kowloon Ridge": 38 * 1024 * 1024,    // 38 MB
            "Sai Kung East": 52 * 1024 * 1024,    // 52 MB
            "Lantau North": 48 * 1024 * 1024      // 48 MB
        ]
        return sizes[region] ?? 40 * 1024 * 1024
    }
    
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws {
        // Simulate download with progress updates
        // In a real implementation, this would download actual map tiles
        let totalSize = getEstimatedSize(for: region.name)
        var downloaded: Int64 = 0
        let chunkSize: Int64 = 1024 * 1024 // 1 MB chunks
        
        // Simulate download progress
        while downloaded < totalSize {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            
            downloaded = min(downloaded + chunkSize, totalSize)
            let progress = Double(downloaded) / Double(totalSize)
            
            progressHandler(progress, downloaded, totalSize)
        }
        
        // Simulate a small chance of failure for testing
        if Int.random(in: 1...20) == 1 {
            throw OfflineMapsDownloadError.downloadFailed
        }
    }
}

enum OfflineMapsDownloadError: Error {
    case downloadFailed
    case invalidRegion
    case insufficientStorage
}

