//
//  LocationSharingService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation
import MessageUI

protocol LocationSharingServiceProtocol {
    func generateShareLink(location: CLLocationCoordinate2D) -> String
    func sendLocationViaMessage(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws
    func sendLocationViaEmail(contacts: [EmergencyContact], location: CLLocationCoordinate2D, subject: String, message: String) async throws
    func sendEmergencySOS(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws
}

final class LocationSharingService: LocationSharingServiceProtocol {
    
    func generateShareLink(location: CLLocationCoordinate2D) -> String {
        // 生成 Google Maps 分享鏈接
        let url = "https://www.google.com/maps?q=\(location.latitude),\(location.longitude)"
        return url
    }
    
    func sendLocationViaMessage(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws {
        // 在實際應用中，這裡會使用 MessageUI 或第三方服務發送短信
        // 目前為模擬實現
        let locationText = "位置：\(location.latitude), \(location.longitude)\n地圖：\(generateShareLink(location: location))"
        let fullMessage = "\(message)\n\n\(locationText)"
        
        print("發送短信給：\(contacts.map { $0.name }.joined(separator: ", "))")
        print("內容：\(fullMessage)")
        
        // 實際實現時，可以使用：
        // - MessageUI 框架（需要用戶確認）
        // - 第三方短信服務 API
        // - 推送通知服務
    }
    
    func sendLocationViaEmail(contacts: [EmergencyContact], location: CLLocationCoordinate2D, subject: String, message: String) async throws {
        // 在實際應用中，這裡會使用 MessageUI 或郵件服務發送郵件
        let locationText = "位置：\(location.latitude), \(location.longitude)\n地圖：\(generateShareLink(location: location))"
        let fullMessage = "\(message)\n\n\(locationText)"
        
        print("發送郵件給：\(contacts.map { $0.email ?? $0.phoneNumber }.joined(separator: ", "))")
        print("主題：\(subject)")
        print("內容：\(fullMessage)")
        
        // 實際實現時，可以使用：
        // - MessageUI 框架（需要用戶確認）
        // - 郵件服務 API（如 SendGrid、Mailgun）
    }
    
    func sendEmergencySOS(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws {
        let sosMessage = "🆘 緊急求救！\n\n\(message)\n\n我的位置：\n緯度：\(location.latitude)\n經度：\(location.longitude)\n地圖：\(generateShareLink(location: location))\n\n請立即協助！"
        
        // 發送給所有緊急聯繫人
        for contact in contacts {
            // 優先使用短信（更快速）
            if !contact.phoneNumber.isEmpty {
                try await sendLocationViaMessage(contacts: [contact], location: location, message: sosMessage)
            }
            // 如果有郵箱，也發送郵件
            if let email = contact.email, !email.isEmpty {
                try await sendLocationViaEmail(contacts: [contact], location: location, subject: "緊急求救 - 需要立即協助", message: sosMessage)
            }
        }
        
        // 在實際應用中，還可以：
        // - 撥打緊急電話（999）
        // - 發送推送通知
        // - 記錄到日誌服務
    }
}

