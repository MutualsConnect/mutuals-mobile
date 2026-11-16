import 'package:flutter/services.dart';

/// Vibraciones suaves para que los toques se sientan físicos.
abstract final class Haptics {
  /// Un toque ligero: dar me gusta, cambiar de pestaña.
  static void light() => HapticFeedback.lightImpact();

  /// Una acción importante: confirmar una interacción.
  static void medium() => HapticFeedback.mediumImpact();

  /// Una celebración: racha confirmada.
  static void success() => HapticFeedback.heavyImpact();

  /// Cambiar entre opciones.
  static void selection() => HapticFeedback.selectionClick();
}
