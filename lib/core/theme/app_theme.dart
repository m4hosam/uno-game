import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE81E32); // Uno Red
  static const Color secondaryColor = Color(0xFF2D2D2D); // Dark Grey
  static const Color accentColor = Color(0xFFFFD700); // Gold/Yellow
  static const Color backgroundColor =
      Color(0xFF1E1111); // Dark Reddish Brown background
  static const Color surfaceColor =
      Color(0xFF2C1B1B); // Slightly lighter for cards/inputs

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    ),
    fontFamily: 'Roboto',
    elevatedButtonTheme: _elevatedButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: surfaceColor,
      primary: primaryColor,
    ),
    fontFamily: 'Roboto',
    elevatedButtonTheme: _elevatedButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      elevation: 0,
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    contentPadding: const EdgeInsets.all(16),
  );

  // UNO Colors
  static const Color unoRed = Color(0xFFE81E32);
  static const Color unoBlue = Color(0xFF00539F);
  static const Color unoGreen = Color(0xFF009D3E);
  static const Color unoYellow = Color(0xFFFFD700);
}
