//
//  OfflineMapsDownloadService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import MapKit
import UIKit

protocol OfflineMapsDownloadServiceProtocol {
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws
    func getEstimatedSize(for region: String) -> Int64
    func isRegionDownloaded(_ region: OfflineMapRegion) -> Bool
    func deleteRegionData(_ region: OfflineMapRegion) throws
}

struct OfflineMapsDownloadService: OfflineMapsDownloadServiceProtocol {
    private let session: URLSession
    private let fileManager = FileManager.default
    
    // 离线地图存储目录
    private var offlineMapsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mapsDir = documentsPath.appendingPathComponent("OfflineMaps", isDirectory: true)
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: mapsDir.path) {
            try? fileManager.createDirectory(at: mapsDir, withIntermediateDirectories: true)
        }
        
        return mapsDir
    }
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getEstimatedSize(for region: String) -> Int64 {
        // 基于区域大小估算（不同缩放级别的地图瓦片）
        // 每个区域需要下载多个缩放级别的地图快照
        let baseSize: Int64 = 5 * 1024 * 1024 // 每个缩放级别约 5MB
        let zoomLevels = 5 // 下载 5 个缩放级别
        
        let regionMultiplier: [String: Double] = [
            "Hong Kong Island": 1.0,
            "Kowloon Ridge": 0.85,
            "Sai Kung East": 1.2,
            "Lantau North": 1.1
        ]
        
        let multiplier = regionMultiplier[region] ?? 1.0
        return Int64(Double(baseSize * Int64(zoomLevels)) * multiplier)
    }
    
    func downloadRegion(_ region: OfflineMapRegion, progressHandler: @escaping (Double, Int64, Int64) -> Void) async throws {
        let totalSize = getEstimatedSize(for: region.name)
        var downloaded: Int64 = 0
        let coordinateRegion = region.coordinateRegion
        
        // 创建区域目录
        let regionDir = offlineMapsDirectory.appendingPathComponent(region.id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: regionDir.path) {
            try fileManager.createDirectory(at: regionDir, withIntermediateDirectories: true)
        }
        
        // 保存区域元数据
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
        
        // 下载多个缩放级别的地图快照
        let zoomLevels: [Double] = [0.05, 0.02, 0.01, 0.005, 0.002] // 不同的缩放级别
        let snapshotsPerLevel = 4 // 每个级别生成 4 个快照（覆盖整个区域）
        
        for (levelIndex, zoomLevel) in zoomLevels.enumerated() {
            let span = MKCoordinateSpan(
                latitudeDelta: coordinateRegion.span.latitudeDelta * zoomLevel,
                longitudeDelta: coordinateRegion.span.longitudeDelta * zoomLevel
            )
            
            // 为每个缩放级别生成多个快照以覆盖整个区域
            for snapshotIndex in 0..<snapshotsPerLevel {
                let offsetLat = (Double(snapshotIndex / 2) - 0.5) * coordinateRegion.span.latitudeDelta * 0.3
                let offsetLon = (Double(snapshotIndex % 2) - 0.5) * coordinateRegion.span.longitudeDelta * 0.3
                
                let center = CLLocationCoordinate2D(
                    latitude: coordinateRegion.center.latitude + offsetLat,
                    longitude: coordinateRegion.center.longitude + offsetLon
                )
                
                let snapshotRegion = MKCoordinateRegion(center: center, span: span)
                
                // 生成地图快照
                let options = MKMapSnapshotter.Options()
                options.region = snapshotRegion
                options.size = CGSize(width: 1024, height: 1024)
                options.scale = UIScreen.main.scale
                options.mapType = .standard
                
                let snapshotter = MKMapSnapshotter(options: options)
                
                do {
                    let snapshot = try await snapshotter.start()
                    
                    // 保存快照图像
                    let imageData = snapshot.image.pngData()
                    let imagePath = regionDir.appendingPathComponent("snapshot_\(levelIndex)_\(snapshotIndex).png")
                    try imageData?.write(to: imagePath)
                    
                    if let data = imageData {
                        downloaded += Int64(data.count)
                    }
                    
                    // 更新进度
                    let progress = Double(downloaded) / Double(totalSize)
                    progressHandler(min(progress, 0.99), downloaded, totalSize)
                    
                    // 添加小延迟以避免过快请求
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 秒
                } catch {
                    print("Failed to generate snapshot for level \(levelIndex), snapshot \(snapshotIndex): \(error)")
                    // 继续下载其他快照，不中断整个下载过程
                }
            }
        }
        
        // 标记下载完成
        progressHandler(1.0, totalSize, totalSize)
    }
    
    func isRegionDownloaded(_ region: OfflineMapRegion) -> Bool {
        let regionDir = offlineMapsDirectory.appendingPathComponent(region.id.uuidString, isDirectory: true)
        return fileManager.fileExists(atPath: regionDir.path) && 
               fileManager.fileExists(atPath: regionDir.appendingPathComponent("metadata.json").path)
    }
    
    func deleteRegionData(_ region: OfflineMapRegion) throws {
        let regionDir = offlineMapsDirectory.appendingPathComponent(region.id.uuidString, isDirectory: true)
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

