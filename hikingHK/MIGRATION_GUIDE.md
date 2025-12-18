# 遷移到統一 FileManager + JSON 架構指南

## 概述

本指南將幫助你將現有的 SwiftData 或獨立實現的 FileStore 遷移到統一的 `BaseFileStore` 架構。

## 遷移步驟

### 1. 分析現有 Store

檢查你的 Store 需要：
- 保存哪些數據模型
- 是否需要自定義排序
- 是否需要過濾或查詢功能

### 2. 創建 DTO

為每個數據模型創建對應的 DTO：

```swift
private struct MyModelDTO: FileStoreDTO {
    // 所有需要持久化的屬性
    var id: UUID
    var name: String
    var createdAt: Date
    
    // 必須實現：modelId 屬性
    var modelId: UUID { id }
    
    // 從模型創建 DTO
    init(from model: MyModel) {
        self.id = model.id
        self.name = model.name
        self.createdAt = model.createdAt
    }
    
    // 將 DTO 轉換回模型
    func toModel() -> MyModel {
        MyModel(
            id: id,
            name: name,
            createdAt: createdAt
        )
    }
}
```

### 3. 創建 Store 類

繼承 `BaseFileStore` 並指定類型參數：

```swift
@MainActor
final class MyModelFileStore: BaseFileStore<MyModel, MyModelDTO> {
    init() {
        super.init(fileName: "my_models.json")
    }
    
    // 可選：自定義加載邏輯（例如排序）
    override func loadAll() throws -> [MyModel] {
        let all = try super.loadAll()
        return all.sorted { $0.createdAt > $1.createdAt }
    }
}
```

### 4. 更新 ViewModel

將 ViewModel 中的 Store 引用更新為新的 FileStore：

```swift
// 舊代碼
private var store: MyModelStore?

// 新代碼
private let fileStore = MyModelFileStore()
```

### 5. 更新方法調用

將所有 Store 方法調用更新為 FileStore 方法：

```swift
// 舊代碼
let items = try store.loadAllItems()

// 新代碼
let items = try fileStore.loadAll()
```

## 遷移現有 Store 的具體示例

### 遷移 JournalFileStore

**步驟 1**: 更新 DTO 實現 `modelId`

```swift
private struct PersistedJournal: FileStoreDTO {
    // ... 現有屬性 ...
    
    var modelId: UUID { id }  // 添加這一行
    
    // ... 現有方法 ...
}
```

**步驟 2**: 重構 Store 類

```swift
@MainActor
final class JournalFileStore: BaseFileStore<HikeJournal, PersistedJournal> {
    init() {
        super.init(fileName: "journals.json")
    }
    
    override func loadAll() throws -> [HikeJournal] {
        let all = try super.loadAll()
        return all.sorted { $0.hikeDate > $1.hikeDate }
    }
}
```

**步驟 3**: 移除重複代碼

刪除以下方法（已在 BaseFileStore 中實現）：
- `loadPersistedJournals()`
- `persist(journals:)`
- 文件路徑管理代碼

### 遷移 OfflineMapsFileStore

同樣的模式：

```swift
@MainActor
final class OfflineMapsFileStore: BaseFileStore<OfflineMapRegion, PersistedOfflineRegion> {
    init() {
        super.init(fileName: "offline_maps.json")
    }
    
    override func loadAll() throws -> [OfflineMapRegion] {
        let all = try super.loadAll()
        return all.sorted { $0.name < $1.name }
    }
}
```

## 遷移其他數據模型

### HikeRecord

```swift
private struct PersistedHikeRecordDTO: FileStoreDTO {
    var id: UUID
    // ... 其他屬性 ...
    
    var modelId: UUID { id }
    
    init(from model: HikeRecord) { /* ... */ }
    func toModel() -> HikeRecord { /* ... */ }
}

@MainActor
final class HikeRecordFileStore: BaseFileStore<HikeRecord, PersistedHikeRecordDTO> {
    init() {
        super.init(fileName: "hike_records.json")
    }
}
```

### Achievement

```swift
private struct PersistedAchievementDTO: FileStoreDTO {
    var id: UUID
    // ... 其他屬性 ...
    
    var modelId: UUID { id }
    
    init(from model: Achievement) { /* ... */ }
    func toModel() -> Achievement { /* ... */ }
}

@MainActor
final class AchievementFileStore: BaseFileStore<Achievement, PersistedAchievementDTO> {
    init() {
        super.init(fileName: "achievements.json")
    }
}
```

## 數據遷移

如果需要從 SwiftData 遷移現有數據：

```swift
func migrateFromSwiftData() throws {
    // 1. 從 SwiftData 加載數據
    let swiftDataItems = try context.fetch(FetchDescriptor<MyModel>())
    
    // 2. 使用新的 FileStore 保存
    let fileStore = MyModelFileStore()
    try fileStore.saveAll(swiftDataItems)
    
    // 3. 驗證遷移
    let migrated = try fileStore.loadAll()
    assert(migrated.count == swiftDataItems.count)
}
```

## 測試

為每個新的 FileStore 編寫測試：

```swift
func testMyModelFileStore() throws {
    let store = MyModelFileStore()
    
    // 測試保存和加載
    let item = MyModel(id: UUID(), name: "Test", createdAt: Date())
    try store.saveOrUpdate(item)
    
    let loaded = try store.loadAll()
    XCTAssertEqual(loaded.count, 1)
    XCTAssertEqual(loaded.first?.name, "Test")
    
    // 測試更新
    var updated = item
    updated.name = "Updated"
    try store.saveOrUpdate(updated)
    
    let reloaded = try store.loadAll()
    XCTAssertEqual(reloaded.first?.name, "Updated")
    
    // 測試刪除
    try store.delete(item)
    let afterDelete = try store.loadAll()
    XCTAssertEqual(afterDelete.count, 0)
}
```

## 注意事項

1. **文件位置**: 所有 JSON 文件保存在 `Documents/` 目錄
2. **原子寫入**: 使用 `.atomic` 選項防止數據損壞
3. **錯誤處理**: 始終使用 `try/catch` 處理 FileStore 操作
4. **主線程**: FileStore 操作應該在 `@MainActor` 上下文中執行
5. **備份**: 遷移前建議備份現有數據

## 遷移檢查清單

- [ ] 創建 DTO 並實現 `FileStoreDTO`
- [ ] 實現 `modelId` 屬性
- [ ] 創建繼承 `BaseFileStore` 的 Store 類
- [ ] 更新 ViewModel 使用新的 FileStore
- [ ] 更新所有方法調用
- [ ] 測試保存/加載/更新/刪除功能
- [ ] 測試數據遷移（如果適用）
- [ ] 移除舊的 Store 實現
- [ ] 更新文檔

