import 'package:flutter/material.dart';

/// 应用主题（当前仅亮色主题）。
abstract final class AppTheme {
  static const seedColor = Color(0xFF3B82F6);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
      ),
    );
  }
}
