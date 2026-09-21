import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF17324A);
  static const muted = Color(0xFF5F6B76);
  static const teal = Color(0xFF006A66);
  static const mint = Color(0xFF5FDEA9);
  static const positive = Color(0xFF00A676);
  static const negative = Color(0xFFD64545);
  static const warning = Color(0xFF996300);
  static const successSurface = Color(0xFFDDF8EA);
  static const warningSurface = Color(0xFFFFE7A8);
  static const dangerSurface = Color(0xFFFFDED7);
  static const neutralSurface = Color(0xFFEDF8F5);
  static const cardBorder = Color(0xFFE0EBE8);
  static const softShadow = Color(0x1017324A);
  static const double heroRadius = 28;
  static const double cardRadius = 20;
  static const double actionRadius = 18;
  static const double controlRadius = 14;
  static const loginCanvas = Color(0xFFFBFDFC);
  static const heroGradientColors = [
    Color(0xFF003F42),
    Color(0xFF006A66),
    Color(0xFF08A39E),
    mint,
  ];
  static const heroGradientStops = [0.0, 0.5, 0.8, 1.0];
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal,
    ).copyWith(primary: teal, surface: Colors.white, onSurface: ink),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(fontSize: 14, color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6D7A78)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
    ),
  );
}
