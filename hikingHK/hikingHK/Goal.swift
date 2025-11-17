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
    
    var progressText: String {
        if isCompleted {
            return "Completed"
        }
        if unit == "km" {
            return "\(current.formatted(.number.precision(.fractionLength(1)))) / \(Int(target)) \(unit)"
        }
        return "\(Int(current)) / \(Int(target)) \(unit)"
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

