import 'package:flutter/material.dart';

/// 应用主题 - 嫩芽绿主色调, 契合产品定位
class AppTheme {
  static const Color primary = Color(0xFF2E7D32);      // 健康绿
  static const Color primaryLight = Color(0xFFEAF3DE);
  static const Color accent = Color(0xFFBA7517);       // 暖阳橙(生长灯)
  static const Color secondary = Color(0xFF185FA5);    // 科技蓝(水)
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF6C00);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: const Color(0xFFFAFBF7),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8F3),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A234E),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF1A234E)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
