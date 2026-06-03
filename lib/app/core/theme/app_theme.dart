import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0D0E15);
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color accentPink = Color(0xFFFF007F);
  
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF4361EE);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentPurple,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: Color(0xFF161722),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF161722),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: Color(0xFF4CC9F0),
        surface: lightCard,
      ),
      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Color(0x1F000000),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 16.0,
  }) {
    if (isDark) {
      return BoxDecoration(
        color: const Color(0xFF1E1F29).withOpacity(0.4),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }
}
