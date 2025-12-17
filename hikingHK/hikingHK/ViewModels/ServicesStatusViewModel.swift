//
//  ServicesStatusViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation
import Combine
import SwiftData

@MainActor
final class ServicesStatusViewModel: NSObject, ObservableObject {
    @Published var weatherServiceStatus: ServiceStatus = .unknown
    @Published var gpsStatus: ServiceStatus = .unknown
    @Published var offlineMapsStatus: ServiceStatus = .unknown
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkGPSStatus()
        checkOfflineMapsStatus()
    }
    
    enum ServiceStatus {
        case connected
        case disconnected
        case unavailable
        case unknown
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .unavailable: return "exclamationmark.triangle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .connected: return "green"
            case .disconnected: return "red"
            case .unavailable: return "orange"
            case .unknown: return "gray"
            }
        }
    }
    
    func checkWeatherServiceStatus(weatherError: String?, hasWeatherData: Bool) {
        if hasWeatherData && weatherError == nil {
            weatherServiceStatus = .connected
        } else if weatherError != nil {
            weatherServiceStatus = .disconnected
        } else {
            weatherServiceStatus = .unknown
        }
    }
    
    func checkGPSStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            gpsStatus = .connected
        case .denied, .restricted:
            gpsStatus = .unavailable
        case .notDetermined:
            gpsStatus = .unknown
        @unknown default:
            gpsStatus = .unknown
        }
    }
    
    func checkOfflineMapsStatus(context: ModelContext? = nil) {
        // 先嘗試從 SwiftData 判斷是否有「已下載」的區域
        var hasDownloaded = false
        
        if let context = context {
            do {
                let store = OfflineMapsStore(context: context)
                let regions = try store.loadAllRegions()
                
                // 1️⃣ 先看資料庫裡是否有標記為已下載的區域
                hasDownloaded = regions.contains { $0.downloadStatus == .downloaded }
                
                // 2️⃣ 如果資料庫裡沒有任何已下載，但實際檔案已存在，改用檔案系統判斷
                if !hasDownloaded {
                    hasDownloaded = hasAnyOfflineMapFilesOnDisk()
                }
            } catch {
                // SwiftData 出錯時，退回檔案系統判斷
                hasDownloaded = hasAnyOfflineMapFilesOnDisk()
            }
        } else {
            // 沒有傳入 context，也用檔案系統來嘗試判斷
            hasDownloaded = hasAnyOfflineMapFilesOnDisk()
        }
        
        offlineMapsStatus = hasDownloaded ? .connected : .unavailable
    }
    
    /// 直接從檔案系統檢查是否存在任何離線地圖資料夾（含 metadata.json）
    private func hasAnyOfflineMapFilesOnDisk() -> Bool {
        // 與 OfflineMapsDownloadService 使用相同的路徑：Documents/OfflineMaps
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let offlineDir = documentsDir.appendingPathComponent("OfflineMaps", isDirectory: true)
        
        // 沒有 OfflineMaps 目錄就直接視為沒有離線地圖
        guard fileManager.fileExists(atPath: offlineDir.path) else {
            return false
        }
        
        do {
            let subdirs = try fileManager.contentsOfDirectory(
                at: offlineDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            for dir in subdirs {
                let metadataPath = dir.appendingPathComponent("metadata.json")
                if fileManager.fileExists(atPath: metadataPath.path) {
                    return true
                }
            }
        } catch {
            // 發生錯誤時當作沒有離線地圖，並在除錯輸出訊息
            print("⚠️ ServicesStatusViewModel: Failed to scan offline maps directory: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func refreshAllStatuses(weatherError: String?, hasWeatherData: Bool, context: ModelContext? = nil) {
        checkWeatherServiceStatus(weatherError: weatherError, hasWeatherData: hasWeatherData)
        checkGPSStatus()
        checkOfflineMapsStatus(context: context)
    }
}

extension ServicesStatusViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkGPSStatus()
        }
    }
}

