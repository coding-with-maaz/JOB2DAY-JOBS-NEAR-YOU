<div align="center">

# 🚀 JOB2DAY - Jobs Near You

<img width="200" height="200" alt="logo" src="https://github.com/user-attachments/assets/a71c1fc4-87c1-4e5e-9666-5acb3b0bbb4d" />

### Find Your Dream Job Today! 💼

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)]()

A modern, feature-rich Flutter application for job seekers to discover, search, and apply for jobs. Create professional resumes and find opportunities near you!

</div>

---

## 📱 Screenshots

<div align="center">

### App Banners
<img width="600" height="338" alt="JOB2DAY_BANNER" src="https://github.com/user-attachments/assets/8e6ce13d-3997-424a-830a-41b431c8432d" />
<img width="600" height="338" alt="DAY2JOB_Banner2" src="https://github.com/user-attachments/assets/d885ab55-34ed-4a38-abf5-f824c0e0eb3b" />

### App Screenshots
<table>
  <tr>
    <td><img width="300" height="533" alt="ScreenShot (1)" src="https://github.com/user-attachments/assets/1df3a5c6-a8d5-4471-a42d-d12b0e2a0e12" /></td>
    <td><img width="300" height="533" alt="ScreenShot (2)" src="https://github.com/user-attachments/assets/08b7789e-76b7-48e2-a9a12-4451a73e7d87" /></td>
    <td><img width="300" height="533" alt="ScreenShot (3)" src="https://github.com/user-attachments/assets/f2247f2a-ee5c-4b2b-92ca-c9d2b118d03b" /></td>
  </tr>
  <tr>
    <td><img width="300" height="533" alt="ScreenShot (4)" src="https://github.com/user-attachments/assets/c04af706-ef23-4208-a47b-82433a23d5e5" /></td>
    <td><img width="300" height="533" alt="ScreenShot (5)" src="https://github.com/user-attachments/assets/298de59a-4980-475f-9b89-bb3bfd4394b7" /></td>
  </tr>
</table>

</div>

---

## ✨ Features

### 🔍 Job Search & Discovery
- **Advanced Search**: Search jobs by keywords, location, job type, experience level, and salary range
- **Smart Filters**: Filter jobs by category, country, company, and more
- **Today's Jobs**: Browse the latest job postings added today
- **Featured Jobs**: Discover highlighted opportunities
- **Job Details**: Comprehensive job information with HTML descriptions
- **Share Jobs**: Share interesting opportunities with friends

### 📄 Resume Builder
- **Professional Templates**: Choose from Modern and Classic resume templates
- **Easy Form-Based Creation**: Fill out your information step-by-step
- **PDF Export**: Generate and download professional PDF resumes
- **Profile Photo**: Add your profile picture to your resume
- **Complete Sections**: Personal info, experience, education, skills, languages, and references

### 🔔 Notifications
- **Push Notifications**: Get notified about new job opportunities via Firebase Cloud Messaging
- **Deep Linking**: Tap notifications to navigate directly to job details
- **Topic Subscriptions**: Subscribe to job categories and countries
- **Local Notifications**: Receive notifications even when the app is closed

### 💰 Monetization
- **Google Mobile Ads Integration**: Comprehensive ad system with multiple ad types
- **Dynamic Ad Configuration**: Remote ad configuration from API
- **Smart Ad Placement**: Banner, Interstitial, Rewarded, Native, and App Open ads
- **User-Friendly**: Visit-based ad triggers with daily limits and cooldowns

### 🎨 User Experience
- **Beautiful UI**: Modern Material Design 3 with custom color scheme
- **Onboarding**: First-time user experience
- **Network Awareness**: Handles offline scenarios gracefully
- **Loading States**: Smooth loading indicators and shimmer effects
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **In-App Reviews**: Smart review prompts based on user engagement

---

## 🛠️ Technology Stack

### Core
- **Flutter**: ^3.8.1
- **Dart**: ^3.8.1
- **State Management**: Provider

### Networking & API
- **Dio**: ^5.9.0 - HTTP client
- **http**: ^1.5.0 - Additional HTTP utilities
- **connectivity_plus**: ^6.1.5 - Network connectivity checking

### Firebase
- **firebase_core**: ^2.24.2
- **firebase_messaging**: ^14.7.10 - Push notifications

### Ads & Monetization
- **google_mobile_ads**: ^6.0.0 - Google Mobile Ads SDK

### UI & Design
- **cached_network_image**: ^3.3.1 - Image caching
- **shimmer**: ^3.0.0 - Loading shimmer effects
- **photo_view**: ^0.15.0 - Image viewing
- **flutter_html**: ^3.0.0 - HTML rendering
- **flutter_svg**: ^2.0.7 - SVG support

### Utilities
- **shared_preferences**: ^2.2.2 - Local storage
- **url_launcher**: ^6.2.4 - Open URLs and links
- **timeago**: ^3.6.0 - Relative time formatting
- **intl**: ^0.20.2 - Internationalization
- **package_info_plus**: ^8.3.1 - App information

### Resume & PDF
- **pdf**: ^3.10.4 - PDF generation
- **printing**: ^5.11.0 - PDF printing
- **path_provider**: ^2.1.2 - File system paths
- **open_file**: ^3.3.2 - Open files
- **image_picker**: ^1.2.0 - Image selection

### Notifications
- **flutter_local_notifications**: ^17.2.2 - Local notifications

### Reviews
- **in_app_review**: ^2.0.11 - In-app review prompts

---

## 📦 Installation

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/coding-with-maaz/JOB2DAY-JOBS-NEAR-YOU.git
   cd JOB2DAY-JOBS-NEAR-YOU
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` file to `android/app/`
   - Add your `GoogleService-Info.plist` file to `ios/Runner/`
   - Follow [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

4. **Configure API**
   - Update `lib/config/api_config.dart` with your backend API URL
   - For development, the default is `https://10.0.2.2:3000/api`
   - For production, update to your production API URL

5. **Configure Google Ads**
   - Update `lib/widgets/google_ads/ad_config.dart` with your ad unit IDs
   - Set `isProduction` flag to `true` for production
   - Configure dynamic ad config API endpoint in `lib/widgets/google_ads/dynamic_ad_config.dart`

6. **Run the app**
   ```bash
   flutter run
   ```

---

## ⚙️ Configuration

### API Configuration
Edit `lib/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'YOUR_API_URL';
  static const int timeout = 30000;
}
```

### Ad Configuration
Edit `lib/widgets/google_ads/ad_config.dart`:
```dart
class AdConfig {
  static const bool isProduction = false; // Set to true for production
  // Add your production ad unit IDs
}
```

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

---

## 📁 Project Structure

```
lib/
├── config/              # Configuration files
│   └── api_config.dart
├── models/              # Data models
│   ├── job.dart
│   ├── category.dart
│   ├── country.dart
│   └── resume_model.dart
├── pages/               # UI screens
│   ├── home_screen.dart
│   ├── jobs_page.dart
│   ├── job_details_page.dart
│   ├── resume_maker_page.dart
│   └── ...
├── services/            # Business logic
│   ├── job_service.dart
│   ├── notification_service.dart
│   ├── review_service.dart
│   └── ...
├── templates/           # Resume templates
│   ├── modern_resume_template.dart
│   └── classic_resume_templates.dart
├── utils/              # Utilities
│   ├── logger.dart
│   ├── app_colors.dart
│   └── ...
└── widgets/            # Reusable widgets
    ├── google_ads/      # Ad system
    ├── job_card.dart
    └── ...
```

---

## 🎯 Key Features Explained

### Dynamic Ad System
The app features a sophisticated ad monetization system:
- **Remote Configuration**: Ad settings fetched from API
- **Visit-Based Triggers**: Ads shown after specific page visits
- **Daily Limits**: Maximum 8 ads per day
- **Cooldown Periods**: 2-15 minutes between ads
- **Multiple Ad Types**: Banner, Interstitial, Rewarded, Native, App Open

### Resume Builder
Create professional resumes with:
- Multiple template options
- Complete form-based input
- PDF generation and export
- Profile photo support
- All standard resume sections

### Job Search
Powerful job search capabilities:
- Real-time search with filters
- Category and country browsing
- Today's jobs feature
- Featured jobs section
- Detailed job information

---

## 🚀 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

---

## 📝 Environment Variables

Create a `.env` file (not committed to git) for sensitive configuration:
```
API_BASE_URL=your_production_api_url
FIREBASE_PROJECT_ID=your_firebase_project_id
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Maaz Khan**
- GitHub: [@coding-with-maaz](https://github.com/coding-with-maaz)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google for Firebase and Mobile Ads SDK
- All contributors and users of this project

---

<div align="center">

### ⭐ If you like this project, give it a star on GitHub!

Made with ❤️ using Flutter

</div>
