import 'package:flutter/material.dart';

/// Design system v3 for Artemis Business OS.
///
/// Identity:
///   - Brand: indigo (#4F46E5) → violet (#7C3AED) — premium, trustworthy
///   - Accent: cyan (#06B6D4) — futuristic highlights, AI/insights
///   - Success: emerald (#10B981)
///   - Warning: amber (#F59E0B)
///   - Danger: rose (#F43F5E)
///   - Info: sky (#0EA5E9)
class AppTheme {
  // ===== Brand =====
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color accentColor = Color(0xFF7C3AED);
  static const Color cyanColor = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFFCFFAFE);

  // ===== Semantic =====
  static const Color successColor = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerColor = Color(0xFFF43F5E);
  static const Color dangerLight = Color(0xFFFFE4E6);
  static const Color infoColor = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ===== Neutrals (slate) =====
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  static const Color backgroundColor = slate50;
  static const Color surfaceColor = Colors.white;
  static const Color surfaceMuted = slate50;

  // ===== Spacing scale (4px base) =====
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  // ===== Radius scale =====
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radiusFull = 999;

  // ===== Motion durations =====
  static const Duration durFast = Duration(milliseconds: 150);
  static const Duration durBase = Duration(milliseconds: 250);
  static const Duration durSlow = Duration(milliseconds: 400);
  static const Duration durSpring = Duration(milliseconds: 500);

  // ===== Motion curves =====
  static const Curve curveSpring = Cubic(0.16, 1, 0.3, 1);
  static const Curve curveEase = Cubic(0.4, 0, 0.2, 1);
  static const Curve curveBack = Cubic(0.34, 1.56, 0.64, 1);

  // ===== Gradients =====
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient gradientAurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient gradientWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
  );

  static const LinearGradient gradientDanger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
  );

  static const LinearGradient gradientCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
  );

  static const LinearGradient gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF7C3AED)],
    stops: [0.0, 0.6, 1.0],
  );

  static const RadialGradient glowPrimary = RadialGradient(
    colors: [Color(0x4D6366F1), Color(0x006366F1)],
  );

  // ===== Glow shadows =====
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> elevationXs = [
    BoxShadow(color: Color(0x08000000), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevationSm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevationMd = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevationLg = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> elevationXl = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        tertiary: cyanColor,
        error: dangerColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: slate900,
        surfaceContainerHighest: slate100,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      highlightColor: primaryColor.withValues(alpha: 0.08),
      hoverColor: primaryColor.withValues(alpha: 0.04),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: slate700),
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: slate400,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: slate600,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: slate500,
        suffixIconColor: slate500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dangerColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slate700,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: slate200, width: 1.2),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        extendedTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate100,
        selectedColor: primaryLight,
        labelStyle: const TextStyle(
          color: slate700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate200,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: slate900,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: const TextStyle(
          color: slate900,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        contentTextStyle: const TextStyle(
          color: slate700,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        showDragHandle: false,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: slate500,
        textColor: slate900,
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: slate500,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 72,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: slate700,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: slate500, size: 24),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: slate900,
          letterSpacing: -0.8,
          height: 1.05,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: slate900,
          letterSpacing: -0.6,
          height: 1.1,
        ),
        displaySmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: slate900,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: slate900,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: slate900,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: slate900,
          letterSpacing: -0.1,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: slate900,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: slate900,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: slate700,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: slate800,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          color: slate700,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: slate500,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: slate900,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: slate700,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: slate500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
