import 'package:flutter/material.dart';

class DoserlyTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFFD6EFFF); // Light blue
  static const Color secondaryColor = Color(0xFFFED18C); // Soft orange/sunset
  static const Color accentColor = Color(0xFFFE654F); // Tomato red (accent)
  static const Color textPrimaryColor = Color(0xFF333333); // Dark gray
  static const Color backgroundWhite = Color(0xFFFEFEFF); // Off-white

  // Functional colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFFC107); // Amber
  static const Color errorColor = Color(0xFFF44336); // Red

  // Font sizes (larger for better readability for elderly)
  static const double fontSizeSmall = 16.0;
  static const double fontSizeMedium = 18.0;
  static const double fontSizeLarge = 22.0;
  static const double fontSizeXLarge = 28.0;

  // Padding and spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;

  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationLong = Duration(milliseconds: 500);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        onPrimary: textPrimaryColor,
        onSecondary: textPrimaryColor,
        background: backgroundWhite,
        surface: backgroundWhite,
        error: errorColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryColor,
        elevation: elevationSmall,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: textPrimaryColor,
          elevation: elevationMedium,
          padding: EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          textStyle: TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor, width: 2),
          padding: EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          textStyle: TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: backgroundWhite,
        elevation: elevationSmall,
        margin: EdgeInsets.all(paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondaryColor,
        contentTextStyle: TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}