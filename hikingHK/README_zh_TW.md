# HikingHK 🏔️

專為香港行山愛好者設計的 iOS 行山伴侶應用程式，使用 SwiftUI 和 SwiftData 構建。

## 概述

HikingHK 是一個功能豐富的行山應用程式，旨在幫助行山愛好者探索、計劃和追蹤他們在香港美麗山徑上的冒險。應用程式提供實時天氣資訊、路線詳情、離線地圖、安全檢查清單和 AR 地標識別功能。

## 功能特色

### 🏠 首頁
- **天氣儀表板**：來自香港天文台的實時天氣狀況
- **精選路線**：發現推薦的行山路線
- **快速操作**：
  - 路線警示 - 實時天氣和路線警告
  - 離線地圖 - 下載地圖供離線使用
  - AR 識別 - 使用 AR 技術識別附近山峰
- **即將計劃**：查看和管理您已安排的行程
- **安全檢查清單**：行山前的安全準備

### 🗺️ 路線
- **路線瀏覽器**：瀏覽 17+ 條香港行山路線
- **搜尋與篩選**：按名稱、地區或難度尋找路線
- **路線資料庫**：包含主要路線：
  - 麥理浩徑（第 1, 2, 3, 4, 5, 8 段）
  - 衛奕信徑（第 1, 2 段）
  - 鳳凰徑（第 2, 3 段）
  - 港島徑（第 1, 4 段）
  - 著名山峰：獅子山、大东山、蚺蛇尖、大帽山
  - 熱門路線：龍脊、山頂環回步行徑、大潭水塘
- **路線詳情**：
  - 互動地圖與路線視覺化
  - 檢查點和路線資訊
  - 設施和交通提示
  - 亮點和描述

### 📅 計劃
- **行程規劃**：安排您的行山行程
- **路線選擇**：從可用路線中選擇
- **備註**：添加集合點、裝備提醒和其他備註
- **日期管理**：設定和更新行山日期

### 👤 個人資料
- **帳戶管理**：安全的登入/登出認證
- **統計儀表板**：
  - 已計劃行程數
  - 收藏路線
  - 總記錄距離
- **目標追蹤**：
  - 完成 4 條山脊線（困難路線）
  - 本月記錄 50 公里
  - 進度條視覺化
- **服務狀態**：監控天氣 API、GPS 和離線地圖的連接狀態
- **API 連接檢查器**：實時 API 連接狀態監控

## 技術架構

### 核心技術
- **SwiftUI**：現代聲明式 UI 框架
- **SwiftData**：持久化數據存儲
- **CoreLocation**：GPS 和位置服務
- **Combine**：響應式編程

### 架構模式
- **MVVM 模式**：Model-View-ViewModel 架構
- **協議導向**：服務協議以提高可測試性
- **Async/Await**：現代並發處理網絡和數據操作

### 數據模型
- `UserCredential`：用戶認證數據
- `SavedHikeRecord`：已計劃和完成的行程
- `FavoriteTrailRecord`：用戶收藏的路線
- `SafetyChecklistItem`：安全檢查清單項目
- `OfflineMapRegion`：離線地圖下載狀態

## 安裝

### 系統要求
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### 設置步驟
1. 克隆倉庫：
```bash
git clone https://github.com/Charlieppy2/iosEa.git
cd iosEa/hikingHK
```

2. 在 Xcode 中打開專案：
```bash
open hikingHK.xcodeproj
```

3. 構建並運行專案（⌘R）

### 配置
- **Mapbox API**：設置 `MAPBOX_ACCESS_TOKEN` 環境變量以使用路線服務（可選）
- **位置服務**：應用程式會在需要時請求位置權限

## 專案結構

```
hikingHK/
├── Core/                    # 核心文件
│   ├── hikingHKApp.swift   # 應用入口
│   ├── RootView.swift      # 根視圖
│   ├── ContentView.swift   # 主內容視圖
│   ├── AppViewModel.swift  # 主應用視圖模型
│   ├── HikingTheme.swift   # 遠足主題樣式
│   └── APIConnectionChecker.swift # API 連接檢查器
│
├── Authentication/          # 認證模組
│   ├── AuthView.swift      # 登入/註冊界面
│   ├── SessionManager.swift # 會話管理
│   ├── AccountStore.swift  # 帳戶數據存儲
│   ├── UserAccount.swift   # 用戶帳戶模型
│   └── UserCredential.swift # 用戶憑證模型
│
├── Home/                    # 首頁模組
│   └── HomeView.swift      # 首頁視圖
│
├── Trails/                  # 路線模組
│   ├── TrailListView.swift # 路線列表視圖
│   ├── TrailDetailView.swift # 路線詳情視圖
│   ├── TrailMapView.swift  # 路線地圖視圖
│   ├── Trail.swift         # 路線數據模型
│   ├── TrailDataStore.swift # 路線數據存儲
│   └── FavoriteTrailRecord.swift # 收藏路線記錄
│
├── Planner/                 # 計劃模組
│   ├── PlannerView.swift   # 計劃視圖
│   ├── SavedHikeRecord.swift # 保存的行程記錄
│   └── ExperienceModels.swift # 體驗相關模型
│
├── Profile/                 # 個人資料模組
│   ├── ProfileView.swift   # 個人資料視圖
│   └── Goal.swift          # 目標追蹤模型
│
├── Services/                # 服務層
│   ├── WeatherService.swift # 天氣服務
│   ├── LocationManager.swift # 位置管理服務
│   ├── MapboxRouteService.swift # Mapbox 路線服務
│   ├── TrailAlertsService.swift # 路線警示服務
│   └── OfflineMapsDownloadService.swift # 離線地圖下載服務
│
├── ViewModels/              # 視圖模型
│   ├── TrailAlertsViewModel.swift
│   ├── OfflineMapsViewModel.swift
│   ├── SafetyChecklistViewModel.swift
│   ├── ServicesStatusViewModel.swift
│   └── ARLandmarkIdentifier.swift
│
├── DataModels/              # 數據模型
│   ├── TrailAlert.swift    # 路線警示模型
│   ├── Landmark.swift      # 地標模型
│   ├── OfflineMapRegion.swift # 離線地圖區域模型
│   └── SafetyChecklistItem.swift # 安全檢查清單項模型
│
└── Stores/                  # 數據存儲層
    ├── OfflineMapsStore.swift
    └── SafetyChecklistStore.swift
```

## 主要功能詳述

### 🔐 認證
- 安全的用戶註冊和登入
- 基於 SwiftData 的憑證存儲
- 自動會話恢復
- 用戶資料管理

### 📊 數據持久化
所有用戶數據使用 SwiftData 持久化：
- 用戶憑證
- 已保存的行程和完成狀態
- 收藏的路線
- 安全檢查清單進度
- 離線地圖下載

### 🌤️ 天氣整合
- 來自香港天文台 API 的實時天氣數據
- 溫度、濕度、UV 指數
- 天氣警告和建議
- 自動刷新功能

### 🗺️ 路線管理
- **17+ 條行山路線**涵蓋香港主要路線
- 難度等級（簡單、中等、困難）
- 互動地圖與路線視覺化
- 檢查點和海拔剖面
- 交通和設施資訊
- 涵蓋四大長途遠足徑（麥理浩徑、衛奕信徑、鳳凰徑、港島徑）

### 📱 離線地圖
- 下載地圖供離線使用
- 多個區域可用
- 下載進度追蹤
- 存儲管理

### ⚠️ 路線警示
- 實時天氣警告
- 路線維護通知
- 警示分類和嚴重程度等級
- 從 HKO API 自動更新

### 🎯 目標與統計
- 追蹤行山目標
- 每月距離記錄
- 山脊線完成追蹤
- 視覺進度指示器

### 🧭 AR 地標識別
- 使用 GPS 識別附近山峰
- 距離和方位計算
- 地標資訊顯示
- 實時掃描

### 🎨 UI/UX 設計
- **遠足主題**：自然色調（森林綠、大地棕、天空藍）
- **圖案背景**：微妙的山脈、樹木、雲朵和路徑圖案
- **卡片式設計**：現代卡片佈局，帶漸變和陰影
- **響應式佈局**：適應不同屏幕尺寸

## 開發

### 添加新功能
1. 在適當的目錄中創建模型
2. 遵循 MVVM 模式實現 ViewModels
3. 使用適當的狀態管理創建 SwiftUI 視圖
4. 如需持久化，添加 SwiftData 模型
5. 在 `hikingHKApp.swift` 中更新 `modelContainer`

### 測試
運行測試：
```bash
xcodebuild test -scheme hikingHK -destination 'platform=iOS Simulator,name=iPhone 15'
```

## API 整合

### 天氣 API ✅
- **端點**：`https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en`
- **狀態**：已連接
- **數據類型**：實時天氣讀數
- **功能**：溫度、濕度、UV 指數、天氣警告
- **更新頻率**：手動刷新或應用啟動時
- **連接檢查**：在個人資料 → API 狀態中可用

### Mapbox API ⚠️
- **端點**：`https://api.mapbox.com/directions/v5/mapbox/walking/`
- **狀態**：可選配置
- **要求**：需要 `MAPBOX_ACCESS_TOKEN` 環境變量
- **功能**：路線計算和導航
- **連接檢查**：在個人資料 → 數據與服務中可用

### API 連接監控
- 實時 API 狀態檢查
- 在個人資料頁面顯示連接狀態
- 手動刷新功能
- 最後檢查時間追蹤

## 數據隱私

- 所有用戶數據使用 SwiftData 本地存儲
- 除以下情況外，不會將數據傳輸到外部服務器：
  - 天氣 API（公開數據）
  - Mapbox API（路線計算，可選）
- 用戶憑證經過加密並安全存儲

## 路線資料庫

應用程式目前包含 **17 條行山路線**，涵蓋：
- **麥理浩徑**：第 1, 2, 3, 4, 5, 8 段
- **衛奕信徑**：第 1, 2 段
- **鳳凰徑**：第 2, 3 段
- **港島徑**：第 1, 4 段
- **著名山峰**：獅子山、大东山、蚺蛇尖、大帽山
- **熱門路線**：龍脊、山頂環回步行徑、大潭水塘

> **注意**：香港有超過 300 條行山路線。應用程式目前包含主要路線。更多路線可在未來更新中添加。

詳見 [TRAILS_LIST.md](TRAILS_LIST.md) 查看完整路線詳情。

## 未來增強功能

- [ ] 擴展路線資料庫以包含所有 300+ 條香港路線
- [ ] 真實 AR 相機整合（使用 ARKit）
- [ ] 社交功能（分享行程、照片）
- [ ] 高級路線規劃（路徑點）
- [ ] Apple Health 整合
- [ ] 路線警示推送通知
- [ ] 社區評價和評分
- [ ] 路線照片庫
- [ ] 導出行程數據
- [ ] 連接官方路線資料庫 API

## 貢獻

歡迎貢獻！請隨時提交 Pull Request。

## 授權

本專案為私有和專有。

## 作者

為香港行山愛好者用心製作 ❤️

---

**注意**：本應用程式專為香港行山路線設計，使用本地 API 和服務。某些功能可能需要位置權限和互聯網連接。

## 相關文檔

- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - 文件結構說明
- [FEATURE_STATUS.md](FEATURE_STATUS.md) - 功能實現狀態和 API 連接檢查
- [TRAILS_LIST.md](TRAILS_LIST.md) - 完整路線列表

---

**語言**：[English](README.md) | [繁體中文](README_zh_TW.md)

