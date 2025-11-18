//
//  Goal.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

struct Goal: Identifiable {
    let id: String
    let title: String
    let icon: String
    let target: Double
    var current: Double
    let unit: String
    var isCompleted: Bool {
        current >= target
    }
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    func progressText(languageManager: LanguageManager) -> String {
        if isCompleted {
            return languageManager.localizedString(for: "goal.completed")
        }
        let unitKey = unit == "km" ? "goal.unit.km" : "goal.unit.lines"
        let localizedUnit = languageManager.localizedString(for: unitKey)
        if unit == "km" {
            return "\(current.formatted(.number.precision(.fractionLength(1)))) / \(Int(target)) \(localizedUnit)"
        }
        return "\(Int(current)) / \(Int(target)) \(localizedUnit)"
    }
    
    func localizedTitle(languageManager: LanguageManager) -> String {
        let key = "goal.\(id)"
        return languageManager.localizedString(for: key)
    }
}

extension Goal {
    static let ridgeLines = Goal(
        id: "ridge_lines",
        title: "Complete 4 Ridge Lines",
        icon: "flag.2.crossed",
        target: 4,
        current: 0,
        unit: "lines"
    )
    
    static let monthlyDistance = Goal(
        id: "monthly_distance",
        title: "Log 50 km this month",
        icon: "chart.line.uptrend.xyaxis",
        target: 50,
        current: 0,
        unit: "km"
    )
}

