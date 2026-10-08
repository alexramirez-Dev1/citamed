import 'package:flutter/material.dart';

/// Colores de la marca y de cada perfil.
class Paleta {
  static const Color paciente = Color(0xFF0B8A74);
  static const Color menta = Color(0xFF00B894);
  static const Color medico = Color(0xFF0984E3);
  static const Color admin = Color(0xFF6C47C4);

  static const Color fondo = Color(0xFFF3F8F7);
  static const Color texto = Color(0xFF1E2D2B);
  static const Color textoSuave = Color(0xFF6B7C79);
  static const Color borde = Color(0xFFD5E0DD);

  static const Color confirmada = Color(0xFF00A86B);
  static const Color pendiente = Color(0xFFF39C12);
  static const Color atendida = Color(0xFF0984E3);
  static const Color cancelada = Color(0xFFD63031);
}

class TemaApp {
  /// Un mismo tema con distinto color principal según el rol.
  static ThemeData construir(Color primario) {
    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Paleta.borde),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primario).copyWith(primary: primario, onPrimary: Colors.white),
      scaffoldBackgroundColor: Paleta.fondo,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ).copyWith(backgroundColor: primario, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(borderSide: BorderSide(color: primario, width: 1.8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: primario.withAlpha(120)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primario.withAlpha(35),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
