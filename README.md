# FitTrack ⚡️

FitTrack is a modern, offline-first fitness companion built with Flutter and Firebase. It helps users track their daily activity, log workouts, and stay consistent with their fitness goals through smart reminders and real-time step counting.

## 🚀 Features

- **Dashboard**: Real-time tracking of daily steps, calories burned, and active minutes.
- **Workout Logging**: Log various exercise types (Running, HIIT, Strength, etc.) with detailed metrics.
- **Interval Timer**: Customisable HIIT timer with work/rest phases, audio beeps, and haptic feedback.
- **Goal Management**: Set and track personalized daily and weekly fitness targets.
- **Smart Reminders**: Recurring local notifications to keep you on track with your routines.
- **Biometric Security**: Secure your data with fingerprint or face recognition.
- **Offline Support**: Seamlessly log workouts and update goals even without an internet connection.
- **Auth**: Secure sign-in via Email/Password or Google Sign-In.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Auth & Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [SQLite](https://pub.dev/packages/sqflite) (for step caching and workout drafts)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)

## 📦 Project Structure

```text
lib/
├── models/          # Data models (Workout, Goal, User, etc.)
├── providers/       # Business logic and state management
├── services/        # Hardware and API integrations (Firestore, Pedometer, Notifs)
├── screens/         # UI Screens organized by feature
├── utils/           # Constants, themes, and routing logic
└── widgets/         # Reusable UI components
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code
- A Firebase project

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/fit_track.git
   cd fit_track
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps to the project.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective directories.
   - Enable **Firestore**, **Authentication** (Email & Google), and **Storage**.

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📱 Platform Specifics

### Android
- Requires `MainActivity` to inherit from `FlutterFragmentActivity` for biometric support.
- Permissions needed: `ACTIVITY_RECOGNITION`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC`.

### iOS
- Add `NSFaceIDUsageDescription` to `Info.plist` for biometric support.
- Enable `Background Modes` for fetch and remote notifications.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
