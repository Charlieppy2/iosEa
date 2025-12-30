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
                    // Try next transport text if this one fails
                    continue
                }
            }
        }
        
        // If no MTR station found or all failed
        isLoading = false
        hasSchedule = false
        
        // Set error message if we tried but failed
        if lastError != nil {
            self.error = languageManager.localizedString(for: "mtr.error.load.failed")
        }
    }
    
    /// Extract MTR station information from transportation text
    private func extractMTRStation(from text: String) -> (line: String, station: String)? {
        // Common patterns: "港鐵XX站", "MTR XX Station", "乘港鐵到XX"
        let patterns = [
            "港鐵([^站]+)站",
            "MTR ([A-Za-z ]+) Station",
            "乘港鐵到([^，。；,.;]+)",
            "乘港鐵至([^，。；,.;]+)",
            "港鐵([^，。；,.;]+)",
            "MTR ([A-Za-z ]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for result in results {
                    if result.numberOfRanges > 1 {
                        let stationName = nsString.substring(with: result.range(at: 1))
                            .trimmingCharacters(in: .whitespaces)
                        
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

