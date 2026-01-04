# HikingHK 🏔️

A comprehensive iOS hiking companion app for Hong Kong trails, built with SwiftUI and SwiftData.

## 📱 Overview

HikingHK is a feature-rich mobile application designed to enhance the hiking experience in Hong Kong. The app provides trail information, real-time weather updates, GPS tracking, journaling capabilities, and safety features to help hikers explore Hong Kong's beautiful trails safely and efficiently.

## ✨ Features

### 🗺️ Trail Discovery
- **Comprehensive Trail Database**: Browse hundreds of hiking trails across Hong Kong
- **Detailed Trail Information**: 
  - Difficulty levels, distance, elevation gain
  - Estimated duration and route highlights
  - Transportation information (MTR, bus routes)
  - Facilities and supply points
  - Exit routes and safety notes
- **Interactive Maps**: View trail routes with checkpoints and landmarks
- **Trail Filtering**: Filter by district, difficulty, and preferences
- **Favorites**: Save your favorite trails for quick access

### 🌤️ Weather Integration
- **Real-time Weather**: Get current weather conditions for multiple locations
- **Weather Warnings**: Receive alerts for severe weather conditions
- **Weather Forecast**: View detailed weather forecasts for your planned hikes
- **Location-based Weather**: Automatic weather updates based on your location

### 📍 GPS Tracking
- **Real-time Tracking**: Record your hike with GPS tracking
- **Route Recording**: Capture your exact path with detailed track points
- **Statistics**: Track distance, duration, speed, elevation gain/loss
- **Route Playback**: Review your recorded routes on the map
- **Offline Support**: Continue tracking even without network connection

### 📝 Journal & Records
- **Hiking Journal**: Create detailed journal entries for your hikes
- **Photo Support**: Attach photos to your journal entries
- **Rich Metadata**: Link journals with trails, weather, and GPS records
- **Sharing**: Share your hiking experiences with others
- **History**: View all your past hiking records and journals

### 📅 Planner
- **Hike Planning**: Plan your future hikes with date and notes
- **Schedule Management**: Track planned and completed hikes
- **Trail Recommendations**: Get personalized trail recommendations based on preferences

### 🏆 Achievements
- **Badge System**: Unlock achievements for various hiking milestones
- **Progress Tracking**: Monitor your progress toward different goals
- **Categories**: 
  - Distance badges (10km, 50km, 100km, 500km)
  - Peak conquests (Lion Rock, Tai Mo Shan, Sunset Peak, etc.)
  - Streak badges (weekly, monthly)
  - Exploration badges (districts explored)

### 🚨 Safety Features
- **Safety Checklist**: Customizable safety checklist before hikes
- **Emergency Contacts**: Manage emergency contacts for SOS features
- **Location Sharing**: Share your real-time location with trusted contacts
- **Trail Alerts**: Receive alerts about trail conditions and closures
- **Smart Gear Recommendations**: Get personalized gear suggestions based on trail and weather

### 🚇 Transportation
- **MTR Integration**: Real-time MTR train schedules
- **Bus Routes**: KMB bus route information
- **Station Coordinates**: Find transportation stations near trail heads
- **Route Planning**: Get directions to trail starting points

### 🗺️ Offline Maps
- **Download Maps**: Download offline maps for 12 major hiking regions
- **Progress Tracking**: Monitor download progress and status
- **Storage Management**: View downloaded map sizes and manage storage

### 👤 User Profile
- **Account Management**: Secure user authentication
- **Preferences**: Set hiking preferences for personalized recommendations
- **Statistics**: View your hiking statistics and achievements
- **Language Support**: English and Traditional Chinese

## 🏗️ Architecture

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent data storage
- **CoreLocation**: GPS tracking and location services
- **MapKit**: Map display and route visualization
- **Combine**: Reactive programming for data flow

### Data Storage
- **SwiftData Models**: 14 main data models for structured data
  - User credentials, hike records, favorites, achievements, etc.
- **JSON File Storage**: Complex data structures using BaseFileStore architecture
  - Journals, emergency contacts, hike records with GPS points
- **User Isolation**: All data is isolated per user account

### Key Components
- **ViewModels**: MVVM architecture for business logic
- **Services**: Modular services for API integration and data processing
- **Stores**: Data persistence layer with SwiftData and file storage
- **Managers**: Core managers for language, session, and location

## 📁 Project Structure

```
hikingHK/
├── Authentication/          # User authentication and account management
├── Core/                   # App entry point and core components
├── DataModels/             # SwiftData models and data structures
├── Home/                   # Home screen and main landing view
├── Journal/                # Journal creation and management
├── Planner/                # Hike planning features
├── Profile/                # User profile and achievements
├── Services/               # API services and business logic
├── Stores/                 # Data persistence layer
├── Trails/                 # Trail browsing and details
└── ViewModels/             # View models for MVVM architecture
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/hikingHK.git
cd hikingHK
```

2. Open the project in Xcode:
```bash
open hikingHK.xcodeproj
```

3. Build and run the project (⌘R)

### Configuration
- The app uses local data storage, no additional API keys required for basic functionality
- Weather data is fetched from Hong Kong Observatory API
- MTR and bus data are fetched from respective public APIs

## 🔧 Development

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain MVVM architecture pattern
- All comments in English

### Data Models
- All SwiftData models include `accountId` for user isolation
- Use UUID for primary keys
- Implement proper relationships between models

### Testing
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- Test data isolation and user switching

## 📱 Screenshots

*Add screenshots of key features here*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **HPY**: [Your responsibilities]
- **LXJ**: [Your responsibilities]

## 🔮 Future Enhancements

- Social features and community sharing
- Advanced route planning with waypoints
- Integration with fitness tracking apps
- Augmented reality trail markers
- Offline route navigation
- Weather-based trail recommendations

## 📞 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Made with ❤️ for Hong Kong hikers**

