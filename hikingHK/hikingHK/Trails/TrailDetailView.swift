//
//  TrailDetailView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

/// Detailed trail page showing map, checkpoints, facilities, highlights and transportation info.
struct TrailDetailView: View {
    let trail: Trail
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var mtrViewModel = MTRScheduleViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                trailImage
                header
                TrailMapView(trail: trail)
                timelineSection
                facilitiesSection
                highlightsSection
                transportationSection
                // MTR real-time schedule - always show, even if no schedule found
                mtrScheduleSection
                if !trail.supplyPoints.isEmpty {
                    supplyPointsSection
                }
                if !trail.exitRoutes.isEmpty {
                    exitRoutesSection
                }
                if let notes = trail.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(20)
        }
        .task {
            await mtrViewModel.loadSchedule(for: trail, languageManager: languageManager)
        }
        .background(
            ZStack {
                Color.hikingBackgroundGradient
                HikingPatternBackground()
                    .opacity(0.15)
            }
            .ignoresSafeArea()
        )
        .navigationTitle(trail.localizedName(languageManager: languageManager))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Trail hero image displayed at the top of the detail view.
    /// Supports both local asset names and remote URLs.
    private var trailImage: some View {
        Group {
            if trail.imageName.hasPrefix("http://") || trail.imageName.hasPrefix("https://") {
                // Remote URL image
                AsyncImage(url: URL(string: trail.imageName)) { phase in
                    switch phase {
                    case .empty:
                        // Placeholder while loading
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.hikingStone.opacity(0.2))
                            .frame(height: 200)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        // Fallback placeholder if URL fails
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                // Local asset image
                Image(trail.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    /// Fallback image when remote image fails to load.
    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [Color.hikingGreen.opacity(0.3), Color.hikingDarkGreen.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.hikingGreen.opacity(0.6))
                    Text(languageManager.localizedString(for: "trail.image.unavailable"))
                        .font(.caption)
                        .foregroundStyle(Color.hikingBrown.opacity(0.7))
                }
            }
    }

    /// Top summary header with district, distance, elevation and duration.
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.and.ellipse")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.hikingBrown)
                    HStack(spacing: 12) {
                        statBlock(title: languageManager.localizedString(for: "trails.distance"), value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))")
                        statBlock(title: languageManager.localizedString(for: "trails.elevation"), value: "\(trail.elevationGain) \(languageManager.localizedString(for: "unit.m"))")
                        statBlock(title: languageManager.localizedString(for: "trails.duration"), value: "\(trail.estimatedDurationMinutes / 60) \(languageManager.localizedString(for: "unit.h"))")
                    }
                }
                Spacer()
                Image(systemName: trail.difficulty.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.hikingGreen)
            }
            Text(trail.localizedSummary(languageManager: languageManager))
                .font(.body)
                .foregroundStyle(Color.hikingBrown.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .hikingCard()
    }

    /// Timeline-style list of checkpoints along the trail.
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.checkpoints"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(trail.checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            Circle()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.hikingGreen)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                            if index < trail.checkpoints.count - 1 {
                                Rectangle()
                                    .frame(width: 3, height: 50)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.hikingGreen.opacity(0.4), Color.hikingGreen.opacity(0.2)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedCheckpointTitle(checkpoint.title))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.hikingDarkGreen)
                            Text(localizedCheckpointSubtitle(checkpoint.subtitle))
                                .font(.caption)
                                .foregroundStyle(Color.hikingBrown)
                            HStack(spacing: 16) {
                                Label {
                                    Text("\(checkpoint.distanceKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))")
                                        .font(.caption.weight(.medium))
                                } icon: {
                                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color.hikingBrown.opacity(0.8))
                                Label {
                                    Text("\(checkpoint.altitude) \(languageManager.localizedString(for: "unit.m"))")
                                        .font(.caption.weight(.medium))
                                } icon: {
                                    Image(systemName: "altimeter")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color.hikingBrown.opacity(0.8))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
            .hikingCard()
        }
    }

    /// Horizontal list of trail facilities (toilets, shelters, kiosks, etc.).
    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.facilities"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trail.facilities, id: \.self) { facility in
                        VStack(spacing: 12) {
                            Image(systemName: facility.systemImage)
                                .font(.system(size: 32))
                                .foregroundStyle(Color.hikingGreen)
                            Text(localizedFacilityName(facility.name))
                                .font(.caption.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.hikingDarkGreen)
                        }
                        .frame(width: 120, height: 110)
                        .padding(.vertical, 12)
                        .hikingCard()
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Section listing key highlights of the trail.
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.highlights"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            VStack(spacing: 12) {
                ForEach(trail.highlights, id: \.self) { highlight in
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.hikingGreen)
                        Text(localizedHighlight(highlight))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.hikingGreen.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.hikingGreen.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
            .hikingCard()
        }
    }
    
    /// Returns a localized version of a highlight, falling back to the original text.
    private func localizedHighlight(_ highlight: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(highlight) {
            return highlight
        }
        
        // Create a key based on trail ID and normalized highlight text.
        let highlightKey = highlight.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let key = "trail.\(trail.id.uuidString.lowercased()).highlight.\(highlightKey)"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English highlights to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(highlight) {
            // Map common English highlights to Chinese
            let englishToChinese: [String: String] = [
                "Peak Scenery": "山頂景色",
                "Harbor Panorama": "海港全景",
                "Easy Walk": "輕鬆步行",
                "Pyramid Shape": "金字塔形狀",
                "Coastal Scenery": "海岸景色",
                "Shaded Bamboo Forest": "陰涼竹林",
                "Main Fall 35 m drop": "主瀑布 35 米落差",
                "Stream Recreation Area": "溪流遊樂區",
                "Historic Dams": "歷史堤壩",
                "Reservoir Views": "水塘景色",
                "Family Friendly": "適合家庭",
                "Shek O Peninsula Viewing Platform": "石澳半島觀景台",
                "Paragliding Launch Site": "滑翔傘起飛點",
                "Surfing Beach Finish": "衝浪海灘終點",
                "Pok Fu Lam Reservoir": "薄扶林水塘",
                "Lady Clementi's Ride": "金夫人徑",
                "Middle Gap": "中峽",
                "Black's Link": "布力徑",
                "City View": "城市景色",
                "Jardine's Lookout": "渣甸山",
                "Tai Fung Au": "大風坳",
                "Tai Tam Road": "大潭道",
                "Mountain Path Views": "山徑景色",
                "Dragon's Back Start Point": "龍脊起點",
                "Shek O Peak": "打爛埕頂山",
                "Hong Kong Trail End Point": "港島徑終點",
                "Kau Ling Chung": "狗嶺涌",
                "Shek Pik": "石壁",
                "Shek Pik Reservoir": "石壁水塘",
                "Lantau Trail End Point": "鳳凰徑終點",
                "Sunset Peak (869m)": "鳳凰山 (869m)",
                "Lantau Peak (934m)": "大東山 (934m)",
                "Wisdom Path": "心經簡林",
                "Sham Wat Road": "深屈道",
                "Big Buddha Views": "大佛景色",
                "Keung Shan Road": "羗山道",
                "Keung Shan": "羗山",
                "Lantau Island View": "大嶼山景觀",
                "Ling Wui Shan": "靈會山",
                "Man Cheung Po": "萬丈布",
                "Yi O": "二澳",
                "Tai O": "大澳",
                "Fishing Village Scenery": "漁村景色",
                "Ng Yat Kok": "牙鷹角",
                "Fan Lau": "分流",
                "Shui Hau": "水口",
                "Lion Rock (495m)": "獅子山 (495m)",
                "Iconic Landmark": "標誌性地標",
                "City Panorama": "城市全景",
                "High Island Reservoir": "萬宜水庫",
                "Long Ke Wan": "浪茄灣",
                "Clear Water and Fine Sand": "水清沙幼",
                "Sai Wan Shan": "西灣山",
                "Hong Kong's Most Beautiful Beach": "香港最優美沙灘",
                "Hwamei Shan": "畫眉山",
                "Kai Kung Shan": "雞公山",
                "Sai Kung West Peaks": "西貢西部山峰",
                "Beacon Hill": "畢架山",
                "Kowloon Reservoir": "九龍水塘",
                "New Territories Central": "新界中部",
                "Reservoir View": "水塘景觀",
                "New Territories West": "新界西部",
                "MacLehose Trail End Point": "麥理浩徑終點",
                "Needle Hill": "針山",
                "Grassy Hill": "草山",
                "Steep Climb Section": "急攀路段",
                "Tai Mo Shan (957m)": "大帽山 (957m)",
                "Hong Kong's Highest Peak": "香港最高峰",
                "Sea of Clouds View": "雲海景觀",
                "Tai Lam Country Park": "大欖郊野公園",
                "Plantation Area": "植林區",
                "Sharp Peak (468m)": "蚺蛇尖 (468m)",
                "Highest Peak": "最高峰",
                "Sea of Clouds": "雲海",
                "Violet Hill": "紫羅蘭山",
                "The Twins": "孖崗山",
                "Repulse Bay View": "淺水灣景色",
                "Mount Butler": "畢拿山",
                "City Skyline": "城市天際線",
                "Kowloon View": "九龍景觀",
                "Fei Ngo Shan": "飛鵝山",
                "Gilwell Camp": "基維爾營",
                "Sai Kung View": "西貢景觀",
                "Tate's Cairn": "大老山",
                "Sha Tin Pass": "沙田坳",
                "New Territories View": "新界景觀",
                "Shing Mun Reservoir": "城門水塘",
                "Lead Mine Pass": "鉛礦坳",
                "Pat Sin Leng": "八仙嶺",
                "Nam Chung": "南涌",
                "New Territories Northeast": "新界東北",
                "Mui Wo": "梅窩",
                "Silvermine Bay": "銀礦灣",
                "Lantau Trail Start": "鳳凰徑起點",
                "Mountain Hut": "山屋",
                "Sunset Views": "日落景色",
                "Ngong Ping": "昂坪",
                "Quarry Bay": "鰂魚涌",
                "Lion Rock": "獅子山",
                "Tin Fu Tsai": "田夫仔",
                "Tuen Mun": "屯門",
                "Tai Po Road": "大埔公路",
                "Long Ke": "浪茄",
                "Pak Tam Au": "北潭凹",
                "Pak Tam Chung": "北潭涌",
                "Pui O": "貝澳",
                "Chi Ma Wan": "芝麻灣"
            ]
            if let chinese = englishToChinese[highlight] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese highlights
        if languageManager.currentLanguage == .english && containsChineseCharacters(highlight) {
            // Map common Chinese highlights to English
            let chineseToEnglish: [String: String] = [
                "歷史堤壩": "Historic Dams",
                "水塘景色": "Reservoir Views",
                "適合家庭": "Family Friendly",
                "石澳半島觀景台": "Shek O Peninsula Viewing Platform",
                "滑翔傘起飛點": "Paragliding Launch Site",
                "衝浪海灘終點": "Surfing Beach Finish",
                "山頂景色": "Peak Scenery",
                "薄扶林水塘": "Pok Fu Lam Reservoir",
                "輕鬆步行": "Easy Walk",
                "金夫人徑": "Lady Clementi's Ride",
                "中峽": "Middle Gap",
                "布力徑": "Black's Link",
                "城市景色": "City View",
                "渣甸山": "Jardine's Lookout",
                "大風坳": "Tai Fung Au",
                "大潭道": "Tai Tam Road",
                "山徑景色": "Mountain Path Views",
                "龍脊起點": "Dragon's Back Start Point",
                "打爛埕頂山": "Shek O Peak",
                "港島徑終點": "Hong Kong Trail End Point",
                "狗嶺涌": "Kau Ling Chung",
                "石壁": "Shek Pik",
                "石壁水塘": "Shek Pik Reservoir",
                "鳳凰徑終點": "Lantau Trail End Point",
                "鳳凰山 (869m)": "Sunset Peak (869m)",
                "大東山 (934m)": "Lantau Peak (934m)",
                "心經簡林": "Wisdom Path",
                "深屈道": "Sham Wat Road",
                "大佛景色": "Big Buddha Views",
                "羗山道": "Keung Shan Road",
                "羗山": "Keung Shan",
                "大嶼山景觀": "Lantau Island View",
                "靈會山": "Ling Wui Shan",
                "萬丈布": "Man Cheung Po",
                "二澳": "Yi O",
                "大澳": "Tai O",
                "漁村景色": "Fishing Village Scenery",
                "牙鷹角": "Ng Yat Kok",
                "海岸景色": "Coastal Scenery",
                "分流": "Fan Lau",
                "水口": "Shui Hau",
                "八仙嶺": "Pat Sin Leng",
                "南涌": "Nam Chung",
                "新界東北": "New Territories Northeast",
                "獅子山 (495m)": "Lion Rock (495m)",
                "標誌性地標": "Iconic Landmark",
                "城市全景": "City Panorama",
                "萬宜水庫": "High Island Reservoir",
                "浪茄灣": "Long Ke Wan",
                "水清沙幼": "Clear Water and Fine Sand",
                "西灣山": "Sai Wan Shan",
                "香港最優美沙灘": "Hong Kong's Most Beautiful Beach",
                "畫眉山": "Hwamei Shan",
                "雞公山": "Kai Kung Shan",
                "西貢西部山峰": "Sai Kung West Peaks",
                "筆架山": "Beacon Hill",
                "九龍水塘": "Kowloon Reservoir",
                "城市景觀": "City View",
                "新界中部": "New Territories Central",
                "水塘景觀": "Reservoir View",
                "新界西部": "New Territories West",
                "麥理浩徑終點": "MacLehose Trail End Point",
                "針山": "Needle Hill",
                "草山": "Grassy Hill",
                "急攀路段": "Steep Climb Section",
                "大帽山 (957m)": "Tai Mo Shan (957m)",
                "香港最高峰": "Hong Kong's Highest Peak",
                "雲海景觀": "Sea of Clouds View",
                "大欖郊野公園": "Tai Lam Country Park",
                "植林區": "Plantation Area",
                "蚺蛇尖 (468m)": "Sharp Peak (468m)",
                "金字塔形狀": "Pyramid Shape",
                "最高峰": "Highest Peak",
                "雲海": "Sea of Clouds",
                "主瀑布 35 米落差": "Main Fall 35 m drop",
                "陰涼竹林": "Shaded Bamboo Forest",
                "溪流遊樂區": "Stream Recreation Area",
                "紫羅蘭山": "Violet Hill",
                "孖崗山": "The Twins",
                "淺水灣景色": "Repulse Bay View",
                "畢拿山": "Mount Butler",
                "城市天際線": "City Skyline",
                "九龍景觀": "Kowloon View",
                "飛鵝山": "Fei Ngo Shan",
                "基維爾營": "Gilwell Camp",
                "西貢景觀": "Sai Kung View",
                "新界景觀": "New Territories View"
            ]
            return chineseToEnglish[highlight] ?? highlight
        }
        
        return highlight
    }

    /// Section describing how to reach the trailhead and return from the finish.
    private var transportationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.transportation"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // 起點交通
                if let startTransport = trail.startPointTransport, !startTransport.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(languageManager.localizedString(for: "trail.start.point"), systemImage: "location.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hikingGreen)
                        Text(localizedStartTransport)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown.opacity(0.8))
                    }
                }
                
                // 終點交通
                if let endTransport = trail.endPointTransport, !endTransport.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(languageManager.localizedString(for: "trail.end.point"), systemImage: "flag.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hikingGreen)
                        Text(localizedEndTransport)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown.opacity(0.8))
                    }
                }
                
                // 如果沒有分開的起終點，使用舊的 transportation
                if trail.startPointTransport == nil && trail.endPointTransport == nil {
                    Text(localizedTransportation)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown.opacity(0.8))
                }
            }
            .padding(20)
            .hikingCard()
        }
    }
    
    /// Section listing supply points along the trail.
    private var supplyPointsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.supply.points"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(trail.supplyPoints, id: \.self) { supply in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Color.hikingGreen)
                            .font(.subheadline)
                        Text(localizedSupplyPoint(supply))
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown.opacity(0.8))
                    }
                }
            }
            .padding(20)
            .hikingCard()
        }
    }
    
    /// Section listing exit routes from the trail.
    private var exitRoutesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.turn.up.right")
                    .foregroundStyle(Color.hikingBrown)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.exit.routes"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(trail.exitRoutes, id: \.self) { exit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundStyle(Color.hikingBrown)
                            .font(.subheadline)
                        Text(localizedExitRoute(exit))
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown.opacity(0.8))
                    }
                }
            }
            .padding(20)
            .hikingCard()
        }
    }
    
    /// Section displaying important notes and warnings.
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.hikingBrown)
                    .font(.headline)
                Text(languageManager.localizedString(for: "trail.notes"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.hikingBrown)
                    .font(.subheadline)
                Text(localizedNotes(notes))
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown.opacity(0.8))
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.hikingBrown.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.hikingBrown.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var localizedTransportation: String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(trail.transportation) {
            return trail.transportation
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).transportation"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, return original (will be handled by adding localization strings)
        // In English mode, if original text contains Chinese, return original (will be handled by adding localization strings)
        return trail.transportation
    }
    
    private var localizedStartTransport: String {
        guard let startTransport = trail.startPointTransport else { return "" }
        
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(startTransport) {
            return startTransport
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).start.transport"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English transport to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(startTransport) {
            // Map common English start transport to Chinese
            let englishToChinese: [String: String] = [
                "Take bus 51 from Route Twisk": "從荃錦公路乘巴士 51",
                "Bus 64K/64P to Ng Tung Chai village": "乘搭 64K/64P 巴士前往梧桐寨村",
                "Peak Tram or Bus 15 to The Peak": "乘山頂纜車或巴士 15 到山頂",
                "MTR Wong Tai Sin Station, walk to Lion Rock Park": "港鐵黃大仙站，步行至獅子山公園",
                "Take bus 94 from Pak Tam Chung, then transfer to taxi to High Island Reservoir": "從北潭涌乘巴士 94，再轉乘的士到萬宜水庫",
                "Bus 6/6X/260 to Stanley Gap": "乘巴士 6/6X/260 到赤柱峽"
            ]
            if let chinese = englishToChinese[startTransport] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese transport to English
        if languageManager.currentLanguage == .english && containsChineseCharacters(startTransport) {
            // Map common Chinese start transport to English
            let chineseToEnglish: [String: String] = [
                "從元墩下乘巴士 64K": "Take bus 64K from Yuen Tun Ha",
                "從荃錦公路乘巴士 51": "Take bus 51 from Route Twisk",
                "從鉛礦坳乘巴士 51": "Take bus 51 from Lead Mine Pass",
                "乘搭 64K/64P 巴士前往梧桐寨村": "Bus 64K/64P to Ng Tung Chai village",
                "乘山頂纜車或巴士 15 到山頂": "Peak Tram or Bus 15 to The Peak",
                "港鐵黃大仙站，步行至獅子山公園": "MTR Wong Tai Sin Station, walk to Lion Rock Park",
                "從北潭涌乘巴士 94，再轉乘的士到萬宜水庫": "Take bus 94 from Pak Tam Chung, then transfer to taxi to High Island Reservoir",
                "乘巴士 6/6X/260 到赤柱峽": "Bus 6/6X/260 to Stanley Gap"
            ]
            if let english = chineseToEnglish[startTransport] {
                return english
            }
        }
        
        return startTransport
    }
    
    private var localizedEndTransport: String {
        guard let endTransport = trail.endPointTransport else { return "" }
        
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(endTransport) {
            return endTransport
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).end.transport"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English transport to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(endTransport) {
            // Map common English end transport to Chinese
            let englishToChinese: [String: String] = [
                "Take bus 51 from Tai Mo Shan Visitor Center": "從大帽山遊客中心乘巴士 51 返回",
                "Take bus 64K/64P from Ng Tung Chai village": "從梧桐寨村乘巴士 64K/64P 返回",
                "Take Peak Tram or Bus 15 from The Peak": "從山頂乘山頂纜車或巴士 15 返回",
                "Take bus 1/7M from Lion Rock Park": "從獅子山公園乘巴士 1/7M 返回",
                "Need to return via original route or take boat from Big Wave Bay": "從大浪灣需原路返回或乘船離開",
                "Take bus 6 from Violet Hill": "從紫羅蘭山乘巴士 6 離開"
            ]
            if let chinese = englishToChinese[endTransport] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese transport to English
        if languageManager.currentLanguage == .english && containsChineseCharacters(endTransport) {
            // Map common Chinese end transport to English
            let chineseToEnglish: [String: String] = [
                "從南涌乘巴士 78K 返回": "Take bus 78K from Nam Chung",
                "從大帽山遊客中心乘巴士 51 返回": "Take bus 51 from Tai Mo Shan Visitor Center",
                "從荃錦公路乘巴士 51 返回": "Take bus 51 from Route Twisk",
                "從梧桐寨村乘巴士 64K/64P 返回": "Take bus 64K/64P from Ng Tung Chai village",
                "從山頂乘山頂纜車或巴士 15 返回": "Take Peak Tram or Bus 15 from The Peak",
                "從獅子山公園乘巴士 1/7M 返回": "Take bus 1/7M from Lion Rock Park",
                "從大浪灣需原路返回或乘船離開": "Need to return via original route or take boat from Big Wave Bay",
                "從紫羅蘭山乘巴士 6 離開": "Take bus 6 from Violet Hill"
            ]
            if let english = chineseToEnglish[endTransport] {
                return english
            }
        }
        
        return endTransport
    }
    
    private func localizedSupplyPoint(_ supply: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(supply) {
            return supply
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).supply.\(supply.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English supply points to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(supply) {
            // Map common English supply points to Chinese
            let englishToChinese: [String: String] = [
                "No supplies along the route, bring your own water": "沿途無補給，需自備食水",
                "Supply points at Tai Mo Shan Visitor Center": "大帽山遊客中心有補給點",
                "Shops at Ng Tung Chai village": "梧桐寨村有商店",
                "Stream water available along the route for replenishment": "沿途有溪水可補充",
                "Supply points and restaurants at The Peak": "山頂有補給點和餐廳",
                "Restaurants and shops along the route": "沿途有餐廳和商店",
                "Supply points at Lion Rock Park": "獅子山公園有補給點",
                "Supply points at Big Wave Bay": "大浪灣有補給點"
            ]
            if let chinese = englishToChinese[supply] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese supply points
        if languageManager.currentLanguage == .english && containsChineseCharacters(supply) {
            // Map common Chinese supply points to English
            let chineseToEnglish: [String: String] = [
                "沿途無補給，需自備食水": "No supplies along the route, bring your own water",
                "大帽山遊客中心有補給點": "Supply points at Tai Mo Shan Visitor Center",
                "梧桐寨村有商店": "Shops at Ng Tung Chai village",
                "沿途有溪水可補充": "Stream water available along the route for replenishment",
                "山頂有補給點和餐廳": "Supply points and restaurants at The Peak",
                "沿途有餐廳和商店": "Restaurants and shops along the route",
                "獅子山公園有補給點": "Supply points at Lion Rock Park",
                "大浪灣有補給點": "Supply points at Big Wave Bay",
                "南涌有補給點": "Supply points at Nam Chung",
                "沿途有燒烤場": "BBQ areas along the route",
                "赤柱有補給點和餐廳": "Supply points and restaurants in Stanley",
                "水浪窩有士多": "Shops at Shui Long Wo",
                "昂平高原附近有補給點": "Supply points near Ngong Ping Plateau"
            ]
            return chineseToEnglish[supply] ?? supply
        }
        
        return supply
    }
    
    private func localizedExitRoute(_ exit: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(exit) {
            return exit
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).exit.\(exit.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English exit routes to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(exit) {
            // Map common English exit routes to Chinese
            let englishToChinese: [String: String] = [
                "Can exit mid-route, but it's difficult": "可在中途退出，但較為困難",
                "Can take bus from Tai Mo Shan Visitor Center": "大帽山遊客中心可乘巴士離開",
                "Can exit mid-route and return to Ng Tung Chai village": "可在中途退出，返回梧桐寨村",
                "Return via original route to start point": "需原路返回起點",
                "Can exit at any time and return to The Peak": "可隨時退出，返回山頂",
                "Can take Peak Tram or bus from The Peak": "可從山頂乘纜車或巴士離開",
                "Can take bus from Lion Rock Park": "可從獅子山公園乘巴士離開",
                "Can take boat from Big Wave Bay or return via original route": "可從大浪灣乘船離開或原路返回",
                "Can take bus from Violet Hill": "可從紫羅蘭山乘巴士離開",
                "Take bus 6/6X/260 to Stanley Gap": "乘巴士 6/6X/260 到赤柱峽",
                "Take bus 6 from Violet Hill": "從紫羅蘭山乘巴士 6 離開"
            ]
            if let chinese = englishToChinese[exit] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese exit routes
        if languageManager.currentLanguage == .english && containsChineseCharacters(exit) {
            // Map common Chinese exit routes to English
            let chineseToEnglish: [String: String] = [
                "可在中途退出，但較為困難": "Can exit mid-route, but it's difficult",
                "大帽山遊客中心可乘巴士離開": "Can take bus from Tai Mo Shan Visitor Center",
                "可在中途退出，返回梧桐寨村": "Can exit mid-route and return to Ng Tung Chai village",
                "需原路返回起點": "Return via original route to start point",
                "可隨時退出，返回山頂": "Can exit at any time and return to The Peak",
                "可從山頂乘纜車或巴士離開": "Can take Peak Tram or bus from The Peak",
                "可從獅子山公園乘巴士離開": "Can take bus from Lion Rock Park",
                "可從大浪灣乘船離開或原路返回": "Can take boat from Big Wave Bay or return via original route",
                "可從紫羅蘭山乘巴士離開": "Can take bus from Violet Hill",
                "南涌可乘巴士離開": "Can take bus from Nam Chung",
                "荃錦公路可乘巴士離開": "Can take bus from Route Twisk",
                "赤柱可乘巴士離開": "Can take bus from Stanley",
                "可在昂平高原退出，返回馬鞍山": "Can exit at Ngong Ping Plateau and return to Ma On Shan",
                "大老山隧道口可乘車離開": "Can take transport from Tate's Cairn Tunnel"
            ]
            return chineseToEnglish[exit] ?? exit
        }
        
        return exit
    }
    
    private func localizedNotes(_ notes: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(notes) {
            return notes
        }
        
        let key = "trail.\(trail.id.uuidString.lowercased()).notes"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English notes to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(notes) {
            // Map common English notes to Chinese (partial matching for long texts)
            let englishToChinese: [String: String] = [
                "This route requires climbing Hong Kong's highest peak, Tai Mo Shan. The summit is often shrouded in clouds, so be mindful of warmth. Some sections are steep, so be careful. It's recommended to bring sufficient water and energy. Tai Mo Shan is famous for its sea of clouds view.": "此路段需登上香港最高峰大帽山，較為困難。山頂經常被雲霧籠罩，需注意保暖。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。大帽山以雲海景觀聞名。",
                "Suitable for family visits. Some sections are slippery, so it's recommended to wear non-slip shoes. Rocks near waterfalls are slippery, so be careful.": "適合家庭遊覽。部分路段較為濕滑，建議穿著防滑鞋。瀑布附近的石頭較為濕滑，需注意安全。",
                "This is a circular walking trail, relatively easy. You can enjoy panoramic views of Hong Kong Island and Victoria Harbour. Suitable for family visits. Restaurants and shops are available along the route.": "這是一條環迴步行徑，較為輕鬆。可欣賞香港島和維多利亞港的全景。適合家庭遊覽。沿途有餐廳和商店。",
                "This route is Hong Kong's iconic Lion Rock, which is challenging. The summit offers panoramic views of Kowloon and Hong Kong Island. Some sections are steep, so be careful. It's recommended to bring sufficient water and energy.": "此路線為香港標誌性的獅子山，較為困難。山頂可欣賞九龍和香港島的全景。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。",
                "This is one of Hong Kong's most challenging routes, requiring climbing Sharp Peak. Sharp Peak is famous for its pyramid shape, and some sections are extremely steep, requiring hands and feet. It's recommended to bring sufficient water and energy, and be careful. Not suitable for beginners.": "此路線為香港最困難的路線之一，需攀越蚺蛇尖。蚺蛇尖以金字塔形狀聞名，部分路段極為陡峭，需手腳並用。建議帶備充足食水和體力，並注意安全。不適合初學者。",
                "This section requires climbing Violet Hill and The Twins, and is more strenuous. You can enjoy views of Repulse Bay and South Bay. Some sections are steep, so be careful.": "此路段需攀越紫羅蘭山和孖崗山，較為費力。可欣賞淺水灣和南灣的景色。部分路段較為陡峭，需注意安全。"
            ]
            if let chinese = englishToChinese[notes] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese notes to English
        if languageManager.currentLanguage == .english && containsChineseCharacters(notes) {
            // Map common Chinese notes to English
            let chineseToEnglish: [String: String] = [
                "此路段需登上香港最高峰大帽山，較為困難。山頂經常被雲霧籠罩，需注意保暖。建議帶備充足食水和體力。部分路段較為陡峭，需注意安全。": "This route requires climbing Hong Kong's highest peak, Tai Mo Shan. The summit is often shrouded in clouds, so be mindful of warmth. It's recommended to bring sufficient water and energy. Some sections are steep, so be careful.",
                "此路段需登上香港最高峰大帽山，較為困難。山頂經常被雲霧籠罩，需注意保暖。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。大帽山以雲海景觀聞名。": "This route requires climbing Hong Kong's highest peak, Tai Mo Shan. The summit is often shrouded in clouds, so be mindful of warmth. Some sections are steep, so be careful. It's recommended to bring sufficient water and energy. Tai Mo Shan is famous for its sea of clouds view.",
                "適合家庭遊覽。部分路段較為濕滑，建議穿著防滑鞋。瀑布附近的石頭較為濕滑，需注意安全。": "Suitable for family visits. Some sections are slippery, so it's recommended to wear non-slip shoes. Rocks near waterfalls are slippery, so be careful.",
                "這是一條環迴步行徑，較為輕鬆。可欣賞香港島和維多利亞港的全景。適合家庭遊覽。沿途有餐廳和商店。": "This is a circular walking trail, relatively easy. You can enjoy panoramic views of Hong Kong Island and Victoria Harbour. Suitable for family visits. Restaurants and shops are available along the route.",
                "此路線為香港標誌性的獅子山，較為困難。山頂可欣賞九龍和香港島的全景。部分路段較為陡峭，需注意安全。建議帶備充足食水和體力。": "This route is Hong Kong's iconic Lion Rock, which is challenging. The summit offers panoramic views of Kowloon and Hong Kong Island. Some sections are steep, so be careful. It's recommended to bring sufficient water and energy.",
                "此路線為香港最困難的路線之一，需攀越蚺蛇尖。蚺蛇尖以金字塔形狀聞名，部分路段極為陡峭，需手腳並用。建議帶備充足食水和體力，並注意安全。不適合初學者。": "This is one of Hong Kong's most challenging routes, requiring climbing Sharp Peak. Sharp Peak is famous for its pyramid shape, and some sections are extremely steep, requiring hands and feet. It's recommended to bring sufficient water and energy, and be careful. Not suitable for beginners.",
                "此路段需攀越紫羅蘭山和孖崗山，較為費力。可欣賞淺水灣和南灣的景色。部分路段較為陡峭，需注意安全。": "This section requires climbing Violet Hill and The Twins, and is more strenuous. You can enjoy views of Repulse Bay and South Bay. Some sections are steep, so be careful.",
                "此路段需攀越八仙嶺，較為費力。可欣賞新界東北的景觀。部分路段較為暴露，需注意防曬。建議帶備充足食水。南涌為衛奕信徑終點。": "This section requires climbing Pat Sin Leng, which is more strenuous. You can enjoy the scenery of the Northeast New Territories. Some sections are more exposed, so pay attention to sun protection. It is recommended to bring plenty of drinking water. Nam Chung is the end point of the Wilson Trail."
            ]
            if let english = chineseToEnglish[notes] {
                return english
            }
        }
        
        return notes
    }
    
    /// Section displaying MTR real-time train schedules
    private var mtrScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tram.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.headline)
                Text(languageManager.localizedString(for: "mtr.real.time.schedule"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                if mtrViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.hikingGreen)
                } else {
                    Button {
                        Task {
                            await mtrViewModel.loadSchedule(for: trail, languageManager: languageManager)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingGreen)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.hikingGreen.opacity(0.1))
                            )
                    }
                }
            }
            
            if let error = mtrViewModel.error {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.hikingBrown)
                        .font(.subheadline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.hikingBrown.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.hikingBrown.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            if let schedule = mtrViewModel.schedule {
                VStack(alignment: .leading, spacing: 16) {
                    // UP direction trains
                    if let upTrains = schedule.UP, !upTrains.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Direction header showing destination
                            let mainDestination = getMainDestination(from: upTrains)
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(languageManager.localizedString(for: "transport.mtr.towards"))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.hikingBrown)
                                    Text(mainDestination)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.hikingDarkGreen)
                                }
                            }
                            .padding(.bottom, 4)
                            
                            // Train times
                            ForEach(Array(upTrains.prefix(4))) { train in
                                HStack(spacing: 12) {
                                    // Destination station
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(Color.hikingGreen)
                                            .font(.subheadline)
                                        Text(getStationName(train.dest))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.hikingDarkGreen)
                                    }
                                    
                                    Spacer()
                                    
                                    // Arrival time badge
                                    Text(formatTrainTime(train.formattedTime))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.hikingGreen, Color.hikingDarkGreen],
                                                        startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.hikingGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.hikingGreen.opacity(0.05))
                                )
                            }
                        }
                        .padding()
                        .hikingCard()
                    }
                    
                    // DOWN direction trains
                    if let downTrains = schedule.DOWN, !downTrains.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Direction header showing destination
                            let mainDestination = getMainDestination(from: downTrains)
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .foregroundStyle(Color.hikingGreen)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(languageManager.localizedString(for: "transport.mtr.towards"))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.hikingBrown)
                                    Text(mainDestination)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.hikingDarkGreen)
                                }
                            }
                            .padding(.bottom, 4)
                            
                            // Train times
                            ForEach(Array(downTrains.prefix(4))) { train in
                                HStack(spacing: 12) {
                                    // Destination station
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(Color.hikingGreen)
                                            .font(.subheadline)
                                        Text(getStationName(train.dest))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.hikingDarkGreen)
                                    }
                                    
                                    Spacer()
                                    
                                    // Arrival time badge
                                    Text(formatTrainTime(train.formattedTime))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.hikingGreen, Color.hikingDarkGreen],
                                                        startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color.hikingGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.hikingGreen.opacity(0.05))
                                )
                            }
                        }
                        .padding()
                        .hikingCard()
                    }
                }
            } else if !mtrViewModel.isLoading && mtrViewModel.error == nil {
                // Show message when no station found but no error occurred
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.hikingBrown)
                        .font(.subheadline)
                    Text(languageManager.localizedString(for: "mtr.no.station.found"))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.hikingBrown.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.hikingBrown.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    /// Format train time string (e.g., "1 分鐘" or "即將到達")
    private func formatTrainTime(_ time: String) -> String {
        if time.lowercased().contains("arriving") || time == "Arr" || time == "0" {
            return languageManager.localizedString(for: "mtr.arriving")
        }
        
        // Check if time already contains unit (min, 分鐘, etc.)
        let timeLower = time.lowercased().trimmingCharacters(in: .whitespaces)
        if timeLower.contains("min") || timeLower.contains("分鐘") || timeLower.contains("分钟") {
            // Already has unit, return as is
            return time
        }
        
        // Extract numeric value
        let numericString = time.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "min", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "分鐘", with: "")
            .replacingOccurrences(of: "分钟", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        if let minutes = Int(numericString) {
            return "\(minutes) \(languageManager.localizedString(for: "mtr.minutes"))"
        }
        
        return time
    }
    
    /// Get the main destination from a list of trains (most common destination)
    private func getMainDestination(from trains: [MTRTrain]) -> String {
        // Count destinations and return the most common one
        let destinationCounts = Dictionary(grouping: trains, by: { $0.dest })
            .mapValues { $0.count }
        
        if let mostCommon = destinationCounts.max(by: { $0.value < $1.value }) {
            return getStationName(mostCommon.key)
        }
        
        // Fallback: return first destination
        if let firstDest = trains.first?.dest {
            return getStationName(firstDest)
        }
        
        return languageManager.localizedString(for: "mtr.direction.up")
    }
    
    /// Convert MTR station code to localized name
    private func getStationName(_ code: String) -> String {
        let stationNames: [String: (tc: String, en: String)] = [
            // Island Line
            "CEN": (tc: "中環", en: "Central"),
            "ADM": (tc: "金鐘", en: "Admiralty"),
            "WAC": (tc: "灣仔", en: "Wan Chai"),
            "CAB": (tc: "銅鑼灣", en: "Causeway Bay"),
            "TIH": (tc: "天后", en: "Tin Hau"),
            "FOH": (tc: "炮台山", en: "Fortress Hill"),
            "NOP": (tc: "北角", en: "North Point"),
            "QUB": (tc: "鰂魚涌", en: "Quarry Bay"),
            "TAK": (tc: "太古城", en: "Tai Koo"),
            "SWH": (tc: "西灣河", en: "Sai Wan Ho"),
            "SKW": (tc: "筲箕灣", en: "Shau Kei Wan"),
            "HFC": (tc: "杏花邨", en: "Heng Fa Chuen"),
            "CHW": (tc: "柴灣", en: "Chai Wan"),
            
            // Tsuen Wan Line
            "TSW": (tc: "荃灣", en: "Tsuen Wan"),
            "TWS": (tc: "荃灣西", en: "Tsuen Wan West"),
            "TWW": (tc: "大窩口", en: "Tai Wo Hau"),
            "KWF": (tc: "葵興", en: "Kwai Hing"),
            "KWH": (tc: "葵芳", en: "Kwai Fong"),
            "LAK": (tc: "荔景", en: "Lai King"),
            "MEF": (tc: "美孚", en: "Mei Foo"),
            "PRE": (tc: "荔枝角", en: "Lai Chi Kok"),
            "CSW": (tc: "長沙灣", en: "Cheung Sha Wan"),
            "SHM": (tc: "深水埗", en: "Sham Shui Po"),
            "MOK": (tc: "旺角", en: "Mong Kok"),
            "YMT": (tc: "油麻地", en: "Yau Ma Tei"),
            "JOR": (tc: "佐敦", en: "Jordan"),
            "TST": (tc: "尖沙咀", en: "Tsim Sha Tsui"),
            
            // Kwun Tong Line
            "WHC": (tc: "黃大仙", en: "Wong Tai Sin"),
            "DIH": (tc: "鑽石山", en: "Diamond Hill"),
            "CHH": (tc: "彩虹", en: "Choi Hung"),
            "KOB": (tc: "九龍灣", en: "Kowloon Bay"),
            "NTK": (tc: "牛頭角", en: "Ngau Tau Kok"),
            "KWT": (tc: "觀塘", en: "Kwun Tong"),
            "LAT": (tc: "藍田", en: "Lam Tin"),
            "YAT": (tc: "油塘", en: "Yau Tong"),
            "TIK": (tc: "調景嶺", en: "Tiu Keng Leng"),
            
            // Tseung Kwan O Line
            "TKO": (tc: "將軍澳", en: "Tseung Kwan O"),
            "HAH": (tc: "坑口", en: "Hang Hau"),
            "POA": (tc: "寶琳", en: "Po Lam"),
            "LHP": (tc: "康城", en: "LOHAS Park"),
            
            // Tung Chung Line
            "TUC": (tc: "東涌", en: "Tung Chung"),
            "SUN": (tc: "欣澳", en: "Sunny Bay"),
            "TSY": (tc: "青衣", en: "Tsing Yi"),
            "AWE": (tc: "機場", en: "Airport"),
            "AEL": (tc: "博覽館", en: "AsiaWorld-Expo"),
            
            // East Rail Line
            "HUH": (tc: "紅磡", en: "Hung Hom"),
            "ETS": (tc: "尖東", en: "East Tsim Sha Tsui"),
            "MKK": (tc: "旺角東", en: "Mong Kok East"),
            "KOT": (tc: "九龍塘", en: "Kowloon Tong"),
            "TAW": (tc: "大圍", en: "Tai Wai"),
            "SHT": (tc: "沙田", en: "Sha Tin"),
            "FOT": (tc: "火炭", en: "Fo Tan"),
            "RAC": (tc: "馬場", en: "Racecourse"),
            "UNI": (tc: "大學", en: "University"),
            "TAP": (tc: "大埔墟", en: "Tai Po Market"),
            "TWO": (tc: "太和", en: "Tai Wo"),
            "FAN": (tc: "粉嶺", en: "Fanling"),
            "SHS": (tc: "上水", en: "Sheung Shui"),
            "LOW": (tc: "羅湖", en: "Lo Wu"),
            "LMC": (tc: "落馬洲", en: "Lok Ma Chau"),
            
            // Tuen Ma Line
            "TUM": (tc: "屯門", en: "Tuen Mun"),
            "SIH": (tc: "兆康", en: "Siu Hong"),
            "TIS": (tc: "天水圍", en: "Tin Shui Wai"),
            "YUL": (tc: "元朗", en: "Yuen Long"),
            "KSR": (tc: "錦上路", en: "Kam Sheung Road"),
            "LOP": (tc: "朗屏", en: "Long Ping"),
            "WKS": (tc: "烏溪沙", en: "Wu Kai Sha"),
            "MOS": (tc: "馬鞍山", en: "Ma On Shan"),
            "HEO": (tc: "恆安", en: "Heng On"),
            "AFC": (tc: "大水坑", en: "Tai Shui Hang"),
            "WHA": (tc: "沙田圍", en: "Sha Tin Wai"),
            "CIO": (tc: "車公廟", en: "Che Kung Temple"),
            "STW": (tc: "石門", en: "Shek Mun"),
            "FIR": (tc: "第一城", en: "City One"),
            "SHO": (tc: "沙田圍", en: "Sha Tin Wai"),
            "HIK": (tc: "顯徑", en: "Hin Keng"),
            "HOM": (tc: "何文田", en: "Ho Man Tin"),
            "HOK": (tc: "香港", en: "Hong Kong"),
            "KOW": (tc: "九龍", en: "Kowloon"),
            "AUS": (tc: "柯士甸", en: "Austin"),
            "EXC": (tc: "會展", en: "Exhibition Centre"),
            "NAC": (tc: "南昌", en: "Nam Cheong"),
            
            // South Island Line
            "OCP": (tc: "海洋公園", en: "Ocean Park"),
            "WCH": (tc: "黃竹坑", en: "Wong Chuk Hang"),
            "LET": (tc: "利東", en: "Lei Tung"),
            "SOH": (tc: "海怡半島", en: "South Horizons"),
            
            // Disneyland Resort Line
            "DIS": (tc: "迪士尼", en: "Disneyland Resort"),
            
            // Airport Express
            "AIR": (tc: "機場", en: "Airport"),
            
            // Other common stations
            "KET": (tc: "堅尼地城", en: "Kennedy Town"),
        ]
        
        if let names = stationNames[code] {
            return languageManager.currentLanguage == .english ? names.en : names.tc
        }
        return code
    }

    /// Helper function to check if a string contains Chinese characters
    private func containsChineseCharacters(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||
            (0x3400...0x4DBF).contains(scalar.value)
        }
    }
    
    private func localizedCheckpointTitle(_ title: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(title) {
            return title
        }
        
        // Normalize the title key
        let normalizedTitle = title.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "-", with: ".")
        let key = "checkpoint.\(normalizedTitle)"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English place names to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(title) {
            // Map common English place names to Chinese
            let englishToChinese: [String: String] = [
                "Ng Tung Chai": "梧桐寨",
                "Lower Waterfall": "下瀑布",
                "Main Waterfall": "主瀑布",
                "Route Twisk": "荃錦公路",
                "Tai Mo Shan": "大帽山",
                "Lead Mine Pass": "鉛礦坳",
                "Lugard Road": "盧吉道",
                "Lion Rock Park": "獅子山公園",
                "Lion Rock": "獅子山",
                "Sha Tin Pass": "沙田坳",
                "Stanley Gap": "赤柱峽",
                "Violet Hill": "紫羅蘭山",
                "The Twins": "孖崗山",
                "Mount Butler": "畢拿山",
                "Quarry Bay": "鰂魚涌",
                "Beacon Hill": "畢架山",
                "Fei Ngo Shan": "飛鵝山",
                "Gilwell Camp": "基維爾營",
                "High Island Reservoir": "萬宜水庫",
                "Yuen Tun Ha": "元墩下",
                "Grassy Hill": "草山",
                "Needle Hill": "針山",
                "Shing Mun Reservoir": "城門水塘",
                "The Peak": "山頂",
                "Big Wave Bay": "大浪灣",
                "Tin Fu Tsai": "田夫仔",
                "Tuen Mun": "屯門",
                "Tai Po Road": "大埔公路",
                "Long Ke": "浪茄",
                "Sai Wan Shan": "西灣山",
                "Pak Tam Au": "北潭凹",
                "Pak Tam Chung": "北潭涌",
                "Hwamei Shan": "畫眉山",
                "Kai Kung Shan": "雞公山",
                "Ngong Ping": "昂坪",
                "Wisdom Path": "心經簡林",
                "Sham Wat Road": "深屈道",
                "Shui Hau": "水口",
                "Pui O": "貝澳",
                "Chi Ma Wan": "芝麻灣",
                "Mui Wo": "梅窩"
            ]
            if let chinese = englishToChinese[title] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese place names
        if languageManager.currentLanguage == .english && containsChineseCharacters(title) {
            // Map common Chinese place names to English
            let chineseToEnglish: [String: String] = [
                "大潭": "Tai Tam",
                "大潭上水塘": "Tai Tam Upper Reservoir",
                "赤柱": "Stanley",
                "土地灣": "To Tei Wan",
                "龍脊": "Dragon's Back Ridge",
                "大浪灣": "Big Wave Bay",
                "水浪窩": "Shui Long Wo",
                "馬鞍山": "Ma On Shan",
                "昂平高原": "Ngong Ping Plateau",
                "大老山": "Tate's Cairn",
                "梅窩": "Mui Wo",
                "鳳凰山": "Sunset Peak",
                "伯公坳": "Pak Kung Au",
                "銀礦灣": "Silvermine Bay",
                "南山": "Nam Shan",
                "大東山": "Lantau Peak",
                "昂坪": "Ngong Ping",
                "心經簡林": "Wisdom Path",
                "深屈道": "Sham Wat Road",
                "羗山": "Keung Shan",
                "靈會山": "Ling Wui Shan",
                "萬丈布": "Man Cheung Po",
                "二澳": "Yi O",
                "大澳": "Tai O",
                "牙鷹角": "Ng Yat Kok",
                "分流": "Fan Lau",
                "水口": "Shui Hau",
                "貝澳": "Pui O",
                "芝麻灣": "Chi Ma Wan",
                "山頂": "The Peak",
                "薄扶林": "Pok Fu Lam",
                "薄扶林水塘": "Pok Fu Lam Reservoir",
                "貝璐道": "Peel Rise",
                "中峽": "Middle Gap",
                "灣仔峽": "Wan Chai Gap",
                "渣甸山": "Jardine's Lookout",
                "黃泥涌峽": "Wong Nai Chung Gap",
                "柏架山道": "Mount Parker Road",
                "大風坳": "Tai Fung Au",
                "大潭道": "Tai Tam Road",
                "大潭水塘": "Tai Tam Reservoir",
                "打爛埕頂山": "Shek O Peak",
                "狗嶺涌": "Kau Ling Chung",
                "石壁": "Shek Pik",
                "石壁水塘": "Shek Pik Reservoir",
                "獅子山公園": "Lion Rock Park",
                "獅子山": "Lion Rock",
                "沙田坳": "Sha Tin Pass",
                "北潭涌": "Pak Tam Chung",
                "浪茄": "Long Ke",
                "西灣山": "Sai Wan Shan",
                "北潭凹": "Pak Tam Au",
                "畫眉山": "Hwamei Shan",
                "雞公山": "Kai Kung Shan",
                "八仙嶺": "Pat Sin Leng",
                "南涌": "Nam Chung",
                "筆架山": "Beacon Hill",
                "大埔公路": "Tai Po Road",
                "城門水塘": "Shing Mun Reservoir",
                "田夫仔": "Tin Fu Tsai",
                "屯門": "Tuen Mun",
                "針山": "Needle Hill",
                "草山": "Grassy Hill",
                "鉛礦坳": "Lead Mine Pass",
                "大帽山": "Tai Mo Shan",
                "荃錦公路": "Route Twisk",
                "梧桐寨": "Ng Tung Chai",
                "下瀑布": "Lower Waterfall",
                "主瀑布": "Main Waterfall",
                "蚺蛇尖": "Sharp Peak",
                "赤柱峽": "Stanley Gap",
                "孖崗山": "The Twins",
                "畢拿山": "Mount Butler",
                "鰂魚涌": "Quarry Bay",
                "畢架山": "Beacon Hill",
                "飛鵝山": "Fei Ngo Shan",
                "基維爾營": "Gilwell Camp",
                "萬宜水庫": "High Island Reservoir",
                "元墩下": "Yuen Tun Ha"
            ]
            return chineseToEnglish[title] ?? title
        }
        
        return title
    }
    
    private func localizedCheckpointSubtitle(_ subtitle: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(subtitle) {
            return subtitle
        }
        
        // Normalize the subtitle key
        let normalizedSubtitle = subtitle.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
        let key = "checkpoint.\(normalizedSubtitle)"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English terms to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(subtitle) {
            // Map common English checkpoint subtitles to Chinese
            let englishToChinese: [String: String] = [
                "Start Point": "起點",
                "End Point": "終點",
                "Start/End Point": "起點/終點",
                "Photo Stop": "拍照點",
                "Photo Spot": "拍照點",
                "Viewpoint": "觀景台",
                "Viewing Platform": "觀景台",
                "Supply Point": "補給點",
                "Exit Point": "退出點",
                "Halfway Point": "中途點",
                "Midpoint": "中途點",
                "Peak": "山峰",
                "Plateau": "高原",
                "Reservoir": "水塘",
                "Beach": "海灘"
            ]
            if let chinese = englishToChinese[subtitle] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese terms
        if languageManager.currentLanguage == .english && containsChineseCharacters(subtitle) {
            // Map common Chinese checkpoint subtitles to English
            let chineseToEnglish: [String: String] = [
                "起點": "Start Point",
                "終點": "End Point",
                "拍照點": "Photo Spot",
                "觀景台": "Viewing Platform",
                "補給點": "Supply Point",
                "退出點": "Exit Point",
                "中途點": "Halfway Point",
                "山峰": "Peak",
                "高原": "Plateau",
                "水塘": "Reservoir"
            ]
            return chineseToEnglish[subtitle] ?? subtitle
        }
        
        return subtitle
    }
    
    private func localizedFacilityName(_ name: String) -> String {
        // In Traditional Chinese mode, if original text is Chinese, return it directly
        if languageManager.currentLanguage == .traditionalChinese && containsChineseCharacters(name) {
            return name
        }
        
        let normalizedName = name.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
        let key = "facility.\(normalizedName)"
        let localized = languageManager.localizedString(for: key)
        
        // If localization found, return it
        if localized != key {
            return localized
        }
        
        // In Traditional Chinese mode, if original text is English, try to map common English facility names to Chinese
        if languageManager.currentLanguage == .traditionalChinese && !containsChineseCharacters(name) {
            // Map common English facility names to Chinese
            let englishToChinese: [String: String] = [
                "BBQ Area": "燒烤場",
                "Toilet": "洗手間",
                "Country Park Toilet": "郊野公園洗手間",
                "Pavilion": "涼亭",
                "Big Wave Bay Shower Facilities": "大浪灣淋浴設施",
                "Water Station": "水站",
                "Mountain Hut": "山屋",
                "Camping": "露營",
                "Ngong Ping Village": "昂坪村",
                "Cable Car": "纜車",
                "Peak Galleria": "山頂廣場",
                "Tai O Village": "大澳村",
                "Campsite": "營地",
                "Village Store": "村莊商店",
                "Visitor Center": "遊客中心",
                "Restaurant": "餐廳",
                "Taxi Stand": "的士站"
            ]
            if let chinese = englishToChinese[name] {
                return chinese
            }
        }
        
        // In English mode, if original text contains Chinese, try to map common Chinese facility names
        if languageManager.currentLanguage == .english && containsChineseCharacters(name) {
            // Map common Chinese facility names to English
            let chineseToEnglish: [String: String] = [
                "燒烤場": "BBQ Area",
                "洗手間": "Toilet",
                "郊野公園洗手間": "Country Park Toilet",
                "涼亭": "Pavilion",
                "大浪灣淋浴設施": "Big Wave Bay Shower Facilities",
                "水站": "Water Station",
                "山屋": "Mountain Hut",
                "露營": "Camping",
                "昂坪村": "Ngong Ping Village",
                "纜車": "Cable Car",
                "山頂廣場": "Peak Galleria",
                "大澳村": "Tai O Village",
                "露營場地": "Campsite",
                "村莊商店": "Village Store",
                "遊客中心": "Visitor Center",
                "餐廳": "Restaurant",
                "的士站": "Taxi Stand",
                "營地": "Campsite"
            ]
            return chineseToEnglish[name] ?? name
        }
        
        return name
    }
    
    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.hikingBrown)
        }
    }
}

#Preview {
    NavigationStack {
        TrailDetailView(trail: Trail.sampleData[0])
            .environmentObject(LanguageManager.shared)
    }
}

