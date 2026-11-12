import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../data/auth_repository.dart';
import '../data/models/user_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final UserProfile? user;
}

/// Estado de la sesión: restaura al abrir, inicia, registra y cierra sesión.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Si la sesión expira y no se puede renovar, volvemos al login.
    ref.listen(sessionExpiredProvider, (_, _) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
    Future.microtask(restore);
    return const AuthState();
  }

  Future<void> restore() async {
    try {
      final user = await _repo.restoreSession();
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException {
      // Sin conexión: mostramos el login; la sesión guardada se conserva.
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Lanza [ApiException] si falla, para que el formulario muestre el error.
  Future<void> login(String email, String password) async {
    final user = await _repo.login(email: email, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> register({
    required String email,
    required String username,
    required String displayName,
    required String password,
  }) async {
    final user = await _repo.register(
      email: email,
      username: username,
      displayName: displayName,
      password: password,
    );
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
