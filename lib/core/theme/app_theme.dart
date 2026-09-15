import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF17324A);
  static const muted = Color(0xFF5F6B76);
  static const teal = Color(0xFF006A66);
  static const mint = Color(0xFF5FDEA9);
  static const loginCanvas = Color(0xFFFBFDFC);
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
