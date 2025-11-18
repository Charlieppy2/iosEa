# HikingHK 🏔️

A comprehensive iOS hiking companion app for Hong Kong trails, built with SwiftUI and SwiftData.

## Overview

HikingHK is a feature-rich mobile application designed to help hikers discover, plan, and track their hiking adventures across Hong Kong's beautiful trails. The app provides real-time weather information, trail details, offline maps, safety checklists, and AR landmark identification.

## Features

### 🏠 Home
- **Weather Dashboard**: Real-time weather conditions from Hong Kong Observatory
- **Featured Trails**: Discover recommended hiking routes
- **Quick Actions**: 
  - Trail Alerts - Real-time weather and route warnings
  - Offline Maps - Download maps for offline use
  - AR Identify - Identify nearby peaks using AR technology
- **Next Plans**: View and manage your scheduled hikes
- **Safety Checklist**: Pre-hike safety preparation

### 🗺️ Trails
- **Trail Browser**: Browse 17+ hiking trails across Hong Kong
- **Search & Filter**: Find trails by name, district, or difficulty
- **Trail Database**: Includes major trails from:
  - MacLehose Trail (Sections 1, 2, 3, 4, 5, 8)
  - Wilson Trail (Sections 1, 2)
  - Lantau Trail (Sections 2, 3)
  - Hong Kong Trail (Sections 1, 4)
  - Famous peaks: Lion Rock, Sunset Peak, Sharp Peak, Tai Mo Shan
  - Popular routes: Dragon's Back, Peak Circle Walk, Tai Tam Reservoir
- **Trail Details**: 
  - Interactive maps with route visualization
  - Checkpoints and route information
  - Facilities and transportation tips
  - Highlights and descriptions

### 📅 Planner
- **Hike Planning**: Schedule your hiking trips
- **Trail Selection**: Choose from available trails
- **Notes**: Add meeting points, gear reminders, and other notes
- **Date Management**: Set and update hike dates

### 👤 Profile
- **Account Management**: Sign in/out with secure authentication
- **Statistics Dashboard**:
  - Planned hikes count
  - Favorite trails
  - Total distance logged
- **Goals Tracking**:
  - Complete 4 Ridge Lines (Challenging trails)
  - Log 50 km this month
  - Progress visualization with progress bars
- **Service Status**: Monitor connection status for weather API, GPS, and offline maps
- **API Connection Checker**: Real-time API connection status monitoring

## Technical Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent data storage
- **CoreLocation**: GPS and location services
- **Combine**: Reactive programming

### Architecture
- **MVVM Pattern**: Model-View-ViewModel architecture
- **Protocol-Oriented**: Service protocols for testability
- **Async/Await**: Modern concurrency for network and data operations

### Data Models
- `UserCredential`: User authentication data
- `SavedHikeRecord`: Planned and completed hikes
- `FavoriteTrailRecord`: User's favorite trails
- `SafetyChecklistItem`: Safety checklist items
- `OfflineMapRegion`: Offline map download status

## Installation

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Setup
1. Clone the repository:
```bash
git clone https://github.com/Charlieppy2/iosEa.git
cd iosEa/hikingHK
```

2. Open the project in Xcode:
```bash
open hikingHK.xcodeproj
```

3. Build and run the project (⌘R)

### Configuration
- **Mapbox API**: Set `MAPBOX_ACCESS_TOKEN` environment variable for route services (optional)
- **Location Services**: The app will request location permissions when needed

## Project Structure

```
hikingHK/
├── hikingHK/
│   ├── Core/
│   │   ├── hikingHKApp.swift          # App entry point
│   │   ├── RootView.swift             # Root navigation
│   │   └── ContentView.swift          # Main tab view
│   │
│   ├── Authentication/
│   │   ├── AuthView.swift             # Login/Register UI
│   │   ├── SessionManager.swift       # Session management
│   │   ├── AccountStore.swift         # Account data store
│   │   ├── UserAccount.swift          # User model
│   │   └── UserCredential.swift       # Credential model (SwiftData)
│   │
│   ├── Views/
│   │   ├── HomeView.swift             # Home screen
│   │   ├── TrailListView.swift        # Trail browser
│   │   ├── TrailDetailView.swift      # Trail details
│   │   ├── TrailMapView.swift         # Interactive map
│   │   ├── PlannerView.swift          # Hike planner
│   │   └── ProfileView.swift          # User profile
│   │
│   ├── Models/
│   │   ├── Trail.swift                # Trail data model
│   │   ├── ExperienceModels.swift     # Weather, SavedHike models
│   │   ├── Goal.swift                 # Goals tracking
│   │   ├── Landmark.swift             # Landmark data
│   │   └── TrailAlert.swift           # Alert model
│   │
│   ├── ViewModels/
│   │   ├── AppViewModel.swift         # Main app state
│   │   ├── SafetyChecklistViewModel.swift
│   │   ├── OfflineMapsViewModel.swift
│   │   ├── TrailAlertsViewModel.swift
│   │   ├── ServicesStatusViewModel.swift
│   │   └── ARLandmarkIdentifier.swift
│   │
│   ├── Services/
│   │   ├── WeatherService.swift       # Weather API integration
│   │   ├── LocationManager.swift      # Location services
│   │   ├── MapboxRouteService.swift   # Route calculation
│   │   ├── TrailAlertsService.swift   # Alert fetching
│   │   └── OfflineMapsDownloadService.swift
│   │
│   └── Data/
│       ├── TrailDataStore.swift       # Trail persistence
│       ├── SafetyChecklistStore.swift
│       ├── OfflineMapsStore.swift
│       ├── SavedHikeRecord.swift      # SwiftData models
│       ├── FavoriteTrailRecord.swift
│       ├── SafetyChecklistItem.swift
│       └── OfflineMapRegion.swift
│
└── hikingHKTests/                     # Unit tests
```

## Key Features in Detail

### 🔐 Authentication
- Secure user registration and login
- SwiftData-based credential storage
- Automatic session restoration
- User profile management

### 📊 Data Persistence
All user data is persisted using SwiftData:
- User credentials
- Saved hikes and completion status
- Favorite trails
- Safety checklist progress
- Offline map downloads

### 🌤️ Weather Integration
- Real-time weather data from Hong Kong Observatory API
- Temperature, humidity, UV index
- Weather warnings and suggestions
- Automatic refresh capability

### 🗺️ Trail Management
- **17+ hiking trails** covering major Hong Kong routes
- Difficulty levels (Easy, Moderate, Challenging)
- Interactive maps with route visualization
- Checkpoints and elevation profiles
- Transportation and facility information
- Coverage of four major long-distance trails (MacLehose, Wilson, Lantau, Hong Kong Trail)

### 📱 Offline Maps
- Download maps for offline use
- Multiple regions available
- Download progress tracking
- Storage management

### ⚠️ Trail Alerts
- Real-time weather warnings
- Route maintenance notifications
- Alert categorization and severity levels
- Automatic updates from HKO API

### 🎯 Goals & Statistics
- Track hiking goals
- Monthly distance logging
- Ridge line completion tracking
- Visual progress indicators

### 🧭 AR Landmark Identification
- Identify nearby peaks using GPS
- Distance and bearing calculations
- Landmark information display
- Real-time scanning

### 🎨 UI/UX Design
- **Hiking Theme**: Natural color palette (forest green, earth brown, sky blue)
- **Pattern Backgrounds**: Subtle mountain, tree, cloud, and path patterns
- **Card-based Design**: Modern card layouts with gradients and shadows
- **Responsive Layout**: Adapts to different screen sizes

## Development

### Adding New Features
1. Create models in appropriate directory
2. Implement ViewModels following MVVM pattern
3. Create SwiftUI views with proper state management
4. Add SwiftData models if persistence is needed
5. Update `modelContainer` in `hikingHKApp.swift`

### Testing
Run tests using:
```bash
xcodebuild test -scheme hikingHK -destination 'platform=iOS Simulator,name=iPhone 15'
```

## API Integration

### Weather API ✅
- **Endpoint**: `https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en`
- **Status**: Connected
- **Data Type**: Real-time weather readings
- **Features**: Temperature, humidity, UV index, weather warnings
- **Update Frequency**: Manual refresh or on app launch
- **Connection Check**: Available in Profile → API Status

### Mapbox API ⚠️
- **Endpoint**: `https://api.mapbox.com/directions/v5/mapbox/walking/`
- **Status**: Optional configuration
- **Requirement**: `MAPBOX_ACCESS_TOKEN` environment variable
- **Features**: Route calculation and navigation
- **Connection Check**: Available in Profile → Data & services

### API Connection Monitoring
- Real-time API status checking
- Connection status display in Profile page
- Manual refresh capability
- Last check time tracking

## Data Privacy

- All user data is stored locally using SwiftData
- No data is transmitted to external servers except:
  - Weather API (public data)
  - Mapbox API (route calculation, optional)
- User credentials are encrypted and stored securely

## Trail Database

The app currently includes **17 hiking trails** covering:
- **MacLehose Trail**: Sections 1, 2, 3, 4, 5, 8
- **Wilson Trail**: Sections 1, 2
- **Lantau Trail**: Sections 2, 3
- **Hong Kong Trail**: Sections 1, 4
- **Famous Peaks**: Lion Rock, Sunset Peak, Sharp Peak, Tai Mo Shan
- **Popular Routes**: Dragon's Back, Peak Circle Walk, Tai Tam Reservoir

> **Note**: Hong Kong has over 300 hiking trails. The app currently includes major routes. More trails can be added in future updates.

See [TRAILS_LIST.md](TRAILS_LIST.md) for complete trail details.

## Future Enhancements

- [ ] Expand trail database to include all 300+ Hong Kong trails
- [ ] Real AR camera integration with ARKit
- [ ] Social features (share hikes, photos)
- [ ] Advanced route planning with waypoints
- [ ] Integration with Apple Health
- [ ] Push notifications for trail alerts
- [ ] Community reviews and ratings
- [ ] Photo gallery for trails
- [ ] Export hike data
- [ ] Connect to official trail database API

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is private and proprietary.

## Author

Created with ❤️ for Hong Kong hikers

---

**Note**: This app is designed specifically for Hong Kong's hiking trails and uses local APIs and services. Some features may require location permissions and internet connectivity.

## Related Documentation

- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - Project file structure
- [FEATURE_STATUS.md](FEATURE_STATUS.md) - Feature implementation status and API connection checks
- [TRAILS_LIST.md](TRAILS_LIST.md) - Complete trail list

---

**Language**: [English](README.md) | [繁體中文](README_zh_TW.md)

