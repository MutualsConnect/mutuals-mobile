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

  /// Convierte la ruta de un archivo que devuelve la API (por ejemplo `/uploads/moments/x.png`)
  /// en una dirección completa que se pueda descargar. Las que ya son completas se dejan igual.
  static String mediaUrl(String url, {String? apiBaseUrl}) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final api = Uri.parse(apiBaseUrl ?? baseUrl);
    return api
        .replace(path: url.startsWith('/') ? url : '/$url', query: '')
        .toString()
        .replaceFirst(RegExp(r'\?$'), '');
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
}
