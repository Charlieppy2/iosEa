# FileManager + JSON Store 總結

## 已創建的 Store 列表

### ✅ 核心 Store（已遷移/新建）

1. **JournalFileStore** - 行山日記
   - 文件: `journals.json`
   - 狀態: ✅ 已遷移並使用中

2. **OfflineMapsFileStore** - 離線地圖區域
   - 文件: `offline_maps.json`
   - 狀態: ✅ 已遷移並使用中

3. **HikeRecordFileStore** - 行山記錄
   - 文件: `hike_records.json`
   - 狀態: ✅ 新建，待集成

4. **AchievementFileStore** - 成就徽章
   - 文件: `achievements.json`
   - 狀態: ✅ 新建，待集成

### ✅ 新建 Store（待遷移）

5. **EmergencyContactFileStore** - 緊急聯繫人
   - 文件: `emergency_contacts.json`
   - 特殊功能: 主要聯繫人管理
   - 狀態: ✅ 已創建，待集成

6. **GearItemFileStore** - 裝備清單
   - 文件: `gear_items.json`
   - 特殊功能: 按類別、遠足、必需狀態篩選
   - 狀態: ✅ 已創建，待集成

7. **LocationShareSessionFileStore** - 位置分享會話
   - 文件: `location_share_sessions.json`
   - 特殊功能: 活動會話管理
   - 狀態: ✅ 已創建，待集成

8. **RecommendationRecordFileStore** - 推薦記錄
   - 文件: `recommendation_records.json`
   - 特殊功能: 按路線、用戶操作篩選
   - 狀態: ✅ 已創建，待集成

9. **SafetyChecklistItemFileStore** - 安全檢查清單
   - 文件: `safety_checklist_items.json`
   - 特殊功能: 完成狀態、完成百分比
   - 狀態: ✅ 已創建，待集成

10. **UserPreferenceFileStore** - 用戶偏好
    - 文件: `user_preferences.json`
    - 特殊功能: 當前偏好管理
    - 狀態: ✅ 已創建，待集成

## 架構特點

### 統一接口
所有 Store 都繼承 `BaseFileStore`，提供統一的 API：
- `loadAll()` - 加載所有數據
- `saveOrUpdate(_:)` - 保存或更新
- `delete(_:)` - 刪除
- `saveAll(_:)` - 批量保存
- `deleteAll()` - 清空所有數據

### 特殊處理
- **String ID 轉換**: `AchievementFileStore`, `GearItemFileStore`, `SafetyChecklistItemFileStore` 使用 String ID，自動轉換為 UUID
- **嵌套數據**: `HikeRecordFileStore` 處理 `trackPoints`，`LocationShareSessionFileStore` 處理 `emergencyContacts`
- **自定義排序**: 每個 Store 都有適合的排序邏輯

### 便利方法
每個 Store 都提供針對性的便利方法：
- `EmergencyContactFileStore`: `getPrimaryContact()`, `setPrimaryContact(_:)`
- `GearItemFileStore`: `getItemsForHike(_:)`, `getItemsByCategory(_:)`, `getRequiredItems()`
- `LocationShareSessionFileStore`: `getActiveSession()`, `deactivateAllSessions()`
- `RecommendationRecordFileStore`: `getRecordsForTrail(_:)`, `getRecordsWithAction(_:)`
- `SafetyChecklistItemFileStore`: `getCompletedItems()`, `getCompletionPercentage()`
- `UserPreferenceFileStore`: `getCurrentPreference()`, `saveCurrentPreference(_:)`

## 文件位置

所有 JSON 文件保存在：
```
Documents/
├── journals.json
├── offline_maps.json
├── hike_records.json
├── achievements.json
├── emergency_contacts.json
├── gear_items.json
├── location_share_sessions.json
├── recommendation_records.json
├── safety_checklist_items.json
└── user_preferences.json
```

## 數據持久化策略

### FileManager + JSON（複雜數據）
- 所有用戶創建的內容
- 所有需要查詢和關聯的數據
- 所有需要版本控制的數據

### UserDefaults（簡單設置）
- 用戶語言設置
- 登入狀態
- 簡單的開關設置
- 臨時緩存數據

## 下一步行動

### 立即執行
1. 更新 ViewModel 使用新的 Store
2. 創建數據遷移管理器
3. 逐步測試每個 Store

### 優先級
1. **高優先級**: SafetyChecklistItem, EmergencyContact, UserPreference
2. **中優先級**: GearItem, LocationShareSession, RecommendationRecord
3. **低優先級**: HikeRecord, Achievement（已創建但可能未使用）

## 文檔

- `FILE_STORE_ARCHITECTURE.md` - 架構設計文檔
- `MIGRATION_GUIDE.md` - 遷移指南
- `MIGRATION_COMPLETE.md` - 遷移完成報告
- `NEW_STORES_USAGE.md` - 新 Store 使用指南
- `SWIFTDATA_MIGRATION_PLAN.md` - SwiftData 遷移計劃
- `STORES_SUMMARY.md` - 本文件（Store 總結）

## 統計

- **總 Store 數量**: 10
- **已遷移**: 2 (Journal, OfflineMaps)
- **新建**: 8
- **待集成**: 8
- **代碼行數**: 約 2000+ 行
- **代碼復用**: 約 90% 通過 BaseFileStore

## 優勢

1. **統一架構**: 所有 Store 使用相同的模式和接口
2. **類型安全**: 編譯時檢查，減少運行時錯誤
3. **易於維護**: 代碼集中在基類，易於更新和修復
4. **易於測試**: 可以輕鬆創建測試版本
5. **性能穩定**: 避免 SwiftData 的同步問題
6. **數據可控**: 100% 控制數據的讀寫行為

