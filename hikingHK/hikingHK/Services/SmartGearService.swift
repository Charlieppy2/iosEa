//
//  SmartGearService.swift
//  hikingHK
//
//  Created for smart gear checklist generation
//

import Foundation

protocol SmartGearServiceProtocol {
    func generateGearList(
        difficulty: Trail.Difficulty,
        weather: WeatherSnapshot,
        season: Season,
        duration: Int // in hours
    ) -> [GearItem]
}

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

@MainActor
final class SmartGearService: SmartGearServiceProtocol {
    
    func generateGearList(
        difficulty: Trail.Difficulty,
        weather: WeatherSnapshot,
        season: Season,
        duration: Int
    ) -> [GearItem] {
        var gearItems: [GearItem] = []
        
        // Essential items (always required)
        gearItems.append(contentsOf: getEssentialItems(duration: duration))
        
        // Clothing based on weather and season
        gearItems.append(contentsOf: getClothingItems(weather: weather, season: season))
        
        // Navigation items
        gearItems.append(contentsOf: getNavigationItems(difficulty: difficulty))
        
        // Safety items based on difficulty
        gearItems.append(contentsOf: getSafetyItems(difficulty: difficulty, weather: weather))
        
        // Food and hydration
        gearItems.append(contentsOf: getFoodItems(duration: duration, weather: weather))
        
        // Tools and equipment based on difficulty
        gearItems.append(contentsOf: getToolsItems(difficulty: difficulty, duration: duration))
        
        // Optional items
        gearItems.append(contentsOf: getOptionalItems(weather: weather, season: season))
        
        return gearItems
    }
    
    private func getEssentialItems(duration: Int) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .essential,
            name: "Water Bottle (2L minimum)",
            iconName: "drop.fill",
            isRequired: true
        ))
        
        if duration > 4 {
            items.append(GearItem(
                category: .essential,
                name: "Extra Water (1L per additional 2 hours)",
                iconName: "drop.fill",
                isRequired: true
            ))
        }
        
        items.append(GearItem(
            category: .essential,
            name: "Mobile Phone (fully charged)",
            iconName: "iphone",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .essential,
            name: "Power Bank",
            iconName: "battery.100",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .essential,
            name: "ID Card / ID Document",
            iconName: "person.text.rectangle.fill",
            isRequired: true
        ))
        
        return items
    }
    
    private func getClothingItems(weather: WeatherSnapshot, season: Season) -> [GearItem] {
        var items: [GearItem] = []
        
        // Base clothing
        items.append(GearItem(
            category: .clothing,
            name: "Moisture-wicking T-shirt",
            iconName: "tshirt.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: "Hiking Pants / Shorts",
            iconName: "figure.walk",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: "Hiking Shoes / Boots",
            iconName: "shoe.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .clothing,
            name: "Socks (extra pair)",
            iconName: "sock.fill",
            isRequired: true
        ))
        
        // Weather-specific clothing
        if weather.temperature < 15 || season == .winter {
            items.append(GearItem(
                category: .clothing,
                name: "Warm Jacket / Fleece",
                iconName: "tshirt.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .clothing,
                name: "Beanie / Warm Hat",
                iconName: "hat.fill",
                isRequired: true
            ))
        }
        
        if weather.temperature > 25 || season == .summer {
            items.append(GearItem(
                category: .clothing,
                name: "Sun Hat / Cap",
                iconName: "sun.max.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .clothing,
                name: "Sunglasses",
                iconName: "eyeglasses",
                isRequired: true
            ))
        }
        
        if weather.humidity > 80 || weather.suggestion.lowercased().contains("rain") {
            items.append(GearItem(
                category: .clothing,
                name: "Rain Jacket / Poncho",
                iconName: "cloud.rain.fill",
                isRequired: true
            ))
        }
        
        if weather.uvIndex > 6 {
            items.append(GearItem(
                category: .clothing,
                name: "UV Protection Clothing",
                iconName: "sun.max.fill",
                isRequired: true
            ))
        }
        
        return items
    }
    
    private func getNavigationItems(difficulty: Trail.Difficulty) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .navigation,
            name: "Offline Map (downloaded)",
            iconName: "map.fill",
            isRequired: true
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .navigation,
                name: "Compass",
                iconName: "location.north.circle.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .navigation,
                name: "GPS Device (optional backup)",
                iconName: "location.fill",
                isRequired: false
            ))
        }
        
        return items
    }
    
    private func getSafetyItems(difficulty: Trail.Difficulty, weather: WeatherSnapshot) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .safety,
            name: "First Aid Kit",
            iconName: "cross.case.fill",
            isRequired: true
        ))
        
        items.append(GearItem(
            category: .safety,
            name: "Whistle",
            iconName: "speaker.wave.2.fill",
            isRequired: true
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .safety,
                name: "Emergency Blanket",
                iconName: "rectangle.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .safety,
                name: "Headlamp / Flashlight",
                iconName: "flashlight.on.fill",
                isRequired: true
            ))
        }
        
        if weather.uvIndex > 6 {
            items.append(GearItem(
                category: .safety,
                name: "Sunscreen (SPF 50+)",
                iconName: "sun.max.fill",
                isRequired: true
            ))
        }
        
        items.append(GearItem(
            category: .safety,
            name: "Insect Repellent",
            iconName: "ant.fill",
            isRequired: true
        ))
        
        return items
    }
    
    private func getFoodItems(duration: Int, weather: WeatherSnapshot) -> [GearItem] {
        var items: [GearItem] = []
        
        if duration <= 2 {
            items.append(GearItem(
                category: .food,
                name: "Energy Snacks",
                iconName: "leaf.fill",
                isRequired: true
            ))
        } else if duration <= 4 {
            items.append(GearItem(
                category: .food,
                name: "Energy Snacks",
                iconName: "leaf.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: "Light Meal / Sandwich",
                iconName: "fork.knife",
                isRequired: true
            ))
        } else {
            items.append(GearItem(
                category: .food,
                name: "Energy Snacks",
                iconName: "leaf.fill",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: "Full Meal",
                iconName: "fork.knife",
                isRequired: true
            ))
            items.append(GearItem(
                category: .food,
                name: "Electrolyte Drinks / Sports Drink",
                iconName: "drop.fill",
                isRequired: true
            ))
        }
        
        if weather.temperature > 25 {
            items.append(GearItem(
                category: .food,
                name: "Electrolyte Tablets",
                iconName: "pills.fill",
                isRequired: true
            ))
        }
        
        return items
    }
    
    private func getToolsItems(difficulty: Trail.Difficulty, duration: Int) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .tools,
            name: "Multi-tool / Knife",
            iconName: "wrench.and.screwdriver.fill",
            isRequired: difficulty == .challenging
        ))
        
        if difficulty == .challenging {
            items.append(GearItem(
                category: .tools,
                name: "Trekking Poles",
                iconName: "figure.walk",
                isRequired: false
            ))
        }
        
        if duration > 6 {
            items.append(GearItem(
                category: .tools,
                name: "Trekking Poles",
                iconName: "figure.walk",
                isRequired: false
            ))
        }
        
        return items
    }
    
    private func getOptionalItems(weather: WeatherSnapshot, season: Season) -> [GearItem] {
        var items: [GearItem] = []
        
        items.append(GearItem(
            category: .optional,
            name: "Camera",
            iconName: "camera.fill",
            isRequired: false
        ))
        
        items.append(GearItem(
            category: .optional,
            name: "Binoculars",
            iconName: "eye.fill",
            isRequired: false
        ))
        
        if season == .spring || season == .autumn {
            items.append(GearItem(
                category: .optional,
                name: "Lightweight Gloves",
                iconName: "hand.raised.fill",
                isRequired: false
            ))
        }
        
        return items
    }
}

