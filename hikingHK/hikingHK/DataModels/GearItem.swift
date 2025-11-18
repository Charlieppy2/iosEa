//
//  GearItem.swift
//  hikingHK
//
//  Created for smart gear checklist
//

import Foundation
import SwiftData

@Model
final class GearItem {
    var id: String
    var category: GearCategory
    var name: String
    var iconName: String
    var isRequired: Bool
    var isCompleted: Bool
    var lastUpdated: Date
    var hikeId: UUID?
    
    init(
        id: String = UUID().uuidString,
        category: GearCategory,
        name: String,
        iconName: String,
        isRequired: Bool = true,
        isCompleted: Bool = false,
        hikeId: UUID? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.iconName = iconName
        self.isRequired = isRequired
        self.isCompleted = isCompleted
        self.lastUpdated = Date()
        self.hikeId = hikeId
    }
    
    enum GearCategory: String, Codable, CaseIterable {
        case essential = "Essential"
        case clothing = "Clothing"
        case navigation = "Navigation"
        case safety = "Safety"
        case food = "Food"
        case tools = "Tools"
        case optional = "Optional"
        
        var icon: String {
            switch self {
            case .essential: return "star.fill"
            case .clothing: return "tshirt.fill"
            case .navigation: return "map.fill"
            case .safety: return "cross.case.fill"
            case .food: return "fork.knife"
            case .tools: return "wrench.and.screwdriver.fill"
            case .optional: return "plus.circle.fill"
            }
        }
    }
}

