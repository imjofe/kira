import 'package:flutter/material.dart';

const _primaryBlue = Color(0xFF5E8BFF);

/// Global gradient used throughout the app
const skyDawnGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF87CEEB), // Sky blue
    Color(0xFFFFE4B5), // Peach/dawn
  ],
);

class AppTheme {
  static final lightTheme = ThemeData(
    colorSchemeSeed: _primaryBlue,
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryBlue,
      unselectedItemColor: Colors.grey,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: _primaryBlue),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
      selectedLabelTextStyle: TextStyle(color: _primaryBlue),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: _primaryBlue,
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryBlue,
      unselectedItemColor: Colors.grey,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: _primaryBlue),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
      selectedLabelTextStyle: TextStyle(color: _primaryBlue),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey),
    ),
  );
}