/// Validaciones de formulario alineadas con las reglas del backend.
/// Devuelven `null` si el valor es válido, o el mensaje de error.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[a-z0-9._]{3,30}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (v.length > 120 || !_email.hasMatch(v)) return 'Correo no válido';
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Elige un nombre de usuario';
    if (!_username.hasMatch(v)) {
      return '3 a 30 caracteres: minúsculas, números, punto o guion bajo';
    }
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  /// 8 a 72 caracteres con mayúscula, minúscula, número y símbolo.
  static String? strongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < 8 || v.length > 72) return 'Entre 8 y 72 caracteres';
    if (!RegExp('[A-Z]').hasMatch(v)) return 'Agrega una mayúscula';
    if (!RegExp('[a-z]').hasMatch(v)) return 'Agrega una minúscula';
    if (!RegExp('[0-9]').hasMatch(v)) return 'Agrega un número';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Agrega un símbolo';
    return null;
  }

  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null;
}
