import 'package:flutter/material.dart';

/// Paleta de Mutuals: modo oscuro con superficies de vidrio.
abstract final class AppColors {
  /// Durazno principal: botones, acentos y la racha.
  static const peach = Color(0xFFFFBE91);

  /// Texto e iconos sobre el durazno (marrón muy oscuro, buen contraste).
  static const onAccent = Color(0xFF2B1B14);

  /// Fondo base de todas las pantallas.
  static const background = Color(0xFF0B0A12);

  /// Texto principal (blanco cálido).
  static const ink = Color(0xFFF7F3EE);

  /// Texto secundario.
  static const inkSoft = Color(0xFFB0AAB8);

  /// Celeste: acento frío y estados confirmados.
  static const sky = Color(0xFFCFEBFF);

  /// Superficie de vidrio neutra (tarjetas).
  static const glass = Color(0x1AFFFFFF);

  /// Vidrio más tenue (elementos secundarios o inactivos).
  static const glassSoft = Color(0x0FFFFFFF);

  /// Vidrio teñido de celeste (estados confirmados).
  static const glassSky = Color(0x2ECFEBFF);

  /// Vidrio teñido de durazno (resaltados).
  static const glassPeach = Color(0x33FFBE91);

  /// Borde fino del vidrio.
  static const glassBorder = Color(0x2EFFFFFF);

  /// Errores y avisos de riesgo.
  static const danger = Color(0xFFFF6B5B);
}
