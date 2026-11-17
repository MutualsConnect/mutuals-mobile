import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

/// Motivos para reportar a alguien (`ReportReason`).
enum ReportReason {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Acoso'),
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Contenido inapropiado'),
  impersonation('IMPERSONATION', 'Se hace pasar por otra persona'),
  other('OTHER', 'Otro motivo');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}

/// Preferencias de la cuenta (`PreferencesResponse`).
class Preferences {
  const Preferences({
    this.locationSharingEnabled = false,
    this.pushEnabled = true,
    this.emailNotificationsEnabled = true,
    this.muteHighlights = false,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    locationSharingEnabled: json['locationSharingEnabled'] as bool? ?? false,
    pushEnabled: json['pushEnabled'] as bool? ?? true,
    emailNotificationsEnabled:
        json['emailNotificationsEnabled'] as bool? ?? true,
    muteHighlights: json['muteHighlights'] as bool? ?? false,
  );

  final bool locationSharingEnabled;
  final bool pushEnabled;
  final bool emailNotificationsEnabled;
  final bool muteHighlights;
}

/// Dispositivo registrado para notificaciones (`DeviceResponse`).
class Device {
  const Device({required this.id, required this.platform, this.lastSeenAt});

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: (json['id'] as num).toInt(),
    platform: json['platform'] as String? ?? '',
    lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
  );

  final int id;
  final String platform;
  final DateTime? lastSeenAt;
}

/// Edición del perfil propio, preferencias, dispositivos, bloqueos y reportes.
/// Personalización del perfil (`CustomizationResponse`).
class Customization {
  const Customization({
    required this.theme,
    required this.fireStyle,
    required this.appIcon,
  });

  final String theme;
  final String fireStyle;
  final String appIcon;

  factory Customization.fromJson(Map<String, dynamic> json) => Customization(
    theme: json['theme'] as String? ?? 'DEFAULT',
    fireStyle: json['fireStyle'] as String? ?? 'CLASSIC',
    appIcon: json['appIcon'] as String? ?? 'DEFAULT',
  );
}

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  /// Actualiza tu nombre y tu biografía.
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) => _guard(
    () => _dio.patch<void>(
      '/users/me',
      data: {'displayName': displayName.trim(), 'bio': bio.trim()},
    ),
  );

  Future<Preferences> preferences() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/preferences');
      return Preferences.fromJson(res.data!);
    } on DioException catch (e) {
      throw e.apiException;
    }
  }

  /// Cambia solo los campos indicados.
  Future<Preferences> updatePreferences({
    bool? locationSharingEnabled,
    bool? pushEnabled,
    bool? emailNotificationsEnabled,
    bool? muteHighlights,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me/preferences',
        data: {
          'locationSharingEnabled': ?locationSharingEnabled,
          'pushEnabled': ?pushEnabled,
          'emailNotificationsEnabled': ?emailNotificationsEnabled,
          'muteHighlights': ?muteHighlights,
        },
      );
      return Preferences.fromJson(res.data!);
    } on DioException catch (e) {
      throw e.apiException;
    }
  }

  Future<List<Device>> devices() async {
    try {
      final res = await _dio.get<List<dynamic>>('/users/me/devices');
      return [
        for (final d in res.data!) Device.fromJson(d as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw e.apiException;
    }
  }

  Future<void> removeDevice(int id) =>
      _guard(() => _dio.delete<void>('/users/me/devices/$id'));

  /// Anonimiza y cierra tu cuenta en el servidor.
  Future<void> deleteAccount() => _guard(() => _dio.delete<void>('/users/me'));

  Future<Customization> customization() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/me/customization',
      );
      return Customization.fromJson(res.data!);
    } on DioException catch (e) {
      throw e.apiException;
    }
  }

  Future<Customization> updateCustomization({
    String? theme,
    String? fireStyle,
    String? appIcon,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me/customization',
        data: {
          'theme': ?theme,
          'fireStyle': ?fireStyle,
          'appIcon': ?appIcon,
        },
      );
      return Customization.fromJson(res.data!);
    } on DioException catch (e) {
      throw e.apiException;
    }
  }

  Future<void> block(int userId) =>
      _guard(() => _dio.post<void>('/users/$userId/block'));

  Future<void> unblock(int userId) =>
      _guard(() => _dio.delete<void>('/users/$userId/block'));

  Future<void> report(int userId, ReportReason reason, {String? description}) =>
      _guard(
        () => _dio.post<void>(
          '/reports',
          data: {
            'reportedUserId': userId,
            'reason': reason.code,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          },
        ),
      );

  Future<void> _guard(Future<Response<void>> Function() call) async {
    try {
      await call();
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

final preferencesProvider = FutureProvider.autoDispose<Preferences>(
  (ref) => ref.watch(profileRepositoryProvider).preferences(),
);

final devicesProvider = FutureProvider.autoDispose<List<Device>>(
  (ref) => ref.watch(profileRepositoryProvider).devices(),
);

final customizationProvider = FutureProvider.autoDispose<Customization>(
  (ref) => ref.watch(profileRepositoryProvider).customization(),
);
