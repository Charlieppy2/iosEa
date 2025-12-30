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
    @State private var selectedStop: KMBStop?
    @State private var busETAs: [KMBETA] = []
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
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localizedString(for: "transport.mtr.search.title"))
                        .font(.headline)
                    
                    TextField(languageManager.localizedString(for: "transport.mtr.search.placeholder"), text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onSubmit {
                            Task {
                                await searchMTRStation()
                            }
                        }
                    
                    Button(languageManager.localizedString(for: "transport.search")) {
                        Task {
                            await searchMTRStation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.isEmpty || isLoadingMTR)
                    
                    // Quick station buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.localizedString(for: "transport.mtr.quick.stations"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickStationButton("荃灣")
                                quickStationButton("筲箕灣")
                                quickStationButton("中環")
                                quickStationButton("金鐘")
                                quickStationButton("東涌")
                                quickStationButton("觀塘")
                            }
                        }
                    }
                }
                .padding()
                
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
                VStack(alignment: .leading, spacing: 8) {
                    Label(languageManager.localizedString(for: "mtr.direction.up"), systemImage: "arrow.up")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    ForEach(Array(upTrains.prefix(4))) { train in
                        HStack {
                            Text(getStationName(train.dest))
                            Spacer()
                            Text(formatTrainTime(train.formattedTime))
                                .foregroundStyle(.red)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            
            if let downTrains = schedule.DOWN, !downTrains.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(languageManager.localizedString(for: "mtr.direction.down"), systemImage: "arrow.down")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    ForEach(Array(downTrains.prefix(4))) { train in
                        HStack {
                            Text(getStationName(train.dest))
                            Spacer()
                            Text(formatTrainTime(train.formattedTime))
                                .foregroundStyle(.red)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
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
    
    /// Convert MTR station code to localized name
    private func getStationName(_ code: String) -> String {
        let stationNames: [String: (tc: String, en: String)] = [
            "CEN": (tc: "中環", en: "Central"),
            "ADM": (tc: "金鐘", en: "Admiralty"),
            "TSW": (tc: "荃灣", en: "Tsuen Wan"),
            "TWS": (tc: "荃灣西", en: "Tsuen Wan West"),
            "SKW": (tc: "筲箕灣", en: "Shau Kei Wan"),
            "QUB": (tc: "鰂魚涌", en: "Quarry Bay"),
            "TUC": (tc: "東涌", en: "Tung Chung"),
            "KWT": (tc: "觀塘", en: "Kwun Tong"),
            "TKO": (tc: "將軍澳", en: "Tseung Kwan O"),
            "TUM": (tc: "屯門", en: "Tuen Mun"),
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
            Text(stationName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.hikingGreen.opacity(0.1), in: Capsule())
                .foregroundStyle(Color.hikingGreen)
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
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localizedString(for: "transport.bus.search.title"))
                        .font(.headline)
                    
                    TextField(languageManager.localizedString(for: "transport.bus.search.placeholder"), text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchBusRoutes()
                        }
                    
                    Button(languageManager.localizedString(for: "transport.search")) {
                        searchBusRoutes()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.isEmpty)
                }
                .padding()
                
                // Search results
                if isLoadingBus {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = busError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.largeTitle)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if !searchResults.isEmpty {
                    searchResultsView
                } else if selectedRoute != nil {
                    routeDetailView
                } else {
                    VStack {
                        Image(systemName: "bus.fill")
                            .foregroundStyle(.orange)
                            .font(.largeTitle)
                        Text(languageManager.localizedString(for: "transport.bus.no.results"))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "transport.bus.results"))
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(searchResults.prefix(20)) { route in
                Button {
                    loadRouteDetail(route: route)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(route.route) \(route.bound == "O" ? "→" : "←")")
                                .font(.headline)
                            Text("\(route.localizedOrigin(languageManager: languageManager)) → \(route.localizedDestination(languageManager: languageManager))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
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
                                selectedStop = stop
                                loadBusETA(stop: stop, route: route)
                            } label: {
                                HStack {
                                    Text(stop.localizedName(languageManager: languageManager))
                                    Spacer()
                                    if selectedStop?.id == stop.id && !busETAs.isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding()
                                .background(
                                    selectedStop?.id == stop.id ? Color.orange.opacity(0.1) : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // ETA display
                if !busETAs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.localizedString(for: "transport.bus.eta"))
                            .font(.headline)
                        
                        ForEach(busETAs) { eta in
                            HStack {
                                Text(eta.localizedDestination(languageManager: languageManager))
                                Spacer()
                                Text(eta.formattedETA)
                                    .foregroundStyle(.orange)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
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
        
        Task {
            do {
                let results = try await kmbService.searchRoutes(keyword: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isLoadingBus = false
                    if results.isEmpty {
                        self.busError = languageManager.localizedString(for: "transport.bus.no.results")
                    } else {
                        self.busError = nil
                    }
                    print("✅ Bus search successful: Found \(results.count) routes for '\(searchText)'")
                }
            } catch {
                await MainActor.run {
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                    self.isLoadingBus = false
                    print("❌ Bus search error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                }
            }
        }
    }
    
    private func loadRouteDetail(route: KMBRoute) {
        selectedRoute = route
        routeStops = []
        busETAs = []
        selectedStop = nil
        
        Task {
            do {
                if let detail = try await kmbService.fetchRouteDetail(
                    route: route.route,
                    direction: route.bound,
                    serviceType: route.service_type
                ) {
                    await MainActor.run {
                        self.routeStops = detail.stops ?? []
                    }
                }
            } catch {
                await MainActor.run {
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                }
            }
        }
    }
    
    private func loadBusETA(stop: KMBStop, route: KMBRoute) {
        selectedStop = stop
        busETAs = []
        
        Task {
            do {
                let etas = try await kmbService.fetchETA(
                    stopId: stop.stop,
                    route: route.route,
                    serviceType: route.service_type
                )
                await MainActor.run {
                    self.busETAs = etas
                }
            } catch {
                await MainActor.run {
                    self.busError = languageManager.localizedString(for: "transport.bus.error.load.failed")
                }
            }
        }
    }
}

