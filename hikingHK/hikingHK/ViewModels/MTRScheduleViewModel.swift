//
//  MTRScheduleViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MTRScheduleViewModel: ObservableObject {
    @Published var schedule: MTRScheduleData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasSchedule = false
    
    private let mtrService: MTRServiceProtocol
    
    init(mtrService: MTRServiceProtocol = MTRService()) {
        self.mtrService = mtrService
    }
    
    /// Load MTR schedule for a trail by extracting station information from transportation text
    func loadSchedule(for trail: Trail, languageManager: LanguageManager) async {
        isLoading = true
        error = nil
        hasSchedule = false
        
        // Try to extract MTR station from start and end transportation
        let transportTexts = [
            trail.startPointTransport,
            trail.endPointTransport,
            trail.transportation
        ].compactMap { $0 }
        
        var lastError: Error?
        
        for transportText in transportTexts {
            // Look for MTR station mentions
            if let stationInfo = extractMTRStation(from: transportText) {
                do {
                    let scheduleData = try await mtrService.fetchSchedule(
                        line: stationInfo.line,
                        station: stationInfo.station
                    )
                    self.schedule = scheduleData
                    self.hasSchedule = true
                    self.isLoading = false
                    self.error = nil
                    return
                } catch {
                    lastError = error
                    // Check if it's a specific API error
                    if let mtrError = error as? MTRServiceError {
                        switch mtrError {
                        case .apiError(let message):
                            // Check for "empty" or "no data" errors
                            if message.lowercased().contains("empty") || message.lowercased().contains("contents are empty") || message.contains("NT-204") {
                                // This station might not have real-time data available at the moment
                                // Don't set error immediately, try next transport text
                                continue
                            } else if message.contains("disabled in CMS") || message.contains("NT-205") {
                                self.error = languageManager.localizedString(for: "mtr.error.line.disabled")
                                isLoading = false
                                return
                            } else {
                                // Other API errors - try next transport text
                                continue
                            }
                        case .lineDisabled:
                            self.error = languageManager.localizedString(for: "mtr.error.line.disabled")
                            isLoading = false
                            return
                        default:
                            // Try next transport text if this one fails
                            continue
                        }
                    } else {
                        // Try next transport text if this one fails
                        continue
                    }
                }
            }
        }
        
        // If no MTR station found or all failed
        isLoading = false
        hasSchedule = false
        
        // Set error message if we tried but failed and haven't set a specific error yet
        if lastError != nil && self.error == nil {
            self.error = languageManager.localizedString(for: "mtr.error.load.failed")
        }
    }
    
    /// Extract MTR station information from transportation text
    private func extractMTRStation(from text: String) -> (line: String, station: String)? {
        // Common patterns: "港鐵XX站", "MTR XX Station", "乘港鐵到XX", "→ XX站", "至XX站"
        let patterns = [
            "港鐵([^站→至，。；,.;]+)站",  // 港鐵XX站
            "MTR ([A-Za-z ]+) Station",  // MTR XX Station
            "乘港鐵到([^，。；,.;]+)",     // 乘港鐵到XX
            "乘港鐵至([^，。；,.;]+)",     // 乘港鐵至XX
            "→\\s*([^，。；,.;]+)站",      // → XX站
            "至\\s*([^，。；,.;]+)站",      // 至XX站
            "港鐵([^，。；,.;]+)",          // 港鐵XX
            "MTR ([A-Za-z ]+)",           // MTR XX
            "([^，。；,.;]+)站",            // XX站 (通用模式，放在最後)
            "([^，。；,.;]+) Station"      // XX Station (通用模式，放在最後)
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for result in results {
                    if result.numberOfRanges > 1 {
                        let stationName = nsString.substring(with: result.range(at: 1))
                            .trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: "港鐵", with: "")
                            .replacingOccurrences(of: "MTR", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        
                        // Skip if too short or contains common non-station words
                        if stationName.count < 2 {
                            continue
                        }
                        
                        if let mapped = MTRStationMapper.mapStation(stationName) {
                            return mapped
                        }
                    }
                }
            }
        }
        
        // Try direct mapping of the entire text
        if let mapped = MTRStationMapper.mapStation(text) {
            return mapped
        }
        
        return nil
    }
}

