# 🐱 MamaMeow - Baby Care Companion

A comprehensive Flutter application designed to help parents track and manage their baby's daily activities, health, and development milestones.

## 📱 Features

### 🔐 Authentication & User Management
- **User Registration & Login**: Secure Firebase authentication
- **Baby Profile Setup**: Create and manage baby information
- **User Profile Management**: Personalized user experience

### 👶 Baby Activity Tracking
- **Diaper Changes**: Track diaper changes with timestamps
- **Feeding Sessions**: Monitor nursing/bottle feeding with detailed metrics
  - Side tracking (left/right for nursing)
  - Duration and amount tracking
  - Milk type selection for bottle feeding
- **Sleep Monitoring**: Comprehensive sleep tracking
  - Start/end times with detailed sleep patterns
  - Sleep quality indicators
  - Sleep environment tracking
- **Medicine Administration**: Track medication schedules and dosages
- **Solid Food Introduction**: Monitor baby's solid food journey
- **Growth Tracking**: Record and visualize baby's development
- **Journal Notes**: Keep detailed notes about baby's daily activities

### 🎧 Educational Content
- **Podcast Player**: Built-in audio player with advanced features
  - Playback speed control (1x, 1.25x, 1.5x, 2x)
  - 10-second skip forward/backward
  - Playlist navigation between episodes
  - Category-based filtering
  - Search functionality
- **Expert Parenting Guidance**: Access to professional advice in audio format

### 🍽️ Meal Planning
- **Meal Plan Management**: Organize baby's feeding schedule
- **Food Asset Library**: Visual food selection with SVG icons
- **Nutritional Tracking**: Monitor baby's dietary intake

### 📊 Analytics & Reports
- **Activity Reports**: Visual charts and analytics for all tracked activities
- **Growth Charts**: Monitor baby's development over time
- **Export Capabilities**: Share reports with healthcare providers

## 🛠️ Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **GetX**: State management and navigation
- **Material Design**: Modern UI/UX components

### Backend & Services
- **Firebase Authentication**: Secure user management
- **Firebase Realtime Database**: Real-time data synchronization
- **Firebase Storage**: Media file storage

### Key Dependencies
```yaml
# Core Framework
flutter: sdk
get: ^4.6.6                    # State management
get_storage: ^2.1.1            # Local storage

# UI & Media
cached_network_image: ^3.4.1   # Image caching
flutter_svg: ^2.2.1            # SVG support
syncfusion_flutter_charts: ^31.1.17  # Charts & analytics

# Audio & Media
just_audio: ^0.10.5            # Audio playback
image_picker: ^1.2.0           # Image selection
file_picker: ^8.0.6            # File selection
record: ^6.1.1                 # Audio recording

# Firebase
firebase_core: ^4.0.0
firebase_auth: ^6.0.2
firebase_database: ^12.0.0
firebase_storage: ^13.0.1

# Utilities
intl: ^0.20.2                  # Internationalization
path_provider: ^2.1.5         # File system paths
http: ^1.5.0                   # HTTP requests
```

## 🏗️ Project Structure

```
lib/
├── constants/           # App-wide constants
│   ├── app_colors.dart
│   ├── app_localization.dart
│   ├── app_pages.dart
│   └── app_routes.dart
├── models/             # Data models
│   ├── activities/     # Baby activity models
│   │   ├── diaper_model.dart
│   │   ├── nursing_model.dart
│   │   ├── sleep_model.dart
│   │   ├── medicine_model.dart
│   │   └── journal_model.dart
│   ├── meow_user_model.dart
│   ├── podcast_model.dart
│   └── solid_food.dart
├── screens/            # UI screens
│   ├── auth/          # Authentication screens
│   ├── navigationbar/ # Main app navigation
│   │   ├── home/      # Dashboard
│   │   ├── learn/     # Podcast & education
│   │   ├── meal-plan/ # Meal planning
│   │   ├── my-baby/   # Activity tracking
│   │   └── profile/   # User profile
│   └── get-started/   # Onboarding
├── service/           # Business logic & API calls
│   ├── activities/    # Activity-specific services
│   ├── authentication_service.dart
│   ├── database_service.dart
│   ├── podcast_service.dart
│   └── app_init_service.dart
└── utils/             # Utility widgets & helpers
    └── custom_widgets/
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.9.0)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mama_meow.git
   cd mama_meow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Configure Firebase Authentication, Realtime Database, and Storage

4. **Environment Configuration**
   - Create a `.env` file in the root directory
   - Add your configuration variables

5. **Run the application**
   ```bash
   flutter run
   ```

## 🎯 Key Features Breakdown

### Baby Activity Tracking System
The app provides comprehensive tracking for all major baby activities:

- **Real-time Data Sync**: All activities sync instantly across devices
- **Detailed Metrics**: Track duration, amounts, times, and additional notes
- **Visual Reports**: Charts and graphs show patterns and trends
- **Export Functionality**: Share data with healthcare providers

### Advanced Podcast Player
- **Multi-speed Playback**: Adjust listening speed for convenience
- **Smart Navigation**: Skip between episodes seamlessly
- **Offline Support**: Download episodes for offline listening
- **Category Filtering**: Find content by topic (sleep, feeding, growth, etc.)

### Comprehensive Data Models
Each activity type has a dedicated data model ensuring:
- **Type Safety**: Strongly typed data structures
- **Validation**: Input validation and error handling
- **Serialization**: Easy JSON conversion for API communication
- **Extensibility**: Models designed for future feature additions

## 🔧 Development

### Code Architecture
- **MVVM Pattern**: Clear separation of concerns
- **GetX State Management**: Reactive programming approach
- **Service Layer**: Centralized business logic
- **Repository Pattern**: Data access abstraction

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Building for Production
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Create an issue in this repository
- Contact the development team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All the parents who provided feedback during development

---

**MamaMeow** - Making parenting a little easier, one feature at a time. 🐱👶