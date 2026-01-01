# HikingHK Report 更新清单

## 对比 Word 文档和现有报告，以下内容需要添加到 Word 文档中：

### 1. Section 3 - App Features 需要添加的内容：

#### 3.1 Sensors and Hardware 需要补充：
- **异常检测算法**：自动检测位置异常（偏离路线、长时间静止）
- **智能天气位置选择**：根据用户GPS位置自动选择最近的天气监测站

#### 3.2 Web Services / API Integration 需要补充：
- **并发处理**：使用 `withTaskGroup` 实现高性能并发 API 请求（MTR/巴士）
- **智能天气预警系统**：WeatherAlertManager 统一管理天气监控、通知调度
- **Mapbox Directions API**：路线规划
- **API连接状态监控**：实时监控各API的健康状态

#### 需要新增的核心功能亮点：

1. **智能推荐系统** ⭐⭐⭐⭐⭐
   - 多因素评分算法（6个维度）
   - 机器学习式逻辑，根据用户历史行为动态调整
   - 6个独立的评分函数

2. **智能天气预警系统** ⭐⭐⭐⭐⭐
   - 自动提醒：恶劣天气前自动推送通知
   - 出发前检查：计划行山前检查天气
   - 实时天气更新：行山过程中每5分钟自动检查

3. **实时交通 API 并发处理** ⭐⭐⭐⭐⭐
   - 使用 `withTaskGroup` 实现高性能并发请求
   - 支持20个并发连接
   - 增量UI更新策略

4. **GPS 追踪与异常检测** ⭐⭐⭐⭐
   - 异常检测算法
   - SOS紧急求救功能
   - 位置分享会话管理

5. **地图语言本地化** ⭐⭐⭐
   - 根据应用语言自动切换地图标签语言

6. **智能装备推荐系统** ⭐⭐⭐
   - 根据路线难度和天气条件生成装备建议

### 2. Section 4 - Data Persistence 需要补充：

#### 4.1 Database Structure 需要添加的数据模型：
- UserPreference (用户偏好)
- RecommendationRecord (推荐记录)
- Achievement (成就)
- HikeJournal (行山日记)
- JournalPhoto (日记照片)
- GearItem (装备清单)

#### 4.2 File System Usage 需要补充：
- **JSON文件存储**：使用 BaseFileStore 统一架构存储部分数据（避免SwiftData同步问题）
- **数据恢复机制**：自动修复损坏文件
- **多用户数据隔离**：JSON文件存储支持多用户数据合并保存

#### 4.3 Web Server Data Formats 需要补充：
- Bus API Response 格式
- Weather Forecast API Response 格式
- Mapbox Directions API Response 格式

### 3. Section 5 - Simple User Guide 需要补充：

5.8 **路线排序**
5.9 **离线地图管理**
5.10 **天气预警系统**
5.11 **紧急联系人管理**

### 4. Section 6 - Division of Labour 需要补充：

需要添加详细的服务层分工表，包括：
- TrailRecommendationService
- WeatherAlertManager
- HikeTrackingService
- SmartGearService
- APIConnectionChecker
- 各种 FileStore 模块

需要添加页面分工的详细表格，列出所有32个页面及其工作内容。

### 5. Section 7 - Conclusion and Further Development 需要补充：

#### 7.2 Further Development Possibilities 需要标记已实现的功能：
- ✅ 完整离线地图支持（已实现，支持12个区域）
- ✅ SOS紧急求救功能：直接拨打999（已实现）
- ✅ 自动位置分享给紧急联系人（已实现）
- ✅ 路线危险区域提醒（已实现）
- ✅ 智能天气预警系统：自动推送天气警告通知（已实现）

### 6. Section 8 - References 需要补充：

需要添加以下参考文献：
- Hong Kong Observatory Weather API Documentation
- MTR Corporation Limited Open Data API
- KMB & Long Win Bus ETA API
- Mapbox Directions API
- CSDI Geoportal
- Oasis Trek Hong Kong Hiking Trails Information

### 7. 其他需要添加的内容：

- **封面页**：需要填写学生信息（Hui Pui Yi - 240017387, Li Xiaojing - 240128886）
- **课程信息**：ITP4206 - Proprietary Mobile Application Development
- **Table of Contents**：需要完整的目录结构
- **贡献度分配**：需要在分工表中明确标注

---

## 建议的更新步骤：

1. 将 Section 3 的核心功能亮点部分扩展，添加上述19个核心功能
2. 更新 Section 4.1，添加所有14个数据模型
3. 扩展 Section 5，添加缺失的用户指南步骤
4. 详细化 Section 6，添加服务层分工和页面分工的详细表格
5. 更新 Section 7.2，标记已实现的功能
6. 补充 Section 8，添加所有API文档的参考文献
7. 填写封面页的学生信息和课程信息

