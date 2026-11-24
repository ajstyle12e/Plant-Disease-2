import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // ── Backend URL ───────────────────────────────────────────────────────────
  // Override at build time:
  //   flutter build web --dart-define=BACKEND_URL=http://192.168.1.x:3000/api
  //   flutter run       --dart-define=BACKEND_URL=http://192.168.1.x:3000/api
  //
  // Defaults:
  //   Web     → localhost:3000  (works in browser on same machine)
  //   Android → 10.0.2.2:3000  (emulator alias for host localhost)
  static const String _envUrl = String.fromEnvironment('BACKEND_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    return kIsWeb
        ? 'http://localhost:3000/api'
        : 'http://10.0.2.2:3000/api';
  }

  static String get predictUrl => '$baseUrl/predict';
  static String get historyUrl => '$baseUrl/history';
  static String get guideUrl   => '$baseUrl/guide';
  static String get chatUrl    => '$baseUrl/chat';
}
