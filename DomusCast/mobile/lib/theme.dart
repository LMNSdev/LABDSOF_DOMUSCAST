import 'package:flutter/material.dart';

const _primary = Color(0xFF0F3478);
const _secondary = Color(0xFF1565C0);
const _accent = Color(0xFF42A5F5);

/// Estados com cor própria, como nos wireframes (US-28): verde para concluído
/// e amarelo para pendente ou aviso. Texto escuro para manter o contraste.
const sucessoFundo = Color(0xFFDFF5E3);
const sucessoTexto = Color(0xFF1C6B2C);
const avisoFundo = Color(0xFFFFF2D6);
const avisoTexto = Color(0xFF5C4000);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    secondary: _secondary,
    tertiary: _accent,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  scaffoldBackgroundColor: const Color(0xFFF0F4FB),
);
