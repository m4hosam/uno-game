# Startup & Firebase Configuration Guide

Follow these steps to configure Firebase and run the UNO application.

## Prerequisites

- **Flutter SDK** installed (v3.0.0+).
- **Firebase Account**.
- **Node.js** (for Firebase CLI).

## Step 1: Firebase Project Setup

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add project** and follow the prompts to create a new project (e.g., "flutter-uno-game").
3.  **Enable Authentication**:
    - Go to **Build** > **Authentication**.
    - Click **Get Started**.
    - Select **Sign-in method** tab.
    - Enable **Anonymous** and click **Save**.
4.  **Enable Realtime Database**:
    - Go to **Build** > **Realtime Database**.
    - Click **Create Database**.
    - Choose a location (e.g., United States).
    - Start in **Test mode** (allows read/write access for development).
      - _Note: For production, you will need to configure Security Rules._

## Step 2: Configure Flutter App with Firebase

We use the `flutterfire_cli` to automatically generate the configuration.

1.  **Install Firebase CLI** (if not installed):
    ```bash
    npm install -g firebase-tools
    ```
2.  **Login to Firebase**:
    ```bash
    firebase login
    ```
3.  **Install FlutterFire CLI** (if not installed):
    ```bash
    dart pub global activate flutterfire_cli
    ```
4.  **Configure the App**:
    Run the following command in the root of your Flutter project (`e:\m4hosam\uno-mine\flutter_unu_app`):
    ```bash
    flutterfire configure
    ```
    - Select your newly created Firebase project.
    - Select the platforms you want to support (Android, iOS, Web, etc.).
    - This will generate a file named `lib/firebase_options.dart`.

## Step 3: Final Code Setup

1.  **Open `lib/main.dart`**.
2.  **Uncomment Firebase Initialization**:
    Ensure the following lines are uncommented in the `main()` function:

    ```dart
    // Import the generated file
    import 'firebase_options.dart';

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      runApp(const ProviderScope(child: UnoApp()));
    }
    ```

## Step 4: Run the Application

1.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate Localizations** (if needed):
    ```bash
    flutter gen-l10n
    ```
3.  **Run**:
    ```bash
    flutter run
    ```

## Troubleshooting

- **"Target of URI doesn't exist: ...app_localizations.dart"**: Run `flutter gen-l10n` and restart your IDE.
- **Firebase Errors**: Ensure `firebase_options.dart` exists and matches your Firebase project ID. Ensure Realtime Database rules allow read/write.
