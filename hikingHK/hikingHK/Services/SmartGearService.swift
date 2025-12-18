//
//  SmartGearService.swift
//  hikingHK
//
//  Created for smart gear checklist generation
//

import Foundation

/// Describes a service that can generate a recommended gear list for a hike.
protocol SmartGearServiceProtocol {
    func generateGearList(
        difficulty: Trail.Difficulty,
        weather: WeatherSnapshot,
        season: Season,
        duration: Int, // in hours
        localize: ((String) -> String)? // Optional localization function
    ) -> [GearItem]
}

/// Simple season abstraction used to tune clothing and gear recommendations.
enum Season: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"
    
    static func current() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
    
    static func from(date: Date) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

/// Generates a smart gear checklist based on trail difficulty, weather,
/// season and expected hike duration.
@MainActor
final class SmartGearService: SmartGearServiceProtocol {
    
    /// Builds a comprehensive gear list for the given hiking parameters.
    func generateGearList(
        difficulty: Trail.Difficulty,
        weather: WeatherSnapshot,
        season: Season,
        duration: Int,
        localize: ((String) -> String)? = nil
    ) -> [GearItem] {
        var gearItems: [GearItem] = []
        
        // Essential items (always required)
        gearItems.append(contentsOf: getEssentialItems(duration: duration, localize: localize))
        
        // Clothing based on weather and season
        gearItems.append(contentsOf: getClothingItems(weather: weather, season: season, localize: localize))
        
        // Navigation items
        gearItems.append(contentsOf: getNavigationItems(difficulty: difficulty, localize: localize))
        
        // Safety items based on difficulty
        gearItems.append(contentsOf: getSafetyItems(difficulty: difficulty, weather: weather, localize: localize))
        
        // Food and hydration
        gearItems.append(contentsOf: getFoodItems(duration: duration, weather: weather, localize: localize))
        
        // Tools and equipment based on difficulty
        gearItems.append(contentsOf: getToolsItems(difficulty: difficulty, duration: duration, localize: localize))
        
        // Optional items
        gearItems.append(contentsOf: getOptionalItems(weather: weather, season: season, localize: localize))
        
        return gearItems
    }
    
    /// Helper function to localize gear item names
    private func localizedName(_ key: String, localize: ((String) -> String)?) -> String {
        return localize?(key) ?? key
    }
    
    private func getEssentialItems(duration: Int, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .essential,
            name: localizedName("gear.item.water.bottle", localize: localize),
            iconName: "drop.fill",
            isRequired: true
        ))
        
        if duration > 4 {
            items.append(GearItem(
                category: .essential,
                name: localizedName("gear.item.extra.water", localize: localize),
                iconName: "drop.fill",
                isRequired: true
            ))
        }
        
        items.append(GearItem(
            category: .essential,
            name: localizedName("gear.item.mobile.phone", localize: localize),
            iconName: "iphone",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .essential,
            name: localizedName("gear.item.power.bank", localize: localize),
            iconName: "battery.100",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .essential,
            name: localizedName("gear.item.id.card", localize: localize),
            iconName: "person.text.rectangle.fill",
            isRequired: true
        ))
        
        return items
    }
    
    private func getClothingItems(weather: WeatherSnapshot, season: Season, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        // Base clothing
        items.append(GearItem(
            category: .clothing,
            name: localizedName("gear.item.moisture.tshirt", localize: localize),
            iconName: "tshirt.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: localizedName("gear.item.hiking.pants", localize: localize),
            iconName: "figure.walk",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: localizedName("gear.item.hiking.shoes", localize: localize),
            iconName: "shoe.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: localizedName("gear.item.socks", localize: localize),
            iconName: "sock.fill",
            isRequired: true
        ))
        
        // Weather-specific clothing
        if weather.temperature < 15 || season == .winter {
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.warm.jacket", localize: localize),
                iconName: "tshirt.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.beanie", localize: localize),
                iconName: "hat.fill",
                isRequired: true
            ))
        }
        
        if weather.temperature > 25 || season == .summer {
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.sun.hat", localize: localize),
                iconName: "sun.max.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.sunglasses", localize: localize),
                iconName: "eyeglasses",
                isRequired: true
            ))
        }
        
        if weather.humidity > 80 || weather.suggestion.lowercased().contains("rain") {
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.rain.jacket", localize: localize),
                iconName: "cloud.rain.fill",
                isRequired: true
            ))
        }
        
        if weather.uvIndex > 6 {
            items.append(GearItem(
                category: .clothing,
                name: localizedName("gear.item.uv.protection", localize: localize),
                iconName: "sun.max.fill",
                isRequired: true
            ))
        }
        
        return items
    }
    
    private func getNavigationItems(difficulty: Trail.Difficulty, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .navigation,
            name: localizedName("gear.item.offline.map", localize: localize),
            iconName: "map.fill",
            isRequired: true
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .navigation,
                name: localizedName("gear.item.compass", localize: localize),
                iconName: "location.north.circle.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .navigation,
                name: localizedName("gear.item.gps.device", localize: localize),
                iconName: "location.fill",
                isRequired: false
            ))
        }
        
        return items
    }
    
    private func getSafetyItems(difficulty: Trail.Difficulty, weather: WeatherSnapshot, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .safety,
            name: localizedName("gear.item.first.aid", localize: localize),
            iconName: "cross.case.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .safety,
            name: localizedName("gear.item.whistle", localize: localize),
            iconName: "speaker.wave.2.fill",
            isRequired: true
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .safety,
                name: localizedName("gear.item.emergency.blanket", localize: localize),
                iconName: "rectangle.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .safety,
                name: localizedName("gear.item.headlamp", localize: localize),
                iconName: "flashlight.on.fill",
                isRequired: true
            ))
        }
        
        if weather.uvIndex > 6 {
            items.append(GearItem(
                category: .safety,
                name: localizedName("gear.item.sunscreen", localize: localize),
                iconName: "sun.max.fill",
                isRequired: true
            ))
        }
        
        items.append(GearItem(
            category: .safety,
            name: localizedName("gear.item.insect.repellent", localize: localize),
            iconName: "ant.fill",
            isRequired: true
        ))
        
        return items
    }
    
    private func getFoodItems(duration: Int, weather: WeatherSnapshot, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        if duration <= 2 {
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.energy.snacks", localize: localize),
                iconName: "leaf.fill",
                isRequired: true
            ))
        } else if duration <= 4 {
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.energy.snacks", localize: localize),
                iconName: "leaf.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.light.meal", localize: localize),
                iconName: "fork.knife",
                isRequired: true
            ))
        } else {
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.energy.snacks", localize: localize),
                iconName: "leaf.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.full.meal", localize: localize),
                iconName: "fork.knife",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.electrolyte.drink", localize: localize),
                iconName: "drop.fill",
                isRequired: true
            ))
        }
        
        if weather.temperature > 25 {
            items.append(GearItem(
                category: .food,
                name: localizedName("gear.item.electrolyte.tablets", localize: localize),
                iconName: "pills.fill",
                isRequired: true
            ))
        }
        
        return items
    }
    
    private func getToolsItems(difficulty: Trail.Difficulty, duration: Int, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .tools,
            name: localizedName("gear.item.multi.tool", localize: localize),
            iconName: "wrench.and.screwdriver.fill",
            isRequired: difficulty == .challenging
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .tools,
                name: localizedName("gear.item.trekking.poles", localize: localize),
                iconName: "figure.walk",
                isRequired: false
            ))
        }
        
        if duration > 6 {
            items.append(GearItem(
                category: .tools,
                name: localizedName("gear.item.trekking.poles", localize: localize),
                iconName: "figure.walk",
                isRequired: false
            ))
        }
        
        return items
    }
    
    private func getOptionalItems(weather: WeatherSnapshot, season: Season, localize: ((String) -> String)?) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .optional,
            name: localizedName("gear.item.camera", localize: localize),
            iconName: "camera.fill",
            isRequired: false
        ))
        
        items.append(GearItem(
            category: .optional,
            name: localizedName("gear.item.binoculars", localize: localize),
            iconName: "eye.fill",
            isRequired: false
        ))
        
        if season == .spring || season == .autumn {
            items.append(GearItem(
                category: .optional,
                name: localizedName("gear.item.lightweight.gloves", localize: localize),
                iconName: "hand.raised.fill",
                isRequired: false
            ))
        }
        
        return items
    }
}

