//
//  OfflineMapLoader.swift
//  hikingHK
//
//  Created for loading offline map data
//

import Foundation
import MapKit
import UIKit

/// Helper responsible for reading offline map metadata, snapshots
/// and region information from the on-disk offline maps directory.
struct OfflineMapLoader {
    private let fileManager = FileManager.default
    
    private var offlineMapsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("OfflineMaps", isDirectory: true)
    }
    
    /// Checks whether the given coordinate lies inside a downloaded offline map region.
    func isCoordinateInOfflineRegion(_ coordinate: CLLocationCoordinate2D, regionId: UUID) -> Bool {
        guard let metadata = loadRegionMetadata(regionId: regionId) else {
            return false
        }
        
        guard let centerLat = Double(metadata["centerLat"] ?? ""),
              let centerLon = Double(metadata["centerLon"] ?? ""),
              let spanLat = Double(metadata["spanLat"] ?? ""),
              let spanLon = Double(metadata["spanLon"] ?? "") else {
            return false
        }
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let span = MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        let region = MKCoordinateRegion(center: center, span: span)
        
        return region.contains(coordinate)
    }
    
    /// Loads metadata JSON for a given offline map region.
    func loadRegionMetadata(regionId: UUID) -> [String: String]? {
        let regionDir = offlineMapsDirectory.appendingPathComponent(regionId.uuidString, isDirectory: true)
        let metadataPath = regionDir.appendingPathComponent("metadata.json")
        
        guard let data = try? Data(contentsOf: metadataPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        
        return json
    }
    
    /// Returns a map snapshot image for the given offline region if available.
    func getMapSnapshot(for regionId: UUID, at coordinate: CLLocationCoordinate2D, zoomLevel: Int = 2) -> UIImage? {
        let regionDir = offlineMapsDirectory.appendingPathComponent(regionId.uuidString, isDirectory: true)
        
        // 尝试加载最接近的快照
        let snapshotPath = regionDir.appendingPathComponent("snapshot_\(min(zoomLevel, 4))_0.png")
        
        if let imageData = try? Data(contentsOf: snapshotPath),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // 如果找不到指定级别的，尝试其他级别
        for level in 0..<5 {
            for index in 0..<4 {
                let path = regionDir.appendingPathComponent("snapshot_\(level)_\(index).png")
                if let imageData = try? Data(contentsOf: path),
                   let image = UIImage(data: imageData) {
                    return image
                }
            }
        }
        
        return nil
    }
    
    /// Returns all downloaded offline region IDs under the offline maps directory.
    func getAllDownloadedRegionIds() -> [UUID] {
        guard fileManager.fileExists(atPath: offlineMapsDirectory.path) else {
            return []
        }
        
        guard let contents = try? fileManager.contentsOfDirectory(at: offlineMapsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url -> UUID? in
            guard url.hasDirectoryPath else { return nil }
            return UUID(uuidString: url.lastPathComponent)
        }
    }
    
    /// Checks whether the specified offline region has been downloaded (directory + metadata.json exist).
    func isRegionDownloaded(regionId: UUID) -> Bool {
        let regionDir = offlineMapsDirectory.appendingPathComponent(regionId.uuidString, isDirectory: true)
        return fileManager.fileExists(atPath: regionDir.path) &&
               fileManager.fileExists(atPath: regionDir.appendingPathComponent("metadata.json").path)
    }
}

// MARK: - MKCoordinateRegion Extension
extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latRange = center.latitude - span.latitudeDelta/2 ... center.latitude + span.latitudeDelta/2
        let lonRange = center.longitude - span.longitudeDelta/2 ... center.longitude + span.longitudeDelta/2
        
        return latRange.contains(coordinate.latitude) && lonRange.contains(coordinate.longitude)
    }
}

