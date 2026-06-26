import 'package:flutter/material.dart';

/// Design system v4 for Artemis Business OS Ã¢â‚¬â€ full light + dark theme.
///
/// Identity:
///   - Brand: indigo (#4F46E5) Ã¢â€ â€™ violet (#7C3AED)
///   - Accent: cyan (#06B6D4) for AI / futuristic highlights
class AppTheme {
  // ===== Brand (same in both themes) =====
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color accentColor = Color(0xFF7C3AED);
  static const Color cyanColor = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFFCFFAFE);

  // ===== Semantic (theme-aware) =====
  // Light values (default, used in const contexts)
  static const Color successColor = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerColor = Color(0xFFF43F5E);
  static const Color dangerLight = Color(0xFFFFE4E6);
  static const Color infoColor = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Legacy aliases (used as const)
  static const Color backgroundColor = slate50;
  static const Color surfaceColor = Colors.white;
  static const Color surfaceMuted = slate50;
  static const Color borderColor = slate200;
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate600;
  static const Color textTertiary = slate500;

  // Dark variants (more vivid for dark surfaces)
  static const Color successDark = Color(0xFF34D399);
  static const Color successDarkBg = Color(0xFF064E3B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningDarkBg = Color(0xFF78350F);
  static const Color dangerDark = Color(0xFFFB7185);
  static const Color dangerDarkBg = Color(0xFF881337);
  static const Color infoDark = Color(0xFF38BDF8);
  static const Color infoDarkBg = Color(0xFF0C4A6E);

  // ===== Light neutrals =====
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

  // ===== Dark surface palette =====
  static const Color darkBg = Color(0xFF0B0F1A);
  static const Color darkSurface = Color(0xFF131825);
  static const Color darkSurfaceElevated = Color(0xFF1B2233);
  static const Color darkBorder = Color(0xFF252D40);
  static const Color darkBorderSubtle = Color(0xFF1E2538);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextSubtle = Color(0xFF64748B);

  // Theme-aware helpers (resolves based on brightness)
  static Color resolveBackground(Brightness b) =>
      b == Brightness.dark ? darkBg : slate50;
  static Color resolveSurface(Brightness b) =>
      b == Brightness.dark ? darkSurface : Colors.white;
  static Color resolveSurfaceMuted(Brightness b) =>
      b == Brightness.dark ? darkSurfaceElevated : slate50;
  static Color resolveBorder(Brightness b) =>
      b == Brightness.dark ? darkBorder : slate200;
  static Color resolveTextPrimary(Brightness b) =>
      b == Brightness.dark ? darkText : slate900;
  static Color resolveTextSecondary(Brightness b) =>
      b == Brightness.dark ? darkTextMuted : slate600;
  static Color resolveTextTertiary(Brightness b) =>
      b == Brightness.dark ? darkTextSubtle : slate500;
  static Color resolveSuccess(Brightness b) =>
      b == Brightness.dark ? successDark : successColor;
  static Color resolveSuccessBg(Brightness b) =>
      b == Brightness.dark ? successDarkBg : successLight;
  static Color resolveWarning(Brightness b) =>
      b == Brightness.dark ? warningDark : warningColor;
  static Color resolveWarningBg(Brightness b) =>
      b == Brightness.dark ? warningDarkBg : warningLight;
  static Color resolveDanger(Brightness b) =>
      b == Brightness.dark ? dangerDark : dangerColor;
  static Color resolveDangerBg(Brightness b) =>
      b == Brightness.dark ? dangerDarkBg : dangerLight;
  static Color resolveInfo(Brightness b) =>
      b == Brightness.dark ? infoDark : infoColor;
  static Color resolveInfoBg(Brightness b) =>
      b == Brightness.dark ? infoDarkBg : infoLight;

  // ===== Spacing scale =====
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

  // ===== Radius =====
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radiusFull = 999;

  // ===== Motion =====
  static const Duration durFast = Duration(milliseconds: 150);
  static const Duration durBase = Duration(milliseconds: 250);
  static const Duration durSlow = Duration(milliseconds: 400);
  static const Curve curveSpring = Cubic(0.16, 1, 0.3, 1);
  static const Curve curveEase = Cubic(0.4, 0, 0.2, 1);

  // ===== Gradients (same in both themes for vibrancy) =====
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

  static const LinearGradient gradientDarkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF7C3AED)],
    stops: [0.0, 0.6, 1.0],
  );

  // Aliases (light/dark)
  static LinearGradient get gradientHeader => gradientAurora;

  // ===== Shadows (light only; dark uses black with higher opacity) =====
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

  // Legacy constant shadows (use brightness-aware versions in widgets)
  static const List<BoxShadow> elevationLg = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> elevationXl = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  // ===== Theme builders =====
  static ThemeData lightTheme() => _buildTheme(Brightness.light);

  static ThemeData darkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = resolveBackground(brightness);
    final surface = resolveSurface(brightness);
    final border = resolveBorder(brightness);
    final textPrim = resolveTextPrimary(brightness);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.white,
              secondary: accentColor,
              onSecondary: Colors.white,
              tertiary: cyanColor,
              error: dangerDark,
              onError: Colors.white,
              surface: darkSurface,
              onSurface: darkText,
              surfaceContainerHighest: darkSurfaceElevated,
            )
          : const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              secondary: accentColor,
              onSecondary: Colors.white,
              tertiary: successColor,
              error: dangerColor,
              onError: Colors.white,
              surface: Colors.white,
              onSurface: slate900,
              surfaceContainerHighest: slate100,
            ),
      scaffoldBackgroundColor: bg,
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
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: surface,
        foregroundColor: textPrim,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? darkTextMuted : slate700),
        titleTextStyle: TextStyle(
          color: textPrim,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceElevated : slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? darkTextSubtle : slate400,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: isDark ? darkTextMuted : slate600,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: isDark ? darkTextMuted : slate500,
        suffixIconColor: isDark ? darkTextMuted : slate500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? dangerDark : dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark ? dangerDark : dangerColor,
            width: 2,
          ),
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
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
          foregroundColor: textPrim,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(color: border, width: 1.2),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        extendedTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurfaceElevated : slate100,
        selectedColor: primaryLight,
        labelStyle: TextStyle(
          color: isDark ? darkTextMuted : slate700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? primaryColor : primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? darkBorderSubtle : slate200,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSurfaceElevated : slate900,
        contentTextStyle: TextStyle(
          color: isDark ? darkText : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: TextStyle(
          color: textPrim,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? darkTextMuted : slate700,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        showDragHandle: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? darkTextMuted : slate500,
        textColor: textPrim,
        titleTextStyle: TextStyle(
          color: textPrim,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: isDark ? darkTextMuted : slate500,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: isDark ? darkTextMuted : slate700,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: isDark ? darkTextMuted : slate500, size: 24),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: textPrim,
          letterSpacing: -0.8,
          height: 1.05,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrim,
          letterSpacing: -0.6,
          height: 1.1,
        ),
        displaySmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrim,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textPrim,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrim,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrim,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrim,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrim,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? darkTextMuted : slate700,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: isDark ? darkText : slate800,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          color: isDark ? darkTextMuted : slate700,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: isDark ? darkTextSubtle : slate500,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrim,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? darkTextMuted : slate700,
        ),
        labelSmall: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isDark ? darkTextSubtle : slate500,
        ),
      ),
    );
  }
}

/// Box shadows compatibility (legacy)
class AppShadows {
  AppShadows._();
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x08000000), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

/// Gradients compatibility (legacy)
class AppGradients {
  AppGradients._();
  static LinearGradient get headerBar => AppTheme.gradientHeader;
}
