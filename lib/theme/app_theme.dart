import 'package:flutter/material.dart';

class DocuMateTheme {
  DocuMateTheme._();

  // Dark color palette - Updated to match professional design
  static const Color primaryDark = Color(0xFF121212); // Background
  static const Color secondaryDark = Color(0xFF1A1F3A);
  static const Color cardDark = Color(0xFF1E1E1E); // Surface
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Accent colors - Updated primary accent
  static const Color accentBlue = Color(0xFF5E81F3); // Primary accent
  static const Color accentPurple = Color(0xFF7B68EE);
  static const Color accentGreen = Color(0xFF5DBD9D);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentRed = Color(0xFFE74C3C);

  // Text colors
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF505050);

  // Status colors
  static const Color success = Color(0xFF5DBD9D);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF4A90E2);

  // Document category colors
  static const Color categoryId = Color(0xFF4A90E2);
  static const Color categoryInsurance = Color(0xFF7B68EE);
  static const Color categoryBills = Color(0xFF5DBD9D);
  static const Color categoryMedical = Color(0xFFE74C3C);
  static const Color categoryLegal = Color(0xFFFF8C42);
  static const Color categoryOther = Color(0xFFB0B0B0);

  static const String fontName = 'Roboto';

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 40,
    letterSpacing: 0.5,
    height: 1.1,
    color: textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    letterSpacing: 0.4,
    height: 1.1,
    color: textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 28,
    letterSpacing: 0.3,
    color: textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 0.25,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: 0.2,
    color: textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.18,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0.1,
    color: textSecondary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: textTertiary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0.1,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 0.1,
    color: textTertiary,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: accentBlue,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentPurple,
      surface: cardDark,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: headlineMedium,
    ),
    textTheme: textTheme,
    fontFamily: fontName,
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentBlue,
      foregroundColor: textPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: textPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: surfaceDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      labelStyle: bodyMedium,
      hintStyle: bodySmall,
    ),
  );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: accentBlue,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentPurple,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1E1E1E),
      error: error,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
      titleTextStyle: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        letterSpacing: 0.25,
        color: Color(0xFF1E1E1E),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 40,
        letterSpacing: 0.5,
        height: 1.1,
        color: Color(0xFF1E1E1E),
      ),
      displayMedium: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 32,
        letterSpacing: 0.4,
        height: 1.1,
        color: Color(0xFF1E1E1E),
      ),
      displaySmall: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 28,
        letterSpacing: 0.3,
        color: Color(0xFF1E1E1E),
      ),
      headlineLarge: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: 0.27,
        color: Color(0xFF1E1E1E),
      ),
      headlineMedium: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        letterSpacing: 0.25,
        color: Color(0xFF1E1E1E),
      ),
      headlineSmall: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: 0.2,
        color: Color(0xFF1E1E1E),
      ),
      titleLarge: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.18,
        color: Color(0xFF1E1E1E),
      ),
      titleMedium: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.15,
        color: Color(0xFF1E1E1E),
      ),
      titleSmall: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.1,
        color: Color(0xFF666666),
      ),
      bodyLarge: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: 0.15,
        color: Color(0xFF1E1E1E),
      ),
      bodyMedium: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.2,
        color: Color(0xFF666666),
      ),
      bodySmall: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        letterSpacing: 0.2,
        color: Color(0xFF999999),
      ),
      labelLarge: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
        color: Color(0xFF1E1E1E),
      ),
      labelMedium: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.1,
        color: Color(0xFF666666),
      ),
      labelSmall: TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 0.1,
        color: Color(0xFF999999),
      ),
    ),
    fontFamily: fontName,
    iconTheme: const IconThemeData(
      color: Color(0xFF666666),
      size: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentBlue,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      labelStyle: const TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.2,
        color: Color(0xFF666666),
      ),
      hintStyle: const TextStyle(
        fontFamily: fontName,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        letterSpacing: 0.2,
        color: Color(0xFF999999),
      ),
    ),
  );

  /// Generate a dark theme with a custom accent color
  static ThemeData darkThemeWithAccent(Color accentColor) {
    return darkTheme.copyWith(
      primaryColor: accentColor,
      colorScheme: darkTheme.colorScheme.copyWith(primary: accentColor),
      floatingActionButtonTheme: darkTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: darkTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(accentColor),
        ),
      ),
      inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }

  /// Generate a light theme with a custom accent color
  static ThemeData lightThemeWithAccent(Color accentColor) {
    return lightTheme.copyWith(
      primaryColor: accentColor,
      colorScheme: lightTheme.colorScheme.copyWith(primary: accentColor),
      floatingActionButtonTheme: lightTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: lightTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(accentColor),
        ),
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }

  // Helper method to get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'id':
      case 'identity':
        return categoryId;
      case 'insurance':
        return categoryInsurance;
      case 'bills':
      case 'utility':
        return categoryBills;
      case 'medical':
      case 'health':
        return categoryMedical;
      case 'legal':
      case 'contract':
        return categoryLegal;
      default:
        return categoryOther;
    }
  }

  // Helper method to get status color
  static Color getStatusColor(bool isExpiringSoon, bool isExpired) {
    if (isExpired) return error;
    if (isExpiringSoon) return warning;
    return success;
  }
}
