//
//  TrailRecommendationViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class TrailRecommendationViewModel: ObservableObject {
    @Published var recommendations: [TrailRecommendation] = []
    @Published var userPreference: UserPreference?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var availableTime: TimeInterval? // 可用時間（秒）
    
    private var store: RecommendationStore?
    private var modelContext: ModelContext?
    private let recommendationService: TrailRecommendationServiceProtocol
    private let appViewModel: AppViewModel
    
    init(
        appViewModel: AppViewModel,
        recommendationService: TrailRecommendationServiceProtocol = TrailRecommendationService()
    ) {
        self.appViewModel = appViewModel
        self.recommendationService = recommendationService
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        self.modelContext = context
        store = RecommendationStore(context: context)
        
        // 載入用戶偏好
        do {
            userPreference = try store?.loadUserPreference()
            if userPreference == nil {
                // 創建默認偏好
                userPreference = UserPreference()
            }
        } catch {
            self.error = "Failed to load user preferences: \(error.localizedDescription)"
        }
    }
    
    func generateRecommendations(availableTime: TimeInterval? = nil) async {
        guard let store = store else { return }
        
        isLoading = true
        error = nil
        self.availableTime = availableTime
        
        defer { isLoading = false }
        
        // 獲取用戶歷史記錄
        let history: [HikeRecord]
        if let context = modelContext {
            do {
                let recordStore = HikeRecordStore(context: context)
                history = try recordStore.loadAllRecords()
            } catch {
                history = []
            }
        } else {
            history = []
        }
        
        // 生成推薦
        let newRecommendations = recommendationService.recommendTrails(
            from: appViewModel.trails,
            userPreference: userPreference,
            weatherSnapshot: appViewModel.weatherSnapshot,
            currentTime: Date(),
            availableTime: availableTime,
            userHistory: history
        )
        
        recommendations = newRecommendations
        
        // 保存推薦記錄
        for recommendation in newRecommendations.prefix(10) { // 只保存前 10 個
            let record = RecommendationRecord(
                trailId: recommendation.trail.id,
                recommendationScore: recommendation.score,
                reason: recommendation.reasons.joined(separator: "；")
            )
            do {
                try store.saveRecommendation(record)
            } catch {
                print("保存推薦記錄失敗：\(error)")
            }
        }
    }
    
    func updateUserPreference(_ preference: UserPreference) {
        guard let store = store else { return }
        userPreference = preference
        preference.lastUpdated = Date()
        
        do {
            try store.saveUserPreference(preference)
        } catch {
            self.error = "Failed to save user preferences: \(error.localizedDescription)"
        }
    }
    
    func recordUserAction(for recommendation: TrailRecommendation, action: RecommendationRecord.UserAction) {
        guard let store = store else { return }
        
        do {
            let history = try store.loadRecommendationHistory(trailId: recommendation.trail.id)
            if let record = history.first(where: { $0.trailId == recommendation.trail.id && $0.recommendedAt > Date().addingTimeInterval(-3600) }) {
                try store.updateRecommendationAction(record, action: action)
            }
        } catch {
            print("記錄用戶操作失敗：\(error)")
        }
    }
}

