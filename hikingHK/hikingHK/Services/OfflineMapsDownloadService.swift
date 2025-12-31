//
//  OfflineMapsDownloadService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import MapKit
import UIKit

/// Abstraction for downloading, estimating and managing offline map regions on disk.
protocol OfflineMapsDownloadServiceProtocol {
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws
    func getEstimatedSize(for region: String) -> Int64
    func isRegionDownloaded(_ region: OfflineMapRegion) -> Bool
    func deleteRegionData(_ region: OfflineMapRegion) throws
}

/// Concrete implementation that generates map snapshots and metadata
/// for predefined regions so they can be used completely offline.
struct OfflineMapsDownloadService: OfflineMapsDownloadServiceProtocol {
    private let session: URLSession
    private let fileManager = FileManager.default
    
    /// Root directory where all offline map data is stored (Documents/OfflineMaps).
    private var offlineMapsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mapsDir = documentsPath.appendingPathComponent("OfflineMaps", isDirectory: true)
        
        // Ensure the directory exists
        if !fileManager.fileExists(atPath: mapsDir.path) {
            try? fileManager.createDirectory(at: mapsDir, withIntermediateDirectories: true)
        }
        
        return mapsDir
    }
    
    /// Generates a stable and filesystem-safe subdirectory name.
    /// Uses the region name instead of the UUID so that even if SwiftData recreates
    /// `OfflineMapRegion` objects, previously downloaded offline maps can still be found.
    private func directoryName(for region: OfflineMapRegion) -> String {
        // Region names currently only contain English and spaces, so replacing spaces is enough.
        return region.name.replacingOccurrences(of: " ", with: "_")
    }
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Roughly estimates the download size for a given region name.
    func getEstimatedSize(for region: String) -> Int64 {
        // Estimate based on multiple zoom levels of map tiles for the region
        let baseSize: Int64 = 5 * 1024 * 1024 // Around 5MB per zoom level
        let zoomLevels = 5 // Download 5 zoom levels
        
        let regionMultiplier: [String: Double] = [
            "Hong Kong Island": 1.0,
            "Kowloon Ridge": 0.85,
            "Sai Kung East": 1.2,
            "Sai Kung West": 1.1,
            "Lantau North": 1.1,
            "Lantau South": 1.3,
            "New Territories Central": 1.0,
            "New Territories West": 1.15,
            "New Territories East": 1.2,
            "Tai Mo Shan Area": 0.9,
            "Pat Sin Leng": 1.0,
            "MacLehose Trail Sections": 1.5
        ]
        
        let multiplier = regionMultiplier[region] ?? 1.0
        return Int64(Double(baseSize * Int64(zoomLevels)) * multiplier)
    }
    
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws {
        let totalSize = getEstimatedSize(for: region.name)
        var downloaded: Int64 = 0
        let coordinateRegion = region.coordinateRegion
        
        // Create a folder for this region using a stable name instead of the UUID
        let regionDir = offlineMapsDirectory.appendingPathComponent(directoryName(for: region), isDirectory: true)
        if !fileManager.fileExists(atPath: regionDir.path) {
            try fileManager.createDirectory(at: regionDir, withIntermediateDirectories: true)
        }
        
        // Save region metadata as JSON
        let metadata = [
            "name": region.name,
            "centerLat": String(coordinateRegion.center.latitude),
            "centerLon": String(coordinateRegion.center.longitude),
            "spanLat": String(coordinateRegion.span.latitudeDelta),
            "spanLon": String(coordinateRegion.span.longitudeDelta),
            "downloadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        let metadataPath = regionDir.appendingPathComponent("metadata.json")
        if let metadataData = try? JSONSerialization.data(withJSONObject: metadata) {
            try? metadataData.write(to: metadataPath)
            downloaded += Int64(metadataData.count)
        }
        
        // Download map snapshots across several zoom levels
        let zoomLevels: [Double] = [0.05, 0.02, 0.01, 0.005, 0.002] // Different zoom levels for coverage
        let snapshotsPerLevel = 4 // Generate 4 snapshots per level to cover the whole region
        
        for (levelIndex, zoomLevel) in zoomLevels.enumerated() {
            let span = MKCoordinateSpan(
                latitudeDelta: coordinateRegion.span.latitudeDelta * zoomLevel,
                longitudeDelta: coordinateRegion.span.longitudeDelta * zoomLevel
            )
            
            // For each zoom level, generate multiple snapshots to cover the entire region
            for snapshotIndex in 0..<snapshotsPerLevel {
                let offsetLat = (Double(snapshotIndex / 2) - 0.5) * coordinateRegion.span.latitudeDelta * 0.3
                let offsetLon = (Double(snapshotIndex % 2) - 0.5) * coordinateRegion.span.longitudeDelta * 0.3
                
                let center = CLLocationCoordinate2D(
                    latitude: coordinateRegion.center.latitude + offsetLat,
                    longitude: coordinateRegion.center.longitude + offsetLon
                )
                
                let snapshotRegion = MKCoordinateRegion(center: center, span: span)
                
                // Generate a map snapshot for this region slice
                let options = MKMapSnapshotter.Options()
                options.region = snapshotRegion
                options.size = CGSize(width: 1024, height: 1024)
                options.scale = UIScreen.main.scale
                options.mapType = .standard
                
                let snapshotter = MKMapSnapshotter(options: options)
                
                do {
                    let snapshot = try await snapshotter.start()
                    
                    // Persist the snapshot image to disk
                    let imageData = snapshot.image.pngData()
                    let imagePath = regionDir.appendingPathComponent("snapshot_\(levelIndex)_\(snapshotIndex).png")
                    try imageData?.write(to: imagePath)
                    
                    if let data = imageData {
                        downloaded += Int64(data.count)
                    }
                    
                    // Update overall download progress
                    let progress = Double(downloaded) / Double(totalSize)
                    progressHandler(min(progress, 0.99), downloaded, totalSize)
                    
                    // Add a small delay to avoid sending snapshot requests too quickly
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                } catch {
                    print("Failed to generate snapshot for level \(levelIndex), snapshot \(snapshotIndex): \(error)")
                    // Continue with remaining snapshots without cancelling the whole download
                }
            }
        }
        
        // Mark the download as completed
        progressHandler(1.0, totalSize, totalSize)
    }
    
    func isRegionDownloaded(_ region: OfflineMapRegion) -> Bool {
        let regionDir = offlineMapsDirectory.appendingPathComponent(directoryName(for: region), isDirectory: true)
        return fileManager.fileExists(atPath: regionDir.path) &&
               fileManager.fileExists(atPath: regionDir.appendingPathComponent("metadata.json").path)
    }
    
    func deleteRegionData(_ region: OfflineMapRegion) throws {
        let regionDir = offlineMapsDirectory.appendingPathComponent(directoryName(for: region), isDirectory: true)
        if fileManager.fileExists(atPath: regionDir.path) {
            try fileManager.removeItem(at: regionDir)
        }
    }
}

enum OfflineMapsDownloadError: Error {
    case downloadFailed
    case invalidRegion
    case insufficientStorage
    case snapshotGenerationFailed
}

