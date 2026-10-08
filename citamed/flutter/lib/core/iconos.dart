import 'package:flutter/material.dart';

/// Íconos que el administrador puede asignar a una especialidad (se guardan por nombre en MySQL).
class Iconos {
  static const Map<String, IconData> disponibles = {
    'medical_services': Icons.medical_services_outlined,
    'favorite': Icons.favorite_border,
    'child_care': Icons.child_care,
    'spa': Icons.spa_outlined,
    'healing': Icons.healing,
    'sentiment_satisfied': Icons.sentiment_satisfied_alt_outlined,
    'visibility': Icons.visibility_outlined,
    'psychology': Icons.psychology_outlined,
    'monitor_heart': Icons.monitor_heart_outlined,
    'vaccines': Icons.vaccines_outlined,
    'pregnant_woman': Icons.pregnant_woman,
    'hearing': Icons.hearing,
  };

  static IconData de(String clave) => disponibles[clave] ?? Icons.medical_services_outlined;

  /// Un color estable por especialidad, como en la lista del diseño.
  static Color colorDe(String clave) {
    const colores = <Color>[
      Color(0xFF2E86DE), Color(0xFFE5484D), Color(0xFF27AE60),
      Color(0xFFF39C12), Color(0xFF5B6EE1), Color(0xFF1ABC9C),
    ];
    final indice = disponibles.keys.toList().indexOf(clave);
    return colores[(indice < 0 ? 0 : indice) % colores.length];
  }
}
