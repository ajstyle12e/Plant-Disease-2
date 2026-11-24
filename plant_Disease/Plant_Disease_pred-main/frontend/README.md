# Frontend — Flutter App

Cross-platform Flutter application (Web + Android) for plant disease classification and AI chat.

## Setup

```bash
flutter pub get
```

## Run (Web)

```bash
flutter build web --release
cd build/web
python -m http.server 5000
```

Open http://localhost:5000

## Run (Android)

```bash
# Emulator
flutter run

# Real device (set your machine IP)
flutter run --dart-define=BACKEND_URL=http://192.168.x.x:3000/api
```

## Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Screens

| Screen | Description |
|---|---|
| `HomeScreen` | Dashboard with 4 menu cards |
| `DetectScreen` | Upload/capture leaf image |
| `CameraScreen` | Live camera via getUserMedia (web) |
| `ResultScreen` | Disease name, AI explanation, Ask AI button |
| `HistoryScreen` | Past analyses list |
| `HistoryDetailScreen` | Full prediction detail |
| `ChatSessionsScreen` | Chat history list (ChatGPT-style) |
| `ChatScreen` | Multi-turn AI conversation |
| `GuideScreen` | Plant lifecycle + disease encyclopedia |

## Backend URL Config

Set via `--dart-define` at build time. Defaults to `localhost:3000` on web and `10.0.2.2:3000` on Android emulator.
