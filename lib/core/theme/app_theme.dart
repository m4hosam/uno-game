import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
  );

  // UNO Colors
  static const Color unoRed = Color(0xFFFF5555);
  static const Color unoBlue = Color(0xFF5555FF);
  static const Color unoGreen = Color(0xFF55AA55);
  static const Color unoYellow = Color(0xFFFFAA00);
}
