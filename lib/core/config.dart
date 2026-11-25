import 'package:flutter/foundation.dart';

/// Base de la API.
///
/// En el emulador de Android `10.0.2.2` apunta a la PC.
/// En un teléfono físico: `flutter run --dart-define=API_BASE_URL=http://TU_IP:8000`
class AppConfig {
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
