//
//  Species.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation

struct Species: Identifiable, Codable {
    let id: UUID
    let name: String
    let scientificName: String
    let commonName: String // 中文名
    let category: Category
    let description: String
    let habitat: String
    let distribution: String
    let protectionStatus: ProtectionStatus
    let imageUrl: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    
    var location: CLLocationCoordinate2D? {
        guard let lat = locationLatitude, let lon = locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    enum Category: String, Codable, CaseIterable {
        case plant = "植物"
        case bird = "鳥類"
        case mammal = "哺乳動物"
        case reptile = "爬行動物"
        case insect = "昆蟲"
        case amphibian = "兩棲動物"
        case other = "其他"
        
        var icon: String {
            switch self {
            case .plant: return "leaf.fill"
            case .bird: return "bird.fill"
            case .mammal: return "pawprint.fill"
            case .reptile: return "lizard.fill"
            case .insect: return "ant.fill"
            case .amphibian: return "tortoise.fill"
            case .other: return "questionmark.circle.fill"
            }
        }
    }
    
    enum ProtectionStatus: String, Codable, CaseIterable {
        case protected = "受保護"
        case endangered = "瀕危"
        case vulnerable = "易危"
        case common = "常見"
        case unknown = "未知"
        
        var color: String {
            switch self {
            case .protected, .endangered: return "red"
            case .vulnerable: return "orange"
            case .common: return "green"
            case .unknown: return "gray"
            }
        }
        
        var icon: String {
            switch self {
            case .protected, .endangered: return "exclamationmark.shield.fill"
            case .vulnerable: return "exclamationmark.triangle.fill"
            case .common: return "checkmark.shield.fill"
            case .unknown: return "questionmark.shield.fill"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        scientificName: String,
        commonName: String,
        category: Category,
        description: String,
        habitat: String,
        distribution: String,
        protectionStatus: ProtectionStatus,
        imageUrl: String? = nil,
        location: CLLocationCoordinate2D? = nil
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.commonName = commonName
        self.category = category
        self.description = description
        self.habitat = habitat
        self.distribution = distribution
        self.protectionStatus = protectionStatus
        self.imageUrl = imageUrl
        self.locationLatitude = location?.latitude
        self.locationLongitude = location?.longitude
    }
}

extension Species {
    static let hongKongSpecies: [Species] = [
        Species(
            name: "Hong Kong Camellia",
            scientificName: "Camellia hongkongensis",
            commonName: "香港茶",
            category: .plant,
            description: "香港特有的茶花品種，是香港的市花。花朵呈粉紅色，通常在冬季開花。",
            habitat: "常綠闊葉林",
            distribution: "香港島、大嶼山",
            protectionStatus: .protected
        ),
        Species(
            name: "Chinese White Dolphin",
            scientificName: "Sousa chinensis",
            commonName: "中華白海豚",
            category: .mammal,
            description: "又稱粉紅海豚，是香港的標誌性海洋哺乳動物。身體呈粉紅色，非常稀有。",
            habitat: "近海淺水區",
            distribution: "大嶼山、屯門一帶海域",
            protectionStatus: .endangered
        ),
        Species(
            name: "Red-whiskered Bulbul",
            scientificName: "Pycnonotus jocosus",
            commonName: "紅耳鵯",
            category: .bird,
            description: "常見的留鳥，頭頂有黑色冠羽，臉頰有紅色斑塊。叫聲響亮，容易識別。",
            habitat: "城市公園、郊野公園",
            distribution: "全港常見",
            protectionStatus: .common
        ),
        Species(
            name: "Hong Kong Newt",
            scientificName: "Paramesotriton hongkongensis",
            commonName: "香港瘰螈",
            category: .amphibian,
            description: "香港特有的兩棲動物，身體呈深褐色，有橙色斑點。生活在清澈的溪流中。",
            habitat: "山間溪流",
            distribution: "新界東部",
            protectionStatus: .vulnerable
        ),
        Species(
            name: "Bamboo",
            scientificName: "Bambusoideae",
            commonName: "竹子",
            category: .plant,
            description: "常見的禾本科植物，生長迅速。香港有多種原生竹類，是重要的生態資源。",
            habitat: "山坡、溪邊",
            distribution: "全港常見",
            protectionStatus: .common
        ),
        Species(
            name: "Chinese Cobra",
            scientificName: "Naja atra",
            commonName: "中華眼鏡蛇",
            category: .reptile,
            description: "有毒蛇類，頸部有眼鏡狀斑紋。遇到威脅時會豎起前半身。請保持距離。",
            habitat: "草叢、石縫",
            distribution: "全港郊野",
            protectionStatus: .protected
        ),
        Species(
            name: "Butterfly",
            scientificName: "Lepidoptera",
            commonName: "蝴蝶",
            category: .insect,
            description: "香港有超過 200 種蝴蝶，是生物多樣性的重要指標。常見於花叢中。",
            habitat: "花園、草地、森林",
            distribution: "全港常見",
            protectionStatus: .common
        )
    ]
}

