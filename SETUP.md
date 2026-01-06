# 🚀 Setup Guide for LonelyReminder

This guide will walk you through setting up **LonelyReminder** on your local machine for development and testing.

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

- **Flutter SDK** (latest stable): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Git**: [Install Git](https://git-scm.com/downloads)
- **Firebase Account**: [Create Firebase Account](https://firebase.google.com/)
- **Android Studio** (for Android development): [Download](https://developer.android.com/studio)
- **Xcode** (for iOS/macOS development, macOS only): [Download from App Store](https://apps.apple.com/us/app/xcode/id497799835)

### Platform-Specific Requirements

#### For Android Development
- Android SDK (comes with Android Studio)
- Android Emulator or physical device
- Java Development Kit (JDK) 8 or higher

#### For iOS/macOS Development (macOS only)
- Xcode 14.0 or later
- CocoaPods: `sudo gem install cocoapods`
- iOS Simulator or physical device
- Apple Developer Account (for device testing)

---

## 🔧 Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/LonelyGuy12/lonelyreminder.git
cd lonelyreminder
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

---

## 🔥 Firebase Configuration

LonelyReminder uses Firebase for authentication and cloud storage. Follow these steps to set up Firebase:

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Name your project (e.g., `lonelyreminder-app`)
4. Follow the setup wizard (you can disable Google Analytics if not needed)

### Step 2: Enable Firebase Services

1. In your Firebase project, enable the following services:
   - **Authentication** → Sign-in method → Enable **Google Sign-In**
   - **Cloud Firestore** → Create database (start in **test mode** for development)

### Step 3: Add Apps to Firebase Project

You need to register each platform separately:

#### Android App

1. In Firebase Console, click **"Add app"** → Select **Android**
2. Register app with package name: `com.example.lonelyreminder`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### iOS App

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. Register app with bundle ID: `com.example.lonelyreminder`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

#### macOS App

1. In Firebase Console, click **"Add app"** → Select **iOS** (use same for macOS)
2. Register app with bundle ID: `com.example.lonelyreminder`
3. Download `GoogleService-Info.plist`
4. Place it in: `macos/Runner/GoogleService-Info.plist`

### Step 4: Update `firebase_options.dart`

Open `lib/firebase_options.dart` and replace all `YOUR_*` placeholders with actual values from your Firebase configuration files:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',           // From google-services.json
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',               // From GoogleService-Info.plist
  appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  iosBundleId: 'com.example.lonelyreminder',
  iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
);

// Similar for macOS...
```

### Step 5: Update iOS `Info.plist` (iOS only)

Open `ios/Runner/Info.plist` and find the `CFBundleURLSchemes` section. Replace `YOUR_REVERSED_CLIENT_ID` with the actual value from your `GoogleService-Info.plist` (look for the `REVERSED_CLIENT_ID` key):

```xml
<array>
  <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
</array>
```

---

## 📱 Platform-Specific Setup

### Android Setup

1. **Open Android Studio** and open the `android/` folder
2. **Sync Gradle files**
3. **Run the app:**

```bash
flutter run -d android
```

### iOS Setup (macOS only)

1. **Navigate to iOS directory:**

```bash
cd ios
```

2. **Install CocoaPods dependencies:**

```bash
pod install
pod update
```

3. **Open Xcode:**

```bash
open Runner.xcworkspace
```

4. **Configure Signing:**
   - Select `Runner` in the project navigator
   - Go to **Signing & Capabilities**
   - Select your **Team** (Apple Developer Account)

5. **Run the app:**

```bash
cd ..
flutter run -d ios
```

### macOS Setup (macOS only)

1. **Navigate to macOS directory:**

```bash
cd macos
```

2. **Install CocoaPods dependencies:**

```bash
pod install
pod update
```

3. **Enable required entitlements:**
   - Open `Runner.xcworkspace` in Xcode
   - Verify signing and capabilities are configured

4. **Run the app:**

```bash
cd ..
flutter run -d macos
```

---

## 🔑 Google Sign-In Configuration

### Android

1. In Firebase Console, go to **Authentication** → **Sign-in method** → **Google**
2. Add your **SHA-1** and **SHA-256** certificate fingerprints:

```bash
# For debug builds
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

3. Copy the SHA-1 and SHA-256 fingerprints to Firebase Console under **Project Settings** → **Your apps** → **Android app**

### iOS/macOS

The `GoogleService-Info.plist` already contains the necessary OAuth configuration. Ensure you've updated the `Info.plist` with the correct `REVERSED_CLIENT_ID`.

---

## 🧪 Running the App

### 1. Start an Emulator/Simulator

**Android:**
```bash
flutter emulators --launch <emulator_id>
```

**iOS:**
```bash
open -a Simulator
```

### 2. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on a specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### 3. Hot Reload

While the app is running:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

---

## 🏗️ Building for Production

### Android (APK/AAB)

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (IPA)

```bash
flutter build ipa --release
```

Then open `build/ios/archive/Runner.xcarchive` in Xcode to upload to App Store.

### macOS (App)

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/lonelyreminder.app`

---

## ⚙️ Configuration Files

### Template Files

If you need reference examples, template files are provided:

- `android/app/google-services.json.example`
- `ios/Runner/GoogleService-Info.plist.example`
- `macos/Runner/GoogleService-Info.plist.example`

Copy these files to their actual locations (without `.example`) and replace placeholders with your Firebase project values.

---

## 🐛 Troubleshooting

### Common Issues

#### "Firebase not initialized" error
- Ensure Firebase configuration files are in the correct locations
- Verify `firebase_options.dart` has correct values
- Check that you called `await Firebase.initializeApp()` in `main.dart`

#### Google Sign-In fails on Android
- Verify SHA-1/SHA-256 fingerprints are added to Firebase Console
- Ensure `google-services.json` is up to date
- Check that Google Sign-In is enabled in Firebase Authentication

#### CocoaPods issues on iOS/macOS
```bash
cd ios  # or macos
pod deintegrate
pod cache clean --all
pod install
```

#### ML Kit text recognition not working
- Ensure you have camera permissions enabled
- Check that `google_ml_kit` is properly installed: `flutter pub get`
- For iOS: Verify ML Kit is in `Podfile` and run `pod install`

#### Build fails with "Duplicate class" errors
- Clean the build: `flutter clean`
- Re-fetch dependencies: `flutter pub get`
- For Android: `cd android && ./gradlew clean`

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Google ML Kit Documentation](https://developers.google.com/ml-kit/vision/text-recognition/v2)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)

---

## 🆘 Getting Help

If you encounter any issues:

1. Check the **[Issues](https://github.com/LonelyGuy12/lonelyreminder/issues)** page on GitHub
2. Run `flutter doctor -v` and share the output
3. Check the **[Discussions](https://github.com/LonelyGuy12/lonelyreminder/discussions)** for common questions

---

## 📝 Next Steps

After setup is complete:

1. ✅ Run the app on your device/emulator
2. ✅ Test Google Sign-In functionality
3. ✅ Try capturing an event from an image
4. ✅ Verify Calendar integration works
5. ✅ Test offline functionality

---

**Happy Coding! 🎉**

If you found this helpful, please ⭐ star the repository!
