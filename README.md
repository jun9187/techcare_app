# TechCare App

TechCare is a Flutter app for managing tech equipment and user access. It uses Firebase Authentication and Cloud Firestore for sign-in, role-based access, profile data, and inventory records.

The app currently supports:

- Student and admin sign-in
- Email/password and Google authentication
- Role-based routing after login
- Student profile viewing and editing
- Admin inventory browsing, filtering, and item management
- Optional inventory image uploads through Cloudinary

## Tech Stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Storage dependency included in the project
- `flutter_bloc` for auth state handling
- Cloudinary for inventory image uploads

## Project Structure

Key folders:

- `lib/blocs` - authentication state management
- `lib/models` - app data models
- `lib/screens` - login, register, profile, and admin screens
- `lib/services` - Firebase auth and inventory services

## Setup On a New PC

These steps assume you are setting up the project locally after cloning the repository.

### 1. Install required tools

Install and verify:

- Flutter SDK
- Android Studio or VS Code with Flutter and Dart extensions
- Android SDK / emulator if you want to run on Android
- Git
- Firebase CLI
- FlutterFire CLI

Useful checks:

```bash
flutter --version
flutter doctor
dart --version
firebase --version
```

### 2. Clone the repository

```bash
git clone <your-repo-url>
cd techcare_app
```

### 3. Install Flutter packages

```bash
flutter pub get
```

### 4. Connect the app to Firebase

This repository does not commit Firebase configuration files. You must generate them locally for your own machine and Firebase project.

If needed, install the FlutterFire CLI first:

```bash
dart pub global activate flutterfire_cli
```

Then configure Firebase from the project root:

```bash
flutterfire configure
```

This generates local files such as:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files are required for local development and should not be committed.

### 5. Create the required Firebase services

In your Firebase project, make sure these are enabled:

- Authentication
- Cloud Firestore

Recommended auth providers for this app:

- Email/Password
- Google Sign-In

### 6. Optional: configure Cloudinary for image uploads

Admin inventory image uploads require Cloudinary runtime variables. Without them, the app can still run, but image upload from the inventory form will fail.

Run the app with:

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=your_upload_preset
```

If you do not need image upload yet, you can skip these values for initial setup.

### 7. Run the app

```bash
flutter run
```

If you are using Cloudinary uploads, use the command with `--dart-define` values instead.

## First-Time Data Notes

- New users are stored in the Firestore `users` collection.
- The app expects a user `role` such as `student` or `admin`.
- If a user has no stored role yet, the app defaults that user to `student`.
- Inventory data is stored in the Firestore `inventory` collection.

## Suggested New-PC Checklist

After setup, confirm these work:

- `flutter doctor` shows no blocking issues
- `flutter pub get` completes successfully
- `flutterfire configure` creates local Firebase files
- Firebase Authentication providers are enabled
- Firestore is available and readable/writable for your project
- The app launches and reaches the login screen

## Troubleshooting

### Missing `firebase_options.dart`

Run:

```bash
flutterfire configure
```

### Firebase login or Firestore errors

Check:

- you are connected to the correct Firebase project
- Authentication providers are enabled
- Firestore has been created in that project
- your local config files were generated in this clone

### Cloudinary upload error

Check that both runtime values are provided:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`

## Development Notes

- Firebase config files are intentionally ignored by Git.
- The current Android package name is `com.example.techcare_app`.
- The app routes admins to the admin shell and students to the profile flow after authentication.
