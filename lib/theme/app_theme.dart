import 'package:flutter/material.dart';

class AppThemeColors {
  static const Color ink = Color(0xFF0A1428);
  static const Color slate = Color(0xFF55637A);
  static const Color mist = Color(0xFFE7F0F2);
  static const Color haze = Color(0xFFF4F8FA);
  static const Color panel = Color(0xFFFDFEFE);
  static const Color panelAlt = Color(0xFFF0F6F8);
  static const Color line = Color(0xFFC7D6DB);
  static const Color primary = Color(0xFF0B7A75);
  static const Color primaryDeep = Color(0xFF075854);
  static const Color primarySoft = Color(0xFFD4F0EB);
  static const Color secondary = Color(0xFFF08A24);
  static const Color secondarySoft = Color(0xFFFFE7C8);
  static const Color info = Color(0xFF145A86);
  static const Color infoSoft = Color(0xFFD7EAF8);
  static const Color accent = Color(0xFF1DB3D8);
  static const Color accentSoft = Color(0xFFD7F4FB);
  static const Color success = Color(0xFF1D8F52);
  static const Color successSoft = Color(0xFFD8F3E4);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFCE5E3);
  static const Color violet = Color(0xFF6C4CE3);
  static const Color violetSoft = Color(0xFFE5DFFE);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppThemeColors.primary,
      onPrimary: Colors.white,
      secondary: AppThemeColors.secondary,
      onSecondary: Colors.white,
      error: AppThemeColors.danger,
      onError: Colors.white,
      surface: AppThemeColors.panel,
      onSurface: AppThemeColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppThemeColors.haze,
      canvasColor: AppThemeColors.haze,
      dividerColor: AppThemeColors.line,
      splashColor: AppThemeColors.primary.withValues(alpha: 0.08),
      highlightColor: AppThemeColors.primary.withValues(alpha: 0.05),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppThemeColors.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppThemeColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        headlineMedium: TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: AppThemeColors.slate,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: AppThemeColors.slate,
          height: 1.55,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppThemeColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppThemeColors.ink.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppThemeColors.line),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppThemeColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppThemeColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppThemeColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppThemeColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppThemeColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppThemeColors.danger, width: 1.6),
        ),
        labelStyle: const TextStyle(
          color: AppThemeColors.slate,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppThemeColors.primary,
        suffixIconColor: AppThemeColors.slate,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8C6C0),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppThemeColors.ink,
          side: const BorderSide(color: AppThemeColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppThemeColors.info,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppThemeColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppThemeColors.secondary,
        foregroundColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppThemeColors.primary,
        textColor: AppThemeColors.ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppThemeColors.panelAlt,
        selectedColor: AppThemeColors.primarySoft,
        secondarySelectedColor: AppThemeColors.primarySoft,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          color: AppThemeColors.ink,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppThemeColors.panel,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppThemeColors.secondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppThemeColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
