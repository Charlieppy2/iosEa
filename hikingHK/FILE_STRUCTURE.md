# 文件结构说明

本项目按照页面和功能模块进行了文件分类组织，方便查找和维护。

## 📁 文件夹结构

```
hikingHK/
├── Core/                    # 核心文件
│   ├── hikingHKApp.swift   # 应用入口
│   ├── RootView.swift      # 根视图
│   ├── ContentView.swift   # 主内容视图（TabView）
│   ├── AppViewModel.swift  # 主应用视图模型
│   └── HikingTheme.swift   # 远足主题样式和颜色
│
├── Authentication/          # 认证模块
│   ├── AuthView.swift      # 登录/注册界面
│   ├── SessionManager.swift # 会话管理
│   ├── AccountStore.swift  # 账户数据存储
│   ├── UserAccount.swift   # 用户账户模型
│   └── UserCredential.swift # 用户凭证模型（SwiftData）
│
├── Home/                    # 首页模块
│   └── HomeView.swift      # 首页视图（包含天气、特色路线、快速操作等）
│
├── Trails/                  # 路线模块
│   ├── TrailListView.swift # 路线列表视图
│   ├── TrailDetailView.swift # 路线详情视图女
│   ├── TrailMapView.swift  # 路线地图视图
│   ├── Trail.swift         # 路线数据模型
│   ├── TrailDataStore.swift # 路线数据存储
│   └── FavoriteTrailRecord.swift # 收藏路线记录（SwiftData）
│
├── Planner/                 # 计划模块
│   ├── PlannerView.swift   # 计划视图
│   ├── SavedHikeRecord.swift # 保存的行程记录（SwiftData）
│   └── ExperienceModels.swift # 体验相关模型（WeatherSnapshot, SavedHike等）
│
├── Profile/                 # 个人资料模块
│   ├── ProfileView.swift   # 个人资料视图
│   └── Goal.swift          # 目标追踪模型
│
├── Services/                # 服务层
│   ├── WeatherService.swift # 天气服务
│   ├── LocationManager.swift # 位置管理服务
│   ├── MapboxRouteService.swift # Mapbox 路线服务
│   ├── TrailAlertsService.swift # 路线警示服务
│   └── OfflineMapsDownloadService.swift # 离线地图下载服务
│
├── ViewModels/              # 视图模型
│   ├── TrailAlertsViewModel.swift # 路线警示视图模型
│   ├── OfflineMapsViewModel.swift # 离线地图视图模型
│   ├── SafetyChecklistViewModel.swift # 安全检查清单视图模型
│   ├── ServicesStatusViewModel.swift # 服务状态视图模型
│   └── ARLandmarkIdentifier.swift # AR 地标识别器
│
├── DataModels/              # 数据模型
│   ├── TrailAlert.swift    # 路线警示模型
│   ├── Landmark.swift      # 地标模型
│   ├── OfflineMapRegion.swift # 离线地图区域模型（SwiftData）
│   └── SafetyChecklistItem.swift # 安全检查清单项模型（SwiftData）
│
├── Stores/                  # 数据存储层
│   ├── OfflineMapsStore.swift # 离线地图存储
│   └── SafetyChecklistStore.swift # 安全检查清单存储
│
└── Assets.xcassets/         # 资源文件
    ├── AppIcon.appiconset/
    └── AccentColor.colorset/
```

## 📋 模块说明

### Core（核心）
应用的基础架构文件，包括应用入口、根视图、主视图和全局视图模型。

### Authentication（认证）
处理用户登录、注册、会话管理和账户数据持久化。

### Home（首页）
应用的主页面，展示天气信息、特色路线、快速操作按钮和计划列表。

### Trails（路线）
路线相关的所有功能，包括路线浏览、详情查看、地图显示和数据管理。

### Planner（计划）
用户计划和管理远足行程的功能模块。

### Profile（个人资料）
用户个人信息、统计数据、目标追踪和服务状态显示。

### Services（服务层）
各种外部服务集成，包括天气API、位置服务、地图服务等。

### ViewModels（视图模型）
各个功能模块的视图模型，负责业务逻辑和状态管理。

### DataModels（数据模型）
应用使用的各种数据模型定义。

### Stores（存储层）
SwiftData 数据存储管理，负责数据的持久化操作。

## 🔍 查找文件提示

- **视图文件**：在对应的页面文件夹中（Home, Trails, Planner, Profile）
- **数据模型**：在 DataModels 文件夹
- **业务逻辑**：在 ViewModels 文件夹
- **服务集成**：在 Services 文件夹
- **数据持久化**：在 Stores 文件夹
- **认证相关**：在 Authentication 文件夹

## 📝 注意事项

- 所有文件已按功能分类，Xcode 会自动识别新的文件结构
- 导入语句无需修改，Swift 会自动查找文件
- 如果添加新功能，请将文件放在对应的文件夹中

