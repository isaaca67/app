import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Identidad visual COV: Negro puro, Blanco y acento Rosa/Salmón
  static const Color primaryColor = Color(0xFFFF7A8A);
  static const Color accentColor = Color(0xFFFF7A8A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFEF6C00);
  static const Color successColor = Color(0xFF2E7D32);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkBorder = Color(0xFF2A2A2A);

  static final BorderRadius radiusXS = BorderRadius.circular(4);
  static final BorderRadius radiusSM = BorderRadius.circular(8);
  static final BorderRadius radiusMD = BorderRadius.circular(12);
  static final BorderRadius radiusLG = BorderRadius.circular(16);
  static final BorderRadius radiusXL = BorderRadius.circular(20);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFF212121),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF212121),
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF212121),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF212121),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF424242),
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF424242)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF616161)),
    bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9E9E9E)),
  );

  static const TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
    bodySmall: TextStyle(fontSize: 12, color: Colors.white38),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white54),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      textTheme: lightTextTheme.copyWith(
        headlineLarge: GoogleFonts.interTextTheme().headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 8,
        centerTitle: true,
        backgroundColor: Color(0xFF000000),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 12,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 12,
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return const TextStyle(color: Color(0xFF9E9E9E));
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusLG),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.grey[300];
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.grey[300],
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: Color(0xFF424242)),
        secondaryLabelStyle: const TextStyle(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        brightness: Brightness.dark,
      ),
      textTheme: darkTextTheme.copyWith(
        headlineLarge: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 8,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 12,
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 12,
        backgroundColor: darkSurface,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return const TextStyle(color: Colors.white54);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusLG),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: darkSurface,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.grey[700];
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      scaffoldBackgroundColor: darkBackground,
      dividerColor: darkBorder,
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1F1F1F),
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white70),
        secondaryLabelStyle: const TextStyle(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }
}