# SwiftData 遷移到 FileManager + JSON 計劃

## 概述

本計劃將逐步將所有複雜數據從 SwiftData 遷移到 FileManager + JSON 架構，同時保留 UserDefaults 用於簡單設置。

## 數據分類

### ✅ 已遷移（使用 FileManager + JSON）
1. **HikeJournal** - `JournalFileStore`
2. **OfflineMapRegion** - `OfflineMapsFileStore`
3. **HikeRecord** - `HikeRecordFileStore`
4. **Achievement** - `AchievementFileStore`

### 🆕 新建 Store（待遷移）
5. **EmergencyContact** - `EmergencyContactFileStore`
6. **GearItem** - `GearItemFileStore`
7. **LocationShareSession** - `LocationShareSessionFileStore`
8. **RecommendationRecord** - `RecommendationRecordFileStore`
9. **SafetyChecklistItem** - `SafetyChecklistItemFileStore`
10. **UserPreference** - `UserPreferenceFileStore`

### 📝 保留 UserDefaults（簡單設置）
- 用戶語言設置
- 登入狀態
- 簡單的開關設置
- 臨時緩存數據

## 遷移步驟

### 階段 1: 準備工作（已完成）
- [x] 創建統一架構（`BaseFileStore`, `FileStoreProtocol`）
- [x] 遷移 `JournalFileStore`
- [x] 遷移 `OfflineMapsFileStore`
- [x] 創建 `HikeRecordFileStore`
- [x] 創建 `AchievementFileStore`

### 階段 2: 創建新 Store（已完成）
- [x] 創建 `EmergencyContactFileStore`
- [x] 創建 `GearItemFileStore`
- [x] 創建 `LocationShareSessionFileStore`
- [x] 創建 `RecommendationRecordFileStore`
- [x] 創建 `SafetyChecklistItemFileStore`
- [x] 創建 `UserPreferenceFileStore`

### 階段 3: 更新 ViewModel（待執行）

#### 3.1 EmergencyContact
**文件**: `hikingHK/ViewModels/LocationSharingViewModel.swift`
- [ ] 將 `EmergencyContact` 的 SwiftData 查詢替換為 `EmergencyContactFileStore`
- [ ] 更新所有 CRUD 操作
- [ ] 測試添加、刪除、設置主要聯繫人

#### 3.2 GearItem
**文件**: `hikingHK/ViewModels/GearChecklistViewModel.swift`
- [ ] 將 `GearItem` 的 SwiftData 查詢替換為 `GearItemFileStore`
- [ ] 更新裝備清單的加載和保存
- [ ] 測試按類別篩選、按遠足篩選

#### 3.3 LocationShareSession
**文件**: `hikingHK/ViewModels/LocationSharingViewModel.swift`
- [ ] 將 `LocationShareSession` 的 SwiftData 查詢替換為 `LocationShareSessionFileStore`
- [ ] 更新會話的啟動、更新、停止
- [ ] 測試位置分享功能

#### 3.4 RecommendationRecord
**文件**: `hikingHK/ViewModels/TrailRecommendationViewModel.swift`
- [ ] 將 `RecommendationRecord` 的 SwiftData 查詢替換為 `RecommendationRecordFileStore`
- [ ] 更新推薦記錄的保存和查詢
- [ ] 測試推薦歷史記錄

#### 3.5 SafetyChecklistItem
**文件**: `hikingHK/ViewModels/SafetyChecklistViewModel.swift`
- [ ] 將 `SafetyChecklistItem` 的 SwiftData 查詢替換為 `SafetyChecklistItemFileStore`
- [ ] 移除 UserDefaults 備份邏輯（不再需要）
- [ ] 更新清單項目的加載、保存、排序
- [ ] 測試完成狀態、添加、刪除、排序

#### 3.6 UserPreference
**文件**: `hikingHK/ViewModels/TrailRecommendationViewModel.swift` 或新建 `UserPreferenceViewModel`
- [ ] 將 `UserPreference` 的 SwiftData 查詢替換為 `UserPreferenceFileStore`
- [ ] 更新偏好設置的保存和加載
- [ ] 測試偏好設置的更新

### 階段 4: 數據遷移（待執行）

為每個 Store 創建遷移函數，從 SwiftData 遷移現有數據：

```swift
// 示例：遷移 EmergencyContact
func migrateEmergencyContactsFromSwiftData(context: ModelContext) throws {
    let descriptor = FetchDescriptor<EmergencyContact>()
    let swiftDataContacts = try context.fetch(descriptor)
    
    let fileStore = EmergencyContactFileStore()
    try fileStore.saveAll(swiftDataContacts)
    
    print("✅ Migrated \(swiftDataContacts.count) emergency contacts")
}
```

### 階段 5: 清理（待執行）
- [ ] 移除 SwiftData 的 `@Model` 標記（可選，保留用於向後兼容）
- [ ] 移除舊的 Store 實現（如 `EmergencyContactStore`）
- [ ] 更新文檔
- [ ] 測試所有功能

## 遷移優先級

### 高優先級（用戶數據）
1. **SafetyChecklistItem** - 用戶經常使用，需要穩定
2. **EmergencyContact** - 安全相關，需要可靠
3. **UserPreference** - 影響推薦功能

### 中優先級（功能數據）
4. **GearItem** - 裝備清單功能
5. **LocationShareSession** - 位置分享功能
6. **RecommendationRecord** - 推薦歷史

## 遷移檢查清單

### 每個 Store 遷移時需要：
- [ ] 創建 FileStore 類（✅ 已完成）
- [ ] 更新 ViewModel 使用新 Store
- [ ] 創建數據遷移函數
- [ ] 測試加載、保存、更新、刪除
- [ ] 測試排序和篩選功能
- [ ] 驗證數據完整性
- [ ] 更新相關文檔

## 注意事項

### 1. 向後兼容
- 保留 SwiftData 模型定義（移除 `@Model` 標記可選）
- 可以同時支持兩種存儲方式，逐步遷移

### 2. 數據遷移時機
- 在應用啟動時檢查並遷移
- 只遷移一次，避免重複遷移
- 遷移後標記，不再從 SwiftData 讀取

### 3. 錯誤處理
- 遷移失敗時保留 SwiftData 數據
- 記錄遷移日誌
- 提供回滾機制（可選）

### 4. 性能考慮
- 批量遷移使用 `saveAll()`
- 異步執行遷移，不阻塞 UI
- 顯示遷移進度（可選）

## 遷移腳本示例

```swift
@MainActor
class DataMigrationManager {
    private var hasMigrated = UserDefaults.standard.bool(forKey: "hasMigratedToFileStore")
    
    func migrateIfNeeded(context: ModelContext) async {
        guard !hasMigrated else { return }
        
        do {
            // 遷移各個 Store
            try await migrateEmergencyContacts(context: context)
            try await migrateGearItems(context: context)
            try await migrateLocationShareSessions(context: context)
            try await migrateRecommendationRecords(context: context)
            try await migrateSafetyChecklistItems(context: context)
            try await migrateUserPreferences(context: context)
            
            // 標記為已遷移
            UserDefaults.standard.set(true, forKey: "hasMigratedToFileStore")
            print("✅ All data migrated successfully")
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
    
    private func migrateEmergencyContacts(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<EmergencyContact>()
        let items = try context.fetch(descriptor)
        let store = EmergencyContactFileStore()
        try store.saveAll(items)
    }
    
    // ... 其他遷移函數
}
```

## 文件結構

```
hikingHK/Stores/
├── FileStoreProtocol.swift           # 協議定義
├── BaseFileStore.swift               # 基類實現
├── JournalFileStore.swift            # ✅ 已遷移
├── OfflineMapsFileStore.swift         # ✅ 已遷移
├── HikeRecordFileStore.swift         # ✅ 新建
├── AchievementFileStore.swift        # ✅ 新建
├── EmergencyContactFileStore.swift   # ✅ 新建
├── GearItemFileStore.swift           # ✅ 新建
├── LocationShareSessionFileStore.swift # ✅ 新建
├── RecommendationRecordFileStore.swift # ✅ 新建
├── SafetyChecklistItemFileStore.swift  # ✅ 新建
└── UserPreferenceFileStore.swift     # ✅ 新建
```

## 測試計劃

### 單元測試
- [ ] 測試每個 Store 的 CRUD 操作
- [ ] 測試排序和篩選
- [ ] 測試數據遷移
- [ ] 測試錯誤處理

### 集成測試
- [ ] 測試 ViewModel 與新 Store 的集成
- [ ] 測試數據遷移流程
- [ ] 測試向後兼容性

### 用戶測試
- [ ] 測試所有功能正常
- [ ] 驗證數據不丟失
- [ ] 檢查性能影響

## 完成標準

- [x] 所有 Store 已創建
- [ ] 所有 ViewModel 已更新
- [ ] 數據遷移已完成
- [ ] 所有測試通過
- [ ] 文檔已更新
- [ ] 用戶數據已驗證

## 下一步

1. 開始更新 ViewModel（從 SafetyChecklistItem 開始）
2. 創建數據遷移管理器
3. 逐步測試和驗證
4. 部署到生產環境

