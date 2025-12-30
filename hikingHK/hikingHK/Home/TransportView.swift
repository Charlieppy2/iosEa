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
    @State private var filteredResults: [KMBRoute] = []
    @State private var selectedRoute: KMBRoute?
    @State private var routeStops: [KMBStop] = []
    @State private var currentStopPage: Int = 0
    private let stopsPerPage = 10
    @State private var selectedStop: KMBStop?
    @State private var busETAs: [KMBETA] = []
    @State private var navigationRoute: KMBRoute?
    @State private var isLoadingBus = false
    @State private var busError: String?
    
    // Filter states
    @State private var selectedFilterStation: String? = nil // Selected station name for filtering
    @State private var availableStations: [String] = [] // All unique stations from search results
    @State private var allStations: [String] = [] // All stations from all routes (for pre-search filtering)
    @State private var isLoadingAllRoutes = false // Loading state for all routes
    
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
                        
                        // Filter section - always visible, before search button
                        filterSection
                        
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
                    } else if !searchResults.isEmpty || !filteredResults.isEmpty || selectedFilterStation != nil {
                        // Show results if we have any, or if a filter is selected
                        searchResultsView
                            .onAppear {
                                print("📱 searchResultsView appeared with \(searchResults.count) results, \(filteredResults.count) filtered")
                                if filteredResults.isEmpty {
                                    if !searchResults.isEmpty {
                                        applyFilters()
                                    } else if !busRoutes.isEmpty {
                                        applyFilters()
                                    } else if selectedFilterStation != nil {
                                        // If filter is selected but routes not loaded, load them
                                        loadAllStations()
                                    }
                                }
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
                    Text("\(filteredResults.count) \(languageManager.localizedString(for: "transport.bus.routes.found"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Route cards with improved design
            ForEach(filteredResults.prefix(20)) { route in
                NavigationLink(value: route) {
                    HStack(spacing: 14) {
                        // Route number badge - fixed width for 5 characters
                        Text(route.route)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 58)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        
                        // Route information
                        VStack(alignment: .leading, spacing: 6) {
                            // Route number and direction in the same line - ensure they stay on one line
                            HStack(spacing: 8) {
                                Image(systemName: route.bound == "O" ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.body)
                                Text(route.bound == "O" ? 
                                     "\(languageManager.localizedString(for: "transport.bus.outbound")) \(route.localizedDestination(languageManager: languageManager))" :
                                     "\(languageManager.localizedString(for: "transport.bus.inbound")) \(route.localizedOrigin(languageManager: languageManager))")
                                    .font(.body.bold())
                                    .foregroundStyle(.orange)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: false)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Origin and destination
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.subheadline)
                                    Text(languageManager.localizedString(for: "trail.start.point"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    let origin = route.localizedOrigin(languageManager: languageManager)
                                    Text(origin.isEmpty ? (languageManager.currentLanguage == .traditionalChinese ? "" : route.orig_en) : origin)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "flag.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.subheadline)
                                    Text(languageManager.localizedString(for: "trail.end.point"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    let destination = route.localizedDestination(languageManager: languageManager)
                                    Text(destination.isEmpty ? (languageManager.currentLanguage == .traditionalChinese ? "" : route.dest_en) : destination)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
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
        guard !searchText.isEmpty else {
            searchResults = []
            filteredResults = []
            return
        }
        
        isLoadingBus = true
        busError = nil
        searchResults = []
        filteredResults = []
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
                    // Initialize filteredResults with all results, then apply filters
                    if self.filteredResults.isEmpty {
                        self.filteredResults = results
                    }
                    updateAvailableStations()
                    applyFilters()
                    self.isLoadingBus = false
                    self.busError = nil // Clear any previous errors
                    print("✅ Bus search successful: Found \(results.count) routes for '\(searchText)'")
                    print("📱 Updated searchResults: \(self.searchResults.count) items")
                    print("📱 Filtered results: \(self.filteredResults.count) items")
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
                    self.filteredResults = []
                    print("❌ Bus search error: \(error.localizedDescription)")
                    print("❌ Error type: \(type(of: error))")
                    if let kmbError = error as? KMBServiceError {
                        print("❌ KMB Service Error: \(kmbError)")
                    }
                }
            }
        }
    }
    
    private func applyFilters() {
        var filtered: [KMBRoute] = []
        
        // If we have search results, use them; otherwise use all routes
        if !searchResults.isEmpty {
            filtered = searchResults
        } else if !busRoutes.isEmpty {
            filtered = busRoutes
        } else {
            // If no routes loaded yet and a station is selected, try to load them
            if selectedFilterStation != nil && !isLoadingAllRoutes {
                loadAllStations()
            }
            filteredResults = []
            return
        }
        
        // Filter by selected station
        if let station = selectedFilterStation {
            filtered = filtered.filter { route in
                // In Traditional Chinese mode, only filter by Traditional Chinese names that contain Chinese characters
                if languageManager.currentLanguage == .traditionalChinese {
                    // Only use TC names if they contain Chinese characters
                    let origin = containsChineseCharacters(route.orig_tc) ? route.orig_tc : ""
                    let destination = containsChineseCharacters(route.dest_tc) ? route.dest_tc : ""
                    // Use contains for partial matching (e.g., "中環 (林士街)" matches "中環")
                    return (!origin.isEmpty && (origin.contains(station) || station.contains(origin))) ||
                           (!destination.isEmpty && (destination.contains(station) || station.contains(destination)))
                } else {
                    let origin = route.localizedOrigin(languageManager: languageManager)
                    let destination = route.localizedDestination(languageManager: languageManager)
                    // Use contains for partial matching (e.g., "中環 (林士街)" matches "中環")
                    return origin.contains(station) || destination.contains(station) || 
                           station.contains(origin) || station.contains(destination)
                }
            }
        }
        
        filteredResults = filtered
        print("🔍 Applied filters - Original: \(searchResults.isEmpty ? busRoutes.count : searchResults.count), Filtered: \(filteredResults.count)")
        print("🔍 Selected station: \(selectedFilterStation ?? "none")")
    }
    
    private func updateAvailableStations() {
        var stations = Set<String>()
        
        for route in searchResults {
            // In Traditional Chinese mode, only add stations that have Traditional Chinese names
            if languageManager.currentLanguage == .traditionalChinese {
                let origTC = route.orig_tc.trimmingCharacters(in: .whitespaces)
                let destTC = route.dest_tc.trimmingCharacters(in: .whitespaces)
                if !origTC.isEmpty && containsChineseCharacters(origTC) {
                    stations.insert(origTC)
                }
                if !destTC.isEmpty && containsChineseCharacters(destTC) {
                    stations.insert(destTC)
                }
            } else {
                stations.insert(route.localizedOrigin(languageManager: languageManager))
                stations.insert(route.localizedDestination(languageManager: languageManager))
            }
        }
        
        availableStations = Array(stations).sorted()
        print("📍 Updated available stations: \(availableStations.count) unique stations")
    }
    
    /// Check if a string contains Chinese characters
    private func containsChineseCharacters(_ text: String) -> Bool {
        // Check if the string contains any Chinese characters (CJK Unified Ideographs)
        return text.unicodeScalars.contains { scalar in
            // Chinese characters range: U+4E00 to U+9FFF
            // Also include common punctuation and symbols used in Chinese
            (0x4E00...0x9FFF).contains(scalar.value) ||
            (0x3400...0x4DBF).contains(scalar.value) || // Extension A
            (0x20000...0x2A6DF).contains(scalar.value) || // Extension B
            (0x3000...0x303F).contains(scalar.value) || // CJK Symbols and Punctuation
            (0xFF00...0xFFEF).contains(scalar.value) // Halfwidth and Fullwidth Forms
        }
    }
    
    /// Load all routes to get all available stations for pre-search filtering
    private func loadAllStations() {
        guard allStations.isEmpty && !isLoadingAllRoutes else { 
            print("⏭️ Skipping loadAllStations - already loaded or loading")
            return 
        }
        
        isLoadingAllRoutes = true
        print("🔄 Starting to load all stations...")
        Task {
            do {
                let allRoutes = try await kmbService.fetchRouteList()
                var stations = Set<String>()
                
                for route in allRoutes {
                    // In Traditional Chinese mode, only add stations that have Traditional Chinese names
                    // to avoid English residue
                    if languageManager.currentLanguage == .traditionalChinese {
                        // Only add if Traditional Chinese name exists, is not empty, and contains Chinese characters
                        let origTC = route.orig_tc.trimmingCharacters(in: .whitespaces)
                        let destTC = route.dest_tc.trimmingCharacters(in: .whitespaces)
                        if !origTC.isEmpty && containsChineseCharacters(origTC) {
                            stations.insert(origTC)
                        }
                        if !destTC.isEmpty && containsChineseCharacters(destTC) {
                            stations.insert(destTC)
                        }
                    } else {
                        // In English mode, use localized methods
                        stations.insert(route.localizedOrigin(languageManager: languageManager))
                        stations.insert(route.localizedDestination(languageManager: languageManager))
                    }
                }
                
                await MainActor.run {
                    self.allStations = Array(stations).sorted()
                    self.isLoadingAllRoutes = false
                    self.busRoutes = allRoutes // Store all routes for filtering
                    print("✅ Loaded all stations: \(self.allStations.count) unique stations")
                    print("📊 Stations by district: \(self.stationsByDistrict.count) districts")
                    print("📊 Loaded \(allRoutes.count) routes")
                    // Apply filters after loading routes
                    applyFilters()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAllRoutes = false
                    print("❌ Failed to load all stations: \(error)")
                }
            }
        }
    }
    
    /// Get color for a district
    private func getDistrictColor(for district: String) -> Color {
        switch district {
        case "港島", "Hong Kong Island":
            return Color.blue
        case "九龍", "Kowloon":
            return Color.purple
        case "新界", "New Territories":
            return Color.green
        default:
            return Color.gray
        }
    }
    
    /// Get district for a station name
    private func getDistrict(for station: String) -> String {
        // Common Hong Kong districts mapping
        let districtMap: [String: String] = [
            // Hong Kong Island
            "中環": "港島",
            "金鐘": "港島",
            "灣仔": "港島",
            "銅鑼灣": "港島",
            "天后": "港島",
            "炮台山": "港島",
            "北角": "港島",
            "鰂魚涌": "港島",
            "太古": "港島",
            "西灣河": "港島",
            "筲箕灣": "港島",
            "柴灣": "港島",
            "上環": "港島",
            "西環": "港島",
            "堅尼地城": "港島",
            "香港": "港島",
            "Central": "Hong Kong Island",
            "Admiralty": "Hong Kong Island",
            "Wan Chai": "Hong Kong Island",
            "Causeway Bay": "Hong Kong Island",
            "Tin Hau": "Hong Kong Island",
            "Fortress Hill": "Hong Kong Island",
            "North Point": "Hong Kong Island",
            "Quarry Bay": "Hong Kong Island",
            "Tai Koo": "Hong Kong Island",
            "Sai Wan Ho": "Hong Kong Island",
            "Shau Kei Wan": "Hong Kong Island",
            "Chai Wan": "Hong Kong Island",
            "Sheung Wan": "Hong Kong Island",
            "Sai Wan": "Hong Kong Island",
            "Kennedy Town": "Hong Kong Island",
            
            // Kowloon
            "尖沙咀": "九龍",
            "佐敦": "九龍",
            "油麻地": "九龍",
            "旺角": "九龍",
            "太子": "九龍",
            "深水埗": "九龍",
            "長沙灣": "九龍",
            "荔枝角": "九龍",
            "美孚": "九龍",
            "黃大仙": "九龍",
            "鑽石山": "九龍",
            "彩虹": "九龍",
            "九龍灣": "九龍",
            "牛頭角": "九龍",
            "觀塘": "九龍",
            "藍田": "九龍",
            "油塘": "九龍",
            "紅磡": "九龍",
            "土瓜灣": "九龍",
            "何文田": "九龍",
            "九龍塘": "九龍",
            "樂富": "九龍",
            "黃埔": "九龍",
            "Tsim Sha Tsui": "Kowloon",
            "Jordan": "Kowloon",
            "Yau Ma Tei": "Kowloon",
            "Mong Kok": "Kowloon",
            "Prince Edward": "Kowloon",
            "Sham Shui Po": "Kowloon",
            "Cheung Sha Wan": "Kowloon",
            "Lai Chi Kok": "Kowloon",
            "Mei Foo": "Kowloon",
            "Wong Tai Sin": "Kowloon",
            "Diamond Hill": "Kowloon",
            "Choi Hung": "Kowloon",
            "Kowloon Bay": "Kowloon",
            "Ngau Tau Kok": "Kowloon",
            "Kwun Tong": "Kowloon",
            "Lam Tin": "Kowloon",
            "Yau Tong": "Kowloon",
            "Hung Hom": "Kowloon",
            "To Kwa Wan": "Kowloon",
            "Ho Man Tin": "Kowloon",
            "Kowloon Tong": "Kowloon",
            "Lok Fu": "Kowloon",
            "Whampoa": "Kowloon",
            
            // New Territories
            "沙田": "新界",
            "大圍": "新界",
            "火炭": "新界",
            "馬鞍山": "新界",
            "大埔": "新界",
            "太和": "新界",
            "粉嶺": "新界",
            "上水": "新界",
            "元朗": "新界",
            "天水圍": "新界",
            "屯門": "新界",
            "荃灣": "新界",
            "葵涌": "新界",
            "青衣": "新界",
            "東涌": "新界",
            "將軍澳": "新界",
            "調景嶺": "新界",
            "坑口": "新界",
            "寶琳": "新界",
            "康城": "新界",
            "Sha Tin": "New Territories",
            "Tai Wai": "New Territories",
            "Fo Tan": "New Territories",
            "Ma On Shan": "New Territories",
            "Tai Po": "New Territories",
            "Tai Wo": "New Territories",
            "Fanling": "New Territories",
            "Sheung Shui": "New Territories",
            "Yuen Long": "New Territories",
            "Tin Shui Wai": "New Territories",
            "Tuen Mun": "New Territories",
            "Tsuen Wan": "New Territories",
            "Kwai Chung": "New Territories",
            "Tsing Yi": "New Territories",
            "Tung Chung": "New Territories",
            "Tseung Kwan O": "New Territories",
            "Tiu Keng Leng": "New Territories",
            "Hang Hau": "New Territories",
            "Po Lam": "New Territories",
            "LOHAS Park": "New Territories"
        ]
        
        // Check if station name contains any district keyword
        for (keyword, district) in districtMap {
            if station.contains(keyword) {
                return district
            }
        }
        
        // Try to match by common patterns if not found in map
        let stationLower = station.lowercased()
        
        // Check for Hong Kong Island patterns
        if stationLower.contains("central") || stationLower.contains("admiralty") || 
           stationLower.contains("wan chai") || stationLower.contains("causeway") ||
           stationLower.contains("north point") || stationLower.contains("quarry bay") ||
           stationLower.contains("chai wan") || stationLower.contains("sheung wan") ||
           stationLower.contains("kennedy") || stationLower.contains("中環") ||
           stationLower.contains("金鐘") || stationLower.contains("灣仔") ||
           stationLower.contains("銅鑼灣") || stationLower.contains("北角") ||
           stationLower.contains("鰂魚涌") || stationLower.contains("柴灣") ||
           stationLower.contains("上環") || stationLower.contains("堅尼地城") {
            return languageManager.currentLanguage == .english ? "Hong Kong Island" : "港島"
        }
        
        // Check for Kowloon patterns
        if stationLower.contains("tsim sha tsui") || stationLower.contains("mong kok") ||
           stationLower.contains("kwun tong") || stationLower.contains("yau ma tei") ||
           stationLower.contains("sham shui po") || stationLower.contains("mei foo") ||
           stationLower.contains("wong tai sin") || stationLower.contains("kowloon") ||
           stationLower.contains("尖沙咀") || stationLower.contains("旺角") ||
           stationLower.contains("觀塘") || stationLower.contains("油麻地") ||
           stationLower.contains("深水埗") || stationLower.contains("美孚") ||
           stationLower.contains("黃大仙") || stationLower.contains("九龍") {
            return languageManager.currentLanguage == .english ? "Kowloon" : "九龍"
        }
        
        // Check for New Territories patterns
        if stationLower.contains("sha tin") || stationLower.contains("tai po") ||
           stationLower.contains("yuen long") || stationLower.contains("tuen mun") ||
           stationLower.contains("tsuen wan") || stationLower.contains("tung chung") ||
           stationLower.contains("tseung kwan o") || stationLower.contains("fanling") ||
           stationLower.contains("sheung shui") || stationLower.contains("沙田") ||
           stationLower.contains("大埔") || stationLower.contains("元朗") ||
           stationLower.contains("屯門") || stationLower.contains("荃灣") ||
           stationLower.contains("東涌") || stationLower.contains("將軍澳") ||
           stationLower.contains("粉嶺") || stationLower.contains("上水") ||
           stationLower.contains("新界") {
            return languageManager.currentLanguage == .english ? "New Territories" : "新界"
        }
        
        // If still not found, don't return "其他", just return empty or skip it
        // We'll filter these out in stationsByDistrict
        return ""
    }
    
    /// Get stations grouped by district - use allStations if available, otherwise use availableStations
    private var stationsByDistrict: [(district: String, stations: [String])] {
        let stationsToUse = allStations.isEmpty ? availableStations : allStations
        var grouped: [String: [String]] = [:]
        
        for station in stationsToUse {
            let district = getDistrict(for: station)
            // Only add stations that have a valid district (not empty)
            if !district.isEmpty {
                if grouped[district] == nil {
                    grouped[district] = []
                }
                grouped[district]?.append(station)
            }
        }
        
        // Sort districts: 港島/Hong Kong Island, 九龍/Kowloon, 新界/New Territories (exclude Others and empty)
        let districtOrder = languageManager.currentLanguage == .english 
            ? ["Hong Kong Island", "Kowloon", "New Territories"]
            : ["港島", "九龍", "新界"]
        
        return districtOrder.compactMap { district in
            guard let stations = grouped[district], !stations.isEmpty else { return nil }
            return (district: district, stations: stations.sorted())
        }
    }
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(.orange)
                    .font(.headline)
                Text(languageManager.localizedString(for: "transport.bus.filter"))
                    .font(.headline)
                
                Spacer()
                
                if selectedFilterStation != nil {
                    Button {
                        selectedFilterStation = nil
                        applyFilters()
                    } label: {
                        Text(languageManager.localizedString(for: "transport.bus.filter.clear"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            // Station filter - Dropdown style with district grouping
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.localizedString(for: "transport.bus.filter.station"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                
                Menu {
                    // All option
                    Button {
                        selectedFilterStation = nil
                        applyFilters()
                    } label: {
                        HStack {
                            Text(languageManager.localizedString(for: "transport.bus.filter.all"))
                            if selectedFilterStation == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Stations grouped by district
                    if isLoadingAllRoutes && allStations.isEmpty && availableStations.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(languageManager.localizedString(for: "transport.bus.loading.eta"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else if stationsByDistrict.isEmpty {
                        Text("暫無車站選項")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(stationsByDistrict, id: \.district) { group in
                            Section {
                                ForEach(group.stations.filter { station in
                                    // In Traditional Chinese mode, only show stations with Chinese characters
                                    if languageManager.currentLanguage == .traditionalChinese {
                                        return containsChineseCharacters(station)
                                    }
                                    return true
                                }, id: \.self) { station in
                                    Button {
                                        selectedFilterStation = station
                                        applyFilters()
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(getDistrictColor(for: group.district))
                                            Text(station)
                                            if selectedFilterStation == station {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(getDistrictColor(for: group.district).opacity(0.15))
                                        )
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group.district)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(getDistrictColor(for: group.district).opacity(0.25))
                                )
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text({
                            if let station = selectedFilterStation, 
                               languageManager.currentLanguage == .traditionalChinese,
                               !containsChineseCharacters(station) {
                                // If selected station doesn't contain Chinese characters in TC mode, show "全部"
                                return languageManager.localizedString(for: "transport.bus.filter.all")
                            } else {
                                return selectedFilterStation ?? languageManager.localizedString(for: "transport.bus.filter.all")
                            }
                        }())
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .task {
            // Load all stations when filter section appears (for pre-search filtering)
            loadAllStations()
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

