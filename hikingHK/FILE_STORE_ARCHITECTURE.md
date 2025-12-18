# 統一 FileManager + JSON 架構設計

## 概述

這個架構提供了一個統一、可擴展的方式來使用 FileManager + JSON 進行數據持久化，替代 SwiftData 以避免同步問題。

## 架構組件

### 1. `FileStoreProtocol`
定義了所有文件存儲必須實現的接口：
- `loadAll()` - 加載所有數據
- `saveOrUpdate(_:)` - 保存或更新單個項目
- `delete(_:)` - 刪除單個項目
- `saveAll(_:)` - 批量保存
- `deleteAll()` - 刪除所有數據

### 2. `FileStoreDTO` Protocol
定義了 DTO（Data Transfer Object）的轉換接口：
- `init(from model:)` - 從領域模型創建 DTO
- `toModel()` - 將 DTO 轉換回領域模型

### 3. `BaseFileStore<Model, DTO>`
提供通用的文件操作實現：
- 自動處理 JSON 編碼/解碼
- 文件路徑管理
- 錯誤處理
- 原子寫入（防止數據損壞）

### 4. `FileStoreError`
統一的錯誤類型，涵蓋所有可能的文件操作錯誤。

## 使用方式

### 步驟 1: 定義 DTO

```swift
private struct MyModelDTO: FileStoreDTO {
    var id: UUID
    var name: String
    var createdAt: Date
    
    // 必須實現：返回模型的 ID
    var modelId: UUID { id }
    
    // 實現 FileStoreDTO
    init(from model: MyModel) {
        self.id = model.id
        self.name = model.name
        self.createdAt = model.createdAt
    }
    
    func toModel() -> MyModel {
        MyModel(id: id, name: name, createdAt: createdAt)
    }
}
```

### 步驟 2: 創建 Store 類

```swift
@MainActor
final class MyModelFileStore: BaseFileStore<MyModel, MyModelDTO> {
    init() {
        super.init(fileName: "my_models.json")
    }
    
    // 可選：自定義排序或過濾
    override func loadAll() throws -> [MyModel] {
        let all = try super.loadAll()
        return all.sorted { $0.createdAt > $1.createdAt }
    }
}
```

### 步驟 3: 使用 Store

```swift
let store = MyModelFileStore()

// 加載所有數據
let items = try store.loadAll()

// 保存新項目
try store.saveOrUpdate(newItem)

// 更新現有項目
try store.saveOrUpdate(existingItem)

// 刪除項目
try store.delete(item)

// 批量保存
try store.saveAll([item1, item2, item3])

// 清空所有數據
try store.deleteAll()
```

## 優勢

1. **統一接口** - 所有 Store 使用相同的 API
2. **類型安全** - 編譯時檢查，避免運行時錯誤
3. **代碼復用** - 通用邏輯在基類中實現
4. **易於測試** - 可以輕鬆創建內存版本的 Store
5. **易於擴展** - 子類可以覆蓋方法添加自定義邏輯
6. **錯誤處理** - 統一的錯誤類型，易於處理

## 遷移現有 Store

### 遷移 JournalFileStore

1. 將 `PersistedJournal` 改為實現 `FileStoreDTO`
2. 讓 `JournalFileStore` 繼承 `BaseFileStore<HikeJournal, PersistedJournalDTO>`
3. 移除重複的文件操作代碼
4. 保留自定義的排序邏輯（如果需要）

### 遷移其他 Store

同樣的模式適用於：
- `OfflineMapsFileStore`
- 未來的其他 Store（如 `HikeRecordFileStore`, `AchievementFileStore` 等）

## 文件位置

所有 JSON 文件默認保存在：
```
Documents/
├── journals.json
├── offline_maps.json
├── hike_records.json
└── ...
```

## 錯誤處理示例

```swift
do {
    try store.saveOrUpdate(item)
} catch FileStoreError.encodingFailed(let error) {
    print("編碼失敗: \(error)")
} catch FileStoreError.writeFailed(let error) {
    print("寫入失敗: \(error)")
} catch {
    print("未知錯誤: \(error)")
}
```

## 性能考慮

- **原子寫入** - 使用 `.atomic` 選項防止數據損壞
- **批量操作** - 使用 `saveAll()` 而不是多次調用 `saveOrUpdate()`
- **懶加載** - 只在需要時加載數據

## 未來擴展

可以添加的功能：
- 數據遷移支持
- 版本控制
- 壓縮支持
- 加密支持
- 備份/恢復功能

