# techcare_app

A new Flutter project.

## Firebase Setup

This project does not commit Firebase configuration files. Before running the
app, generate the local Firebase files with FlutterFire CLI.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will generate local files such as:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files are required for local development, but they are ignored by Git and
should not be committed to the repository.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
