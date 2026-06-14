import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class CustomTheme {
  static const Color background = Color(0xFF080A0D);
  static const Color surface = Color(0xFF12161D);
  static const Color surfaceHigh = Color(0xFF1A2029);
  static const Color primary = Color(0xFFD7FF47);
  static const Color secondary = Color(0xFF5CE1E6);
  static const Color textPrimary = Color(0xFFF6F8FA);
  static const Color textSecondary = Color(0xFFAAB2C0);
  static const Color danger = Color(0xFFFF6B6B);

  static const SystemUiOverlayStyle systemStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        error: danger,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: textPrimary,
        systemOverlayStyle: systemStyle,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
