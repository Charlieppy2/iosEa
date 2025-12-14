//
//  OfflineMapLoader.swift
//  hikingHK
//
//  Created for loading offline map data
//

import Foundation
import MapKit
import UIKit

struct OfflineMapLoader {
    private let fileManager = FileManager.default
    
    private var offlineMapsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("OfflineMaps", isDirectory: true)
    }
    
    /// 检查指定坐标是否在已下载的离线地图区域内
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
    
    /// 加载区域元数据
    func loadRegionMetadata(regionId: UUID) -> [String: String]? {
        let regionDir = offlineMapsDirectory.appendingPathComponent(regionId.uuidString, isDirectory: true)
        let metadataPath = regionDir.appendingPathComponent("metadata.json")
        
        guard let data = try? Data(contentsOf: metadataPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        
        return json
    }
    
    /// 获取区域的地图快照图像
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
    
    /// 获取所有已下载的区域 ID
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
    
    /// 检查区域是否已下载
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

