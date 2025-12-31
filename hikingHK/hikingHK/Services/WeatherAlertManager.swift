//
//  WeatherAlertManager.swift
//  hikingHK
//
//  Manages weather alerts, notifications, and real-time weather monitoring
//

import Foundation
import UserNotifications
import Combine

/// Manages weather alerts, automatic notifications, and real-time weather monitoring
@MainActor
final class WeatherAlertManager: ObservableObject {
    @Published var hasActiveWarnings = false
    @Published var lastWeatherCheck: Date?
    @Published var isMonitoring = false
    
    private let weatherService: WeatherServiceProtocol
    private let warningService: WeatherWarningServiceProtocol
    private var monitoringTask: Task<Void, Never>?
    private var notificationCenter: UNUserNotificationCenter
    private var cancellables = Set<AnyCancellable>()
    
    /// Interval for checking weather during active monitoring (default: 15 minutes)
    var monitoringInterval: TimeInterval = 900 // 15 minutes
    
    /// Interval for checking weather before planned hikes (default: 1 hour)
    var preHikeCheckInterval: TimeInterval = 3600 // 1 hour
    
    init(
        weatherService: WeatherServiceProtocol = WeatherService(),
        warningService: WeatherWarningServiceProtocol = WeatherWarningService(),
        notificationCenter: UNUserNotificationCenter? = nil
    ) {
        self.weatherService = weatherService
        self.warningService = warningService
        self.notificationCenter = notificationCenter ?? UNUserNotificationCenter.current()
    }
    
    // MARK: - Notification Permission
    
    /// Requests notification permission from the user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ WeatherAlertManager: Notification permission granted")
            } else {
                print("⚠️ WeatherAlertManager: Notification permission denied")
            }
            return granted
        } catch {
            print("❌ WeatherAlertManager: Failed to request notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Automatic Weather Monitoring
    
    /// Starts automatic weather monitoring for planned hikes
    /// Checks weather periodically and sends notifications for severe weather
    func startMonitoring(language: String = "en") {
        guard !isMonitoring else {
            print("⚠️ WeatherAlertManager: Already monitoring")
            return
        }
        
        isMonitoring = true
        print("🔄 WeatherAlertManager: Starting weather monitoring...")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                do {
                    await checkWeatherAndNotify(language: language)
                    try await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
                } catch {
                    print("❌ WeatherAlertManager: Monitoring error: \(error)")
                    try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
                }
            }
        }
    }
    
    /// Stops automatic weather monitoring
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
        print("🛑 WeatherAlertManager: Stopped weather monitoring")
    }
    
    // MARK: - Weather Check and Notification
    
    /// Checks current weather and sends notifications if severe weather is detected
    private func checkWeatherAndNotify(language: String) async {
        do {
            let snapshot = try await weatherService.fetchSnapshot(language: language)
            let warnings = try await warningService.fetchWarnings(language: language)
            let activeWarnings = warnings.filter { $0.isActive }
            
            hasActiveWarnings = !activeWarnings.isEmpty || (snapshot.warningMessage != nil && !snapshot.warningMessage!.isEmpty)
            lastWeatherCheck = Date()
            
            // Send notification if severe weather detected
            if hasActiveWarnings {
                await sendWeatherAlertNotification(
                    warnings: activeWarnings,
                    warningMessage: snapshot.warningMessage,
                    language: language
                )
            }
        } catch {
            print("❌ WeatherAlertManager: Failed to check weather: \(error)")
        }
    }
    
    /// Sends a notification for severe weather conditions
    private func sendWeatherAlertNotification(
        warnings: [WeatherWarning],
        warningMessage: String?,
        language: String
    ) async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else {
            print("⚠️ WeatherAlertManager: No notification permission, skipping alert")
            return
        }
        
        let isEnglish = language == "en" || language == "english"
        
        // Build notification content
        let title: String
        let body: String
        
        if !warnings.isEmpty {
            let warningNames = warnings.map { $0.name }.joined(separator: ", ")
            title = isEnglish ? "Weather Warning Active" : "天氣警告生效"
            body = isEnglish 
                ? "Active weather warnings: \(warningNames). Please check conditions before hiking."
                : "活躍天氣警告：\(warningNames)。請在行山前檢查天氣狀況。"
        } else if let message = warningMessage, !message.isEmpty {
            title = isEnglish ? "Weather Alert" : "天氣警示"
            body = isEnglish 
                ? "Weather warning: \(message)"
                : "天氣警告：\(message)"
        } else {
            return // No warnings to notify about
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WEATHER_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "weather_alert_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ WeatherAlertManager: Sent weather alert notification")
        } catch {
            print("❌ WeatherAlertManager: Failed to send notification: \(error)")
        }
    }
    
    /// Checks if notification permission is granted
    private func checkNotificationPermission() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Pre-Hike Weather Check
    
    /// Checks weather before a planned hike and returns a recommendation
    /// - Parameters:
    ///   - scheduledDate: The scheduled date for the hike
    ///   - language: Language code for localization
    /// - Returns: A tuple containing whether it's safe to hike and a recommendation message
    func checkWeatherBeforeHike(scheduledDate: Date, language: String = "en") async -> (isSafe: Bool, message: String) {
        do {
            let snapshot = try await weatherService.fetchSnapshot(language: language)
            let warnings = try await warningService.fetchWarnings(language: language)
            let activeWarnings = warnings.filter { $0.isActive }
            
            let isEnglish = language == "en" || language == "english"
            
            // Check if hike is today or tomorrow
            let calendar = Calendar.current
            let daysUntilHike = calendar.dateComponents([.day], from: Date(), to: scheduledDate).day ?? 0
            
            // If hike is more than 2 days away, just check current conditions
            if daysUntilHike > 2 {
                if hasActiveWarnings || (snapshot.warningMessage != nil && !snapshot.warningMessage!.isEmpty) {
                    let message = isEnglish
                        ? "Current weather warnings are active. Check again closer to your hike date."
                        : "目前有活躍的天氣警告。請在接近行山日期時再次檢查。"
                    return (false, message)
                } else {
                    let message = isEnglish
                        ? "Current weather conditions look good. Check again closer to your hike date."
                        : "目前天氣狀況良好。請在接近行山日期時再次檢查。"
                    return (true, message)
                }
            }
            
            // For hikes today or tomorrow, provide detailed check
            var issues: [String] = []
            
            if !activeWarnings.isEmpty {
                let warningNames = activeWarnings.map { $0.name }.joined(separator: ", ")
                issues.append(isEnglish 
                    ? "Active weather warnings: \(warningNames)"
                    : "活躍天氣警告：\(warningNames)")
            }
            
            if let warningMessage = snapshot.warningMessage, !warningMessage.isEmpty {
                issues.append(warningMessage)
            }
            
            // Check UV index
            if snapshot.uvIndex >= 8 {
                issues.append(isEnglish
                    ? "Extreme UV index (\(snapshot.uvIndex)). Start early and bring sun protection."
                    : "極高紫外線指數（\(snapshot.uvIndex)）。建議提早出發並攜帶防曬用品。")
            }
            
            // Check humidity
            if snapshot.humidity >= 85 {
                issues.append(isEnglish
                    ? "High humidity (\(snapshot.humidity)%). Stay hydrated and take frequent breaks."
                    : "高濕度（\(snapshot.humidity)%）。請多補充水分並經常休息。")
            }
            
            if issues.isEmpty {
                let message = isEnglish
                    ? "Weather conditions are suitable for hiking. Have a safe and enjoyable hike!"
                    : "天氣狀況適合行山。祝您行山愉快，注意安全！"
                return (true, message)
            } else {
                let message = issues.joined(separator: "\n")
                return (false, message)
            }
        } catch {
            let isEnglish = language == "en" || language == "english"
            let message = isEnglish
                ? "Unable to check weather conditions. Please check manually before hiking."
                : "無法檢查天氣狀況。請在行山前手動檢查。"
            return (false, message)
        }
    }
    
    // MARK: - Real-time Weather Updates During Hike
    
    /// Starts real-time weather monitoring during an active hike
    /// Updates weather every monitoringInterval and sends alerts for severe changes
    func startHikeMonitoring(language: String = "en") {
        guard !isMonitoring else {
            print("⚠️ WeatherAlertManager: Already monitoring")
            return
        }
        
        isMonitoring = true
        print("🔄 WeatherAlertManager: Starting real-time weather monitoring during hike...")
        
        // Use shorter interval for active hike monitoring (5 minutes)
        let originalInterval = monitoringInterval
        monitoringInterval = 300 // 5 minutes
        
        monitoringTask = Task {
            while !Task.isCancelled {
                do {
                    await checkWeatherAndNotify(language: language)
                    try await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
                } catch {
                    print("❌ WeatherAlertManager: Hike monitoring error: \(error)")
                    try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
                }
            }
        }
        
        // Restore original interval when monitoring stops
        Task {
            await monitoringTask?.value
            monitoringInterval = originalInterval
        }
    }
    
    /// Gets the latest weather snapshot (for real-time updates during hike)
    func getLatestWeather(language: String = "en") async -> WeatherSnapshot? {
        do {
            let snapshot = try await weatherService.fetchSnapshot(language: language)
            lastWeatherCheck = Date()
            return snapshot
        } catch {
            print("❌ WeatherAlertManager: Failed to get latest weather: \(error)")
            return nil
        }
    }
}

