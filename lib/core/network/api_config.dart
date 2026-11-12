import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Configuración de la API.
///
/// Se puede sobrescribir al ejecutar:
/// `flutter run --dart-define=API_URL=http://192.168.1.10:8080/api/v1`
abstract final class ApiConfig {
  static const _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // El emulador de Android ve la máquina anfitriona como 10.0.2.2;
    // el simulador de iOS comparte localhost con el Mac.
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8080/api/v1';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
}
