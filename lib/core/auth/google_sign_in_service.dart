import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Obtiene el ID token de Google que el backend verifica en `/auth/google`.
///
/// Se configura al compilar con el Client ID de tipo "Aplicación web" (el mismo
/// que usa el backend en `GOOGLE_CLIENT_ID`):
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
/// En iOS además hace falta el Client ID de tipo iOS en `GOOGLE_IOS_CLIENT_ID`.
abstract interface class GoogleSignInService {
  /// `false` si falta el Client ID: el botón de Google no se muestra.
  bool get isConfigured;

  /// Devuelve el ID token, o `null` si la persona canceló.
  Future<String?> idToken();
}

class GoogleSignInServiceImpl implements GoogleSignInService {
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  late final _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _serverClientId,
    clientId: _iosClientId.isEmpty ? null : _iosClientId,
  );

  @override
  bool get isConfigured => _serverClientId.isNotEmpty;

  @override
  Future<String?> idToken() async {
    // Cerrar la sesión previa permite elegir otra cuenta cada vez.
    await _google.signOut();
    final account = await _google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInServiceImpl(),
);
