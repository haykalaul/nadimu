import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFEE2B3B);
  static const Color backgroundLight = Color(0xFFF8F6F6);
  static const Color backgroundDark = Color(0xFF221012);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2A1618);
  static const Color textPrimaryLight = Color(0xFF181112);
  static const Color textPrimaryDark = Color(0xFFF8F6F6);
  static const Color textSecondaryLight = Color(0xFF896165);
  static const Color textSecondaryDark = Color(0xFFA88E91);
  static const Color borderLight = Color(0xFFF4F0F0);
  static const Color borderDark = Color(0xFF3C292B);
  static const Color green = Color(0xFF07885B);
  static const Color orange = Color(0xFFE75A08);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: textPrimaryLight),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimaryLight),
      ),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: primary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: textPrimaryDark),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimaryDark),
      ),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(secondary: primary),
    );
  }
}