# 新 Store 使用指南

## 已創建的 Store

### ✅ HikeRecordFileStore
用於持久化行山記錄（HikeRecord）及其軌跡點（HikeTrackPoint）。

### ✅ AchievementFileStore
用於持久化成就徽章（Achievement）及其進度狀態。

---

## HikeRecordFileStore 使用示例

### 基本使用

```swift
import Foundation

@MainActor
class HikeRecordViewModel: ObservableObject {
    @Published var records: [HikeRecord] = []
    private let fileStore = HikeRecordFileStore()
    
    // 加載所有記錄
    func loadRecords() {
        do {
            records = try fileStore.loadAll()
            // 記錄會自動按開始時間排序（最新的在前）
        } catch {
            print("Failed to load records: \(error)")
        }
    }
    
    // 保存新記錄
    func saveRecord(_ record: HikeRecord) {
        do {
            try fileStore.saveOrUpdate(record)
            loadRecords() // 重新加載以更新列表
        } catch {
            print("Failed to save record: \(error)")
        }
    }
    
    // 更新記錄
    func updateRecord(_ record: HikeRecord) {
        do {
            try fileStore.saveOrUpdate(record)
            loadRecords()
        } catch {
            print("Failed to update record: \(error)")
        }
    }
    
    // 刪除記錄
    func deleteRecord(_ record: HikeRecord) {
        do {
            try fileStore.delete(record)
            loadRecords()
        } catch {
            print("Failed to delete record: \(error)")
        }
    }
    
    // 批量保存
    func saveAllRecords(_ records: [HikeRecord]) {
        do {
            try fileStore.saveAll(records)
            loadRecords()
        } catch {
            print("Failed to save records: \(error)")
        }
    }
}
```

### 創建記錄示例

```swift
// 創建一個新的行山記錄
let record = HikeRecord(
    trailId: someTrailId,
    trailName: "Dragon's Back",
    startTime: Date(),
    isCompleted: false,
    totalDistance: 0,
    notes: "Starting hike"
)

// 添加軌跡點
let trackPoint = HikeTrackPoint(
    latitude: 22.267,
    longitude: 114.188,
    altitude: 100,
    speed: 0,
    timestamp: Date()
)
record.trackPoints.append(trackPoint)

// 保存記錄
try fileStore.saveOrUpdate(record)
```

---

## AchievementFileStore 使用示例

### 基本使用

```swift
import Foundation

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    private let fileStore = AchievementFileStore()
    
    // 加載所有成就
    func loadAchievements() {
        do {
            achievements = try fileStore.loadAll()
            // 成就會自動按徽章類型和目標值排序
        } catch {
            print("Failed to load achievements: \(error)")
        }
    }
    
    // 保存成就
    func saveAchievement(_ achievement: Achievement) {
        do {
            try fileStore.saveOrUpdate(achievement)
            loadAchievements()
        } catch {
            print("Failed to save achievement: \(error)")
        }
    }
    
    // 更新成就進度
    func updateProgress(forId id: String, value: Double) {
        do {
            try fileStore.updateProgress(forId: id, value: value)
            loadAchievements()
        } catch {
            print("Failed to update progress: \(error)")
        }
    }
    
    // 解鎖成就
    func unlockAchievement(id: String) {
        do {
            try fileStore.unlock(achievementId: id)
            loadAchievements()
        } catch {
            print("Failed to unlock achievement: \(error)")
        }
    }
    
    // 查找特定成就
    func findAchievement(id: String) -> Achievement? {
        do {
            return try fileStore.findById(id)
        } catch {
            print("Failed to find achievement: \(error)")
            return nil
        }
    }
}
```

### 初始化默認成就

```swift
// 加載或創建默認成就
func initializeDefaultAchievements() {
    do {
        let existing = try fileStore.loadAll()
        
        if existing.isEmpty {
            // 如果沒有成就，創建默認成就
            let defaults = Achievement.defaultAchievements
            try fileStore.saveAll(defaults)
            achievements = defaults
        } else {
            achievements = existing
        }
    } catch {
        print("Failed to initialize achievements: \(error)")
    }
}
```

### 更新成就進度示例

```swift
// 當用戶完成一次行山後，更新距離相關成就
func updateDistanceAchievements(totalDistanceKm: Double) {
    let distanceAchievements = [
        "distance_10km",
        "distance_50km",
        "distance_100km",
        "distance_500km"
    ]
    
    for achievementId in distanceAchievements {
        do {
            if var achievement = try fileStore.findById(achievementId) {
                let newValue = achievement.currentValue + totalDistanceKm
                try fileStore.updateProgress(forId: achievementId, value: newValue)
            }
        } catch {
            print("Failed to update achievement \(achievementId): \(error)")
        }
    }
}
```

---

## 文件位置

兩個 Store 的 JSON 文件都保存在 `Documents/` 目錄：

- `Documents/hike_records.json` - 行山記錄
- `Documents/achievements.json` - 成就數據

## 數據遷移

如果需要從 SwiftData 遷移到 FileStore：

### 遷移 HikeRecord

```swift
func migrateHikeRecordsFromSwiftData(context: ModelContext) throws {
    // 1. 從 SwiftData 加載
    let descriptor = FetchDescriptor<HikeRecord>()
    let swiftDataRecords = try context.fetch(descriptor)
    
    // 2. 使用 FileStore 保存
    let fileStore = HikeRecordFileStore()
    try fileStore.saveAll(swiftDataRecords)
    
    // 3. 驗證
    let migrated = try fileStore.loadAll()
    assert(migrated.count == swiftDataRecords.count)
}
```

### 遷移 Achievement

```swift
func migrateAchievementsFromSwiftData(context: ModelContext) throws {
    // 1. 從 SwiftData 加載
    let descriptor = FetchDescriptor<Achievement>()
    let swiftDataAchievements = try context.fetch(descriptor)
    
    // 2. 使用 FileStore 保存
    let fileStore = AchievementFileStore()
    try fileStore.saveAll(swiftDataAchievements)
    
    // 3. 驗證
    let migrated = try fileStore.loadAll()
    assert(migrated.count == swiftDataAchievements.count)
}
```

## 注意事項

1. **HikeRecordFileStore**:
   - 自動保存和恢復 `trackPoints` 關聯
   - 記錄按開始時間降序排序
   - 支持完整的軌跡點數據（經緯度、海拔、速度等）

2. **AchievementFileStore**:
   - 使用 String ID（不是 UUID）
   - 提供便利方法：`findById()`, `updateProgress()`, `unlock()`
   - 成就按徽章類型和目標值排序
   - `modelId` 會將 String ID 轉換為穩定的 UUID

3. **性能**:
   - 所有操作都是同步的（在主線程）
   - 使用原子寫入防止數據損壞
   - 批量操作使用 `saveAll()` 更高效

4. **錯誤處理**:
   - 所有方法都可能拋出 `FileStoreError`
   - 建議使用 `do-catch` 處理錯誤
   - 檢查文件是否存在和可讀性

## 測試建議

### HikeRecordFileStore 測試
- [ ] 測試保存新記錄
- [ ] 測試更新記錄
- [ ] 測試刪除記錄
- [ ] 測試加載所有記錄（驗證排序）
- [ ] 測試軌跡點關聯
- [ ] 測試批量保存

### AchievementFileStore 測試
- [ ] 測試加載所有成就
- [ ] 測試保存成就
- [ ] 測試更新進度
- [ ] 測試解鎖成就
- [ ] 測試查找成就（按 String ID）
- [ ] 測試排序邏輯

