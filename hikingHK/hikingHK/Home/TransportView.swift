//
//  TransportView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

/// Transport query view for MTR and Bus services
struct TransportView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedTab: TransportTab = .mtr
    @State private var searchText = ""
    @State private var selectedLine: String?
    @State private var selectedStation: String?
    @State private var mtrSchedule: MTRScheduleData?
    @State private var isLoadingMTR = false
    @State private var mtrError: String?
    
    // Bus states
    @State private var busRoutes: [KMBRoute] = []
    @State private var searchResults: [KMBRoute] = []
    @State private var selectedRoute: KMBRoute?
    @State private var routeStops: [KMBStop] = []
    @State private var currentStopPage: Int = 0
    private let stopsPerPage = 10
    @State private var selectedStop: KMBStop?
    @State private var busETAs: [KMBETA] = []
    @State private var navigationRoute: KMBRoute?
    @State private var isLoadingBus = false
    @State private var busError: String?
    
    private let mtrService = MTRService()
    private let kmbService = KMBService()
    
    enum TransportTab: String, CaseIterable {
        case mtr = "MTR"
        case bus = "Bus"
        
        func localizedName(languageManager: LanguageManager) -> String {
            switch self {
            case .mtr:
                return languageManager.localizedString(for: "transport.mtr")
            case .bus:
                return languageManager.localizedString(for: "transport.bus")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Transport Type", selection: $selectedTab) {
                    ForEach(TransportTab.allCases, id: \.self) { tab in
                        Text(tab.localizedName(languageManager: languageManager)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                if selectedTab == .mtr {
                    mtrView
                } else {
                    busView
                }
            }
            .navigationTitle(languageManager.localizedString(for: "transport.title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: KMBRoute.self) { route in
                BusRouteDetailView(route: route)
                    .environmentObject(languageManager)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
                        // Dismiss handled by parent sheet
                    }
                }
            }
        }
    }
    
    // MARK: - MTR View
    
    private var mtrView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Search section with improved design
                VStack(alignment: .leading, spacing: 16) {
                    Text(languageManager.localizedString(for: "transport.mtr.search.title"))
                        .font(.title3.bold())
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            TextField(languageManager.localizedString(for: "transport.mtr.search.placeholder"), text: $searchText)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    Task {
                                        await searchMTRStation()
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        
                        Button {
                            Task {
                                await searchMTRStation()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text(languageManager.localizedString(for: "transport.search"))
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(searchText.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                            )
                            .foregroundColor(searchText.isEmpty ? .secondary : .white)
                        }
                        .disabled(searchText.isEmpty || isLoadingMTR)
                    }
                    .padding(.horizontal)
                    
                    // Quick station buttons with improved design
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.localizedString(for: "transport.mtr.quick.stations"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                quickStationButton("荃灣")
                                quickStationButton("筲箕灣")
                                quickStationButton("中環")
                                quickStationButton("金鐘")
                                quickStationButton("東涌")
                                quickStationButton("觀塘")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                
                // Schedule display
                if isLoadingMTR {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = mtrError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.largeTitle)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if let schedule = mtrSchedule {
                    scheduleView(schedule: schedule)
                } else {
                    VStack {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(.red)
                            .font(.largeTitle)
                        Text(languageManager.localizedString(for: "transport.mtr.no.schedule"))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
        }
    }
    
    private func scheduleView(schedule: MTRScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let upTrains = schedule.UP, !upTrains.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Direction header showing destination
                    let mainDestination = getMainDestination(from: upTrains)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(languageManager.localizedString(for: "transport.mtr.towards"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mainDestination)
                                .font(.headline.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Train times
                    ForEach(Array(upTrains.prefix(4))) { train in
                        HStack(spacing: 12) {
                            // Destination station
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(getStationName(train.dest))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            // Arrival time badge
                            Text(formatTrainTime(train.formattedTime))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                )
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            
            if let downTrains = schedule.DOWN, !downTrains.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Direction header showing destination
                    let mainDestination = getMainDestination(from: downTrains)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(languageManager.localizedString(for: "transport.mtr.towards"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mainDestination)
                                .font(.headline.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Train times
                    ForEach(Array(downTrains.prefix(4))) { train in
                        HStack(spacing: 12) {
                            // Destination station
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(getStationName(train.dest))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            // Arrival time badge
                            Text(formatTrainTime(train.formattedTime))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                )
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTrainTime(_ time: String) -> String {
        if time.lowercased().contains("arriving") || time == "Arr" || time == "0" {
            return languageManager.localizedString(for: "mtr.arriving")
        }
        if let minutes = Int(time) {
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
    
    private func quickStationButton(_ stationName: String) -> some View {
        Button {
            searchText = stationName
            Task {
                await searchMTRStation()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.caption)
                Text(stationName)
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(.white)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private func searchMTRStation() async {
        guard !searchText.isEmpty else { return }
        
        await MainActor.run {
            isLoadingMTR = true
            mtrError = nil
            mtrSchedule = nil
        }
        
        if let stationInfo = MTRStationMapper.mapStation(searchText) {
            do {
                let schedule = try await mtrService.fetchSchedule(
                    line: stationInfo.line,
                    station: stationInfo.station
                )
                await MainActor.run {
                    self.mtrSchedule = schedule
                    self.isLoadingMTR = false
                    self.mtrError = nil
                }
            } catch {
                await MainActor.run {
                    self.mtrError = languageManager.localizedString(for: "mtr.error.load.failed")
                    self.isLoadingMTR = false
                    print("❌ MTR Service Error: \(error.localizedDescription)")
                }
            }
        } else {
            await MainActor.run {
                self.mtrError = languageManager.localizedString(for: "transport.mtr.station.not.found")
                self.isLoadingMTR = false
            }
        }
    }
    
    // MARK: - Bus View
    
    private var busView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Search section with improved design
                VStack(alignment: .leading, spacing: 16) {
                    Text(languageManager.localizedString(for: "transport.bus.search.title"))
                        .font(.title3.bold())
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            TextField(languageManager.localizedString(for: "transport.bus.search.placeholder"), text: $searchText)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    Task {
                                        await searchBusRoutes()
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        
                        Button {
                            Task {
                                await searchBusRoutes()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text(languageManager.localizedString(for: "transport.search"))
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(searchText.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                            )
                            .foregroundColor(searchText.isEmpty ? .secondary : .white)
                        }
                        .disabled(searchText.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Search results
                Group {
                    if isLoadingBus {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if !searchResults.isEmpty {
                        // Show results if we have any, regardless of error state
                        searchResultsView
                            .onAppear {
                                print("📱 searchResultsView appeared with \(searchResults.count) results")
                            }
                    } else if let error = busError, !error.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.largeTitle)
                            Text(error)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button(languageManager.localizedString(for: "retry")) {
                                Task {
                                    await searchBusRoutes()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else if selectedRoute != nil {
                        routeDetailView
                    } else if selectedStop != nil && !busETAs.isEmpty {
                        // ETA view is already shown in routeDetailView
                        routeDetailView
                    } else if !searchText.isEmpty && searchResults.isEmpty {
                        // User searched but no results
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.orange)
                                .font(.largeTitle)
                            Text(languageManager.localizedString(for: "transport.bus.no.results"))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else {
                        // Initial state - no search yet
                        VStack(spacing: 12) {
                            Image(systemName: "bus.fill")
                                .foregroundStyle(.orange)
                                .font(.largeTitle)
                            Text(languageManager.localizedString(for: "transport.bus.search.placeholder"))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                }
                .id("bus-results-\(searchResults.count)-\(isLoadingBus)-\(busError ?? "nil")")
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Results header with count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localizedString(for: "transport.bus.results"))
                        .font(.title3.bold())
                    Text("\(searchResults.count) \(languageManager.localizedString(for: "transport.bus.routes.found"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Route cards with improved design
            ForEach(searchResults.prefix(20)) { route in
                NavigationLink(value: route) {
                    HStack(spacing: 12) {
                        // Route number badge
                        Text(route.route)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                        
                        // Route information
                        VStack(alignment: .leading, spacing: 6) {
                            // Direction indicator with destination
                            HStack(spacing: 6) {
                                Image(systemName: route.bound == "O" ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(route.bound == "O" ? 
                                     "\(languageManager.localizedString(for: "transport.bus.outbound")) \(route.localizedDestination(languageManager: languageManager))" :
                                     "\(languageManager.localizedString(for: "transport.bus.inbound")) \(route.localizedOrigin(languageManager: languageManager))")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                            }
                            
                            // Origin and destination
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption2)
                                    Text(route.localizedOrigin(languageManager: languageManager))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "flag.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption2)
                                    Text(route.localizedDestination(languageManager: languageManager))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if searchResults.count > 20 {
                HStack {
                    Spacer()
                    Text(languageManager.localizedString(for: "transport.bus.showing.first.20"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                    Spacer()
                }
            }
        }
        .padding(.vertical)
    }
    
    private var routeDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let route = selectedRoute {
                // Route info
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(route.route) \(route.bound == "O" ? "→" : "←")")
                        .font(.title2.bold())
                    Text("\(route.localizedOrigin(languageManager: languageManager)) → \(route.localizedDestination(languageManager: languageManager))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                
                // Stops list
                if !routeStops.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.localizedString(for: "transport.bus.stops"))
                            .font(.headline)
                        
                        ForEach(routeStops) { stop in
                            Button {
                                print("🔘 Tapped stop: \(stop.localizedName(languageManager: languageManager))")
                                loadBusETA(stop: stop, route: route)
                            } label: {
                                HStack {
                                    Text(stop.localizedName(languageManager: languageManager))
                                    Spacer()
                                    if selectedStop?.id == stop.id {
                                        if !busETAs.isEmpty {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.orange)
                                        } else {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    selectedStop?.id == stop.id ? Color.orange.opacity(0.1) : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding()
                }
                
                // ETA display
                if selectedStop != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(languageManager.localizedString(for: "transport.bus.eta"))
                                .font(.headline)
                            Spacer()
                            if busETAs.isEmpty {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if !busETAs.isEmpty {
                            ForEach(busETAs) { eta in
                                let remark = eta.localizedRemark(languageManager: languageManager)
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(eta.localizedDestination(languageManager: languageManager))
                                            .font(.subheadline.bold())
                                        if !remark.isEmpty {
                                            Text(remark)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(eta.formattedETA)
                                        .foregroundStyle(.orange)
                                        .fontWeight(.medium)
                                        .font(.headline)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            Text(languageManager.localizedString(for: "transport.bus.no.eta.found"))
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func searchBusRoutes() {
        guard !searchText.isEmpty else { return }
        
        isLoadingBus = true
        busError = nil
        searchResults = []
        selectedRoute = nil
        routeStops = []
        selectedStop = nil
        busETAs = []
        
        Task {
            do {
                print("🔍 Starting bus search for: '\(searchText)'")
                let results = try await kmbService.searchRoutes(keyword: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isLoadingBus = false
                    self.busError = nil // Clear any previous errors
                    print("✅ Bus search successful: Found \(results.count) routes for '\(searchText)'")
                    print("📱 Updated searchResults: \(self.searchResults.count) items")
                    print("📱 isLoadingBus: \(self.isLoadingBus)")
                    print("📱 busError: \(self.busError ?? "nil")")
                    if results.isEmpty {
                        print("⚠️ No routes found for '\(searchText)'")
                    }
                }
            } catch {
                await MainActor.run {
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                    self.isLoadingBus = false
                    self.searchResults = []
                    print("❌ Bus search error: \(error.localizedDescription)")
                    print("❌ Error type: \(type(of: error))")
                    if let kmbError = error as? KMBServiceError {
                        print("❌ KMB Service Error: \(kmbError)")
                    }
                }
            }
        }
    }
    
    private func loadRouteStopsAndETA(route: KMBRoute) {
        print("📋 Loading route stops and ETA for: \(route.route) \(route.bound) \(route.service_type)")
        selectedRoute = route
        routeStops = []
        busETAs = []
        selectedStop = nil
        busError = nil
        
        Task {
            do {
                print("🌐 Fetching route stops...")
                let stops = try await kmbService.fetchRouteStops(
                    route: route.route,
                    direction: route.bound,
                    serviceType: route.service_type
                )
                await MainActor.run {
                    self.routeStops = stops
                    self.currentStopPage = 0 // Reset to first page when loading new route
                    print("✅ Loaded \(self.routeStops.count) stops for route \(route.route)")
                }
                
                // Load ETA for first 10 stops initially, then load more as needed
                if !stops.isEmpty {
                    let initialStopsToLoad = Array(stops.prefix(10)) // Load first 10 stops initially
                    await loadETAsForStopsParallel(stops: initialStopsToLoad, route: route)
                    
                    // Load remaining stops in background
                    if stops.count > 10 {
                        let remainingStops = Array(stops.dropFirst(10))
                        Task {
                            await loadETAsForStopsParallel(stops: remainingStops, route: route)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading route stops: \(error.localizedDescription)")
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                }
            }
        }
    }
    
    private func loadETAsForStopsParallel(stops: [KMBStop], route: KMBRoute) async {
        print("🚀 Loading ETAs for \(stops.count) stops in parallel...")
        let startTime = Date()
        
        // Load all ETAs in parallel using async let
        await withTaskGroup(of: (stopId: String, etas: [KMBETA]?).self) { group in
            for stop in stops {
                group.addTask {
                    do {
                        let etas = try await kmbService.fetchETA(
                            stopId: stop.stop,
                            route: route.route,
                            serviceType: route.service_type
                        )
                        return (stopId: stop.stop, etas: etas)
                    } catch {
                        print("⚠️ Failed to load ETA for stop \(stop.stop): \(error.localizedDescription)")
                        return (stopId: stop.stop, etas: nil)
                    }
                }
            }
            
            var allETAs: [KMBETA] = []
            for await result in group {
                if let etas = result.etas {
                    allETAs.append(contentsOf: etas)
                }
            }
            
            let loadTime = Date().timeIntervalSince(startTime)
            await MainActor.run {
                self.busETAs = allETAs
                print("✅ Loaded \(allETAs.count) ETAs for route \(route.route) in \(String(format: "%.2f", loadTime))s")
            }
        }
    }
    
    private func routeETAExpandedView(route: KMBRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoadingBus {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if !routeStops.isEmpty {
                // Show stops with ETA in paginated view
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(languageManager.localizedString(for: "transport.bus.real.time.eta"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        
                        Spacer()
                        
                        // Page indicator
                        if routeStops.count > stopsPerPage {
                            Text("\(currentStopPage + 1) / \(Int(ceil(Double(routeStops.count) / Double(stopsPerPage))))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    TabView(selection: $currentStopPage) {
                        ForEach(0..<Int(ceil(Double(routeStops.count) / Double(stopsPerPage))), id: \.self) { pageIndex in
                            let startIndex = pageIndex * stopsPerPage
                            let endIndex = min(startIndex + stopsPerPage, routeStops.count)
                            let pageStops = Array(routeStops[startIndex..<endIndex])
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(pageStops) { stop in
                                    stopETACard(stop: stop)
                                }
                            }
                            .tag(pageIndex)
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: CGFloat(min(stopsPerPage, routeStops.count)) * 80) // Approximate height per stop
                }
                .padding(.vertical, 8)
            } else if let error = busError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func stopETACard(stop: KMBStop) -> some View {
        // Filter ETAs by stop ID - handle both cases where stop field may be nil
        let stopETAs = busETAs.filter { eta in
            if let etaStop = eta.stop {
                return etaStop == stop.stop
            }
            // If stop field is nil, we can't match - this shouldn't happen after our fix
            return false
        }
        let isLoading = routeStops.contains(where: { $0.id == stop.id }) && stopETAs.isEmpty && !isLoadingBus
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(stop.localizedName(languageManager: languageManager))
                .font(.caption.bold())
            
            if !stopETAs.isEmpty {
                ForEach(stopETAs.prefix(2)) { eta in
                    HStack {
                        Text(eta.localizedDestination(languageManager: languageManager))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(eta.formattedETA)
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
            } else if isLoadingBus {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(languageManager.localizedString(for: "transport.bus.loading.eta"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(languageManager.localizedString(for: "transport.bus.no.eta.found"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func loadBusETA(stop: KMBStop, route: KMBRoute) {
        print("📋 Loading ETA for stop: \(stop.stop), route: \(route.route), serviceType: \(route.service_type)")
        selectedStop = stop
        busETAs = []
        busError = nil
        
        Task {
            do {
                print("🌐 Fetching ETA...")
                let etas = try await kmbService.fetchETA(
                    stopId: stop.stop,
                    route: route.route,
                    serviceType: route.service_type
                )
                await MainActor.run {
                    self.busETAs = etas
                    print("✅ Loaded \(self.busETAs.count) ETAs for stop \(stop.localizedName(languageManager: languageManager))")
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading ETA: \(error.localizedDescription)")
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                }
            }
        }
    }
}

