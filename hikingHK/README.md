# HikingHK 🏔️

A comprehensive iOS hiking companion app for Hong Kong trails, built with SwiftUI and SwiftData.

## Overview

HikingHK is a feature-rich mobile application designed to help hikers discover, plan, and track their hiking adventures across Hong Kong's beautiful trails. The app provides real-time weather information, trail details, offline maps, safety checklists, location sharing, hike tracking, and intelligent trail recommendations.

## Features

### 🏠 Home
- **Weather Dashboard**: Real-time weather conditions from Hong Kong Observatory
- **Featured Trails**: Discover recommended hiking routes
- **Quick Actions** (4 buttons per row):
  - 🚨 Trail Alerts - Real-time weather and route warnings
  - 🗺️ Offline Maps - Download maps for offline use
  - 📍 Location Sharing - Share your location with emergency contacts
  - 🎯 Start Tracking - Begin recording your hike
  - 📋 Hike Records - View your hiking history
  - ✨ Smart Recommendations - AI-powered trail suggestions
  - 📖 Journal - Document your hiking adventures
  - ☁️ Weather Forecast - 7-day weather forecast
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
  - Offline map support with network detection
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
- **Achievements & Badges**: Track your hiking achievements
- **Service Status**: Monitor connection status for weather API, GPS, and offline maps
- **API Connection Checker**: Real-time API connection status monitoring
- **Language Selection**: Switch between English and Traditional Chinese

### 📖 Journal
- **Hike Journal**: Document your hiking adventures
- **Photo Support**: Add photos to journal entries
- **Trail Association**: Link journal entries to specific trails
- **Weather Data**: Automatically record weather conditions
- **Timeline View**: Browse entries by month
- **Edit & Delete**: Manage your journal entries

### 🎯 Smart Recommendations
- **AI-Powered Suggestions**: Get personalized trail recommendations
- **Time-Based**: Select available time (30-minute intervals from 1-8 hours)
- **Preference-Based**: Recommendations based on:
  - Fitness level
  - Preferred scenery (sea view, mountain view, forest, etc.)
  - Difficulty preference
  - Distance preference
- **Weather Integration**: Considers current weather conditions
- **History Learning**: Learns from your hiking history

### 📍 Location Sharing
- **Real-Time Sharing**: Share your location with emergency contacts
- **SOS Feature**: One-tap emergency SOS with location
- **Anomaly Detection**: Automatic detection of unusual movement patterns
- **Emergency Contacts**: Manage your emergency contact list
- **Session Management**: Start and stop sharing sessions

### 🎯 Hike Tracking
- **GPS Tracking**: Record your hiking route in real-time
- **Statistics**: Track distance, time, speed, and altitude
- **Trail Selection**: Associate tracking with specific trails
- **Live Map**: View your current location and route
- **Track Points**: Detailed GPS point recording

### 📋 Hike Records
- **History View**: Browse all your recorded hikes
- **Detailed Statistics**: View comprehensive hike data
- **Route Visualization**: See your recorded routes on maps
- **Elevation Profile**: View altitude changes during hikes
- **3D Playback**: Replay your hiking route in 3D

### ☁️ Weather Forecast
- **7-Day Forecast**: Extended weather predictions
- **Best Hiking Times**: Recommendations for optimal hiking periods
- **Comfort Index**: Weather comfort level calculations
- **Condition Details**: Temperature, humidity, and conditions

### 🎒 Smart Gear Checklist
- **Intelligent Suggestions**: Gear recommendations based on:
  - Trail difficulty
  - Weather conditions
  - Season
- **Category Organization**: Essential, clothing, navigation, safety, food, tools
- **Progress Tracking**: Visual progress indicators

### 🏆 Achievements
- **Badge System**: Unlock achievements as you hike
- **Categories**:
  - Distance achievements (10km, 50km, 100km, 500km)
  - Peak conquests (Lion Rock, Tai Mo Shan, Sunset Peak, Sharp Peak)
  - Streak achievements (1 week, 2 weeks, 1 month)
  - Exploration achievements (3, 5, 10 districts)
- **Progress Tracking**: Visual progress indicators

## Technical Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent data storage
- **CoreLocation**: GPS and location services
- **Combine**: Reactive programming
- **MapKit**: Map display and offline map support
- **Network Framework**: Network status monitoring

### Architecture
- **MVVM Pattern**: Model-View-ViewModel architecture
- **Protocol-Oriented**: Service protocols for testability
- **Async/Await**: Modern concurrency for network and data operations
- **MainActor Isolation**: Proper thread safety for UI updates

### Data Models
- `UserCredential`: User authentication data
- `SavedHikeRecord`: Planned and completed hikes
- `FavoriteTrailRecord`: User's favorite trails
- `SafetyChecklistItem`: Safety checklist items
- `OfflineMapRegion`: Offline map download status
- `HikeRecord`: Recorded hiking sessions
- `HikeTrackPoint`: GPS tracking points
- `HikeJournal`: Journal entries
- `JournalPhoto`: Journal entry photos
- `EmergencyContact`: Emergency contacts
- `LocationShareSession`: Location sharing sessions
- `UserPreference`: User preferences for recommendations
- `Achievement`: Achievement and badge data

## Installation

### Requirements
- iOS 17.0+
- Xcode 15.0+ (tested with Xcode 26.1)
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

## API Integration

### Weather API ✅
- **Endpoint**: `https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang={lang}`
- **Status**: Connected
- **Languages**: English (`en`) and Traditional Chinese (`tc`)
- **Data Type**: Real-time weather readings
- **Features**: Temperature, humidity, UV index, weather warnings
- **Update Frequency**: Manual refresh or on app launch
- **Connection Check**: Available in Profile → API Status
- **Error Handling**: Comprehensive error handling with detailed logging

### Weather Warning API ✅
- **Endpoint**: `https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang={lang}`
- **Status**: Connected
- **Languages**: English (`en`) and Traditional Chinese (`tc`)
- **Features**: Active weather warnings and alerts

### CSDI Geoportal API ✅
- **Endpoints**: 
  - `https://portal.csdi.gov.hk/geoportal/?datasetId=afcd_rcd_1665568199103_4360&lang={lang}`
  - `https://portal.csdi.gov.hk/geoportal/?datasetId=afcd_rcd_1635136039113_86105&lang={lang}`
  - `https://portal.csdi.gov.hk/geoportal/?datasetId=cas_rcd_1640314527589_15538&lang={lang}`
- **Status**: Connected
- **Languages**: English (`en`) and Traditional Chinese (`zh-hk`)
- **Features**: Trail information and government data

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
- Detailed error reporting

## Localization

The app fully supports two languages:
- **English** (`en`)
- **Traditional Chinese** (`zh-Hant` / `tc`)

All UI elements, trail names, weather conditions, and error messages are localized. Users can switch languages in Profile → Language.

## Data Privacy

- All user data is stored locally using SwiftData
- No data is transmitted to external servers except:
  - Weather API (public data)
  - Weather Warning API (public data)
  - CSDI Geoportal API (public data)
  - Mapbox API (route calculation, optional)
- User credentials are encrypted and stored securely
- Location sharing is user-initiated and can be stopped at any time

## Trail Database

The app currently includes **17 hiking trails** covering:
- **MacLehose Trail**: Sections 1, 2, 3, 4, 5, 8
- **Wilson Trail**: Sections 1, 2
- **Lantau Trail**: Sections 2, 3
- **Hong Kong Trail**: Sections 1, 4
- **Famous Peaks**: Lion Rock, Sunset Peak, Sharp Peak, Tai Mo Shan
- **Popular Routes**: Dragon's Back, Peak Circle Walk, Tai Tam Reservoir

> **Note**: Hong Kong has over 300 hiking trails. The app currently includes major routes. More trails can be added in future updates.

## Offline Maps

- **Download Regions**: 
  - Hong Kong Island (香港島)
  - Kowloon Ridge (九龍山脊)
  - Sai Kung East (西貢東)
  - Lantau North (大嶼山北)
- **Features**:
  - Download progress tracking
  - Storage management
  - Automatic offline mode detection
  - Network status monitoring
  - Map tile caching

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
