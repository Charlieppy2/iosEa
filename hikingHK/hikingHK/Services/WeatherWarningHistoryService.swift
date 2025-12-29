//
//  WeatherWarningHistoryService.swift
//  hikingHK
//
//  Created for weather warning history management
//

import Foundation

/// Service for managing weather warning history
class WeatherWarningHistoryService {
    static let shared = WeatherWarningHistoryService()
    
    private let historyKey = "weatherWarningHistory"
    private let maxHistoryCount = 100 // 最多保存 100 條歷史記錄
    
    private init() {}
    
    /// Save a warning to history
    func saveWarning(_ warning: WeatherWarning) {
        var history = loadHistory()
        
        // Check if warning already exists
        if let existingIndex = history.firstIndex(where: { $0.code == warning.code && $0.cancelledAt == nil }) {
            // Update existing warning
            var existing = history[existingIndex]
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let updateTime = formatter.date(from: warning.updateTime) {
                existing = WeatherWarningHistory(
                    id: existing.id,
                    code: existing.code,
                    name: warning.name,
                    actionCode: warning.actionCode,
                    issueTime: existing.issueTime,
                    updateTime: updateTime,
                    cancelledAt: nil
                )
            }
            history[existingIndex] = existing
        } else {
            // Add new warning
            let historyRecord = WeatherWarningHistory(from: warning)
            history.insert(historyRecord, at: 0)
        }
        
        // Limit history size
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    /// Mark a warning as cancelled
    func cancelWarning(code: String) {
        var history = loadHistory()
        
        if let index = history.firstIndex(where: { $0.code == code && $0.cancelledAt == nil }) {
            let existing = history[index]
            let cancelled = WeatherWarningHistory(
                id: existing.id,
                code: existing.code,
                name: existing.name,
                actionCode: existing.actionCode,
                issueTime: existing.issueTime,
                updateTime: existing.updateTime,
                cancelledAt: Date()
            )
            history[index] = cancelled
            saveHistory(history)
        }
    }
    
    /// Load all history records
    func loadHistory() -> [WeatherWarningHistory] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([WeatherWarningHistory].self, from: data) else {
            return []
        }
        return history.sorted { $0.issueTime > $1.issueTime } // 最新的在前
    }
    
    /// Get active warnings from history (not cancelled)
    func getActiveWarnings() -> [WeatherWarningHistory] {
        return loadHistory().filter { $0.cancelledAt == nil }
    }
    
    /// Get cancelled warnings
    func getCancelledWarnings() -> [WeatherWarningHistory] {
        return loadHistory().filter { $0.cancelledAt != nil }
    }
    
    /// Clear all history
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    private func saveHistory(_ history: [WeatherWarningHistory]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}

