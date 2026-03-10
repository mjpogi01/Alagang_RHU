import 'package:flutter/material.dart';

/// Alagang RHU app colors and theme (Tagalog-first, accessible).
class AppTheme {
  AppTheme._();

  // Spacing scale (base 4px) — use these for consistent padding/margins
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacingRadiusSm = 8;
  static const double spacingRadiusMd = 12;

  /// Space between a section title and its content (use for all sections).
  static const double sectionTitleToContent = spacingMd;

  // Primary & header
  static const Color headerBlueLight = Color(0xFFB8D4E8);
  static const Color headerBlue = Color(0xFF7EB8DA);
  static const Color primaryBlue = Color(0xFF5A9BC4);
  /// Dark green header (home screen app bar)
  static const Color headerDarkGreen = Color(0xFF1B5E20);
  /// Teal/green for active nav and slideshow accent (matches design)
  static const Color accentTeal = Color(0xFF2E7D32);

  /// Main background gradient colors (deep teal-black to forest green).
  static const Color bgGradientStart = Color(0xFF0D2B24);
  static const Color bgGradientMid = Color(0xFF1A4F3E);
  static const Color bgGradientEnd = Color(0xFF0D2B24);

  // Surfaces (clean white — whole app)
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceCream = Color(0xFFF5F2EB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color searchBarBackground = Color(0xFFF5F5F5);
  static const Color bannerLight = Color(0xFFF8F8F8);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Text
  static const Color textPrimary = Color(0xFF3D3D3D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF8E8E8E);

  // Service / calendar accent colors (PDF: Buntis pink, Bata green, Adolescent blue, Adult orange, Elderly purple)
  static const Color accentSerbisyo = Color(0xFF5A9BC4);
  static const Color accentBakuna = Color(0xFF6BBF8A);
  static const Color accentBulletin = Color(0xFFE89B5C);
  static const Color accentEmergency = Color(0xFFD45B5B);
  static const Color buntisPink = Color(0xFFE8A4B8);
  static const Color pediatricGreen = Color(0xFF6BBF8A);
  static const Color adolescentBlue = Color(0xFF5A9BC4);
  static const Color adultOrange = Color(0xFFE89B5C);
  static const Color elderlyPurple = Color(0xFF9B7EC4);

  // Notification badge
  static const Color notificationBadge = Color(0xFFE07C4C);

  /// Icon container background (header circles) — #F4F6F8
  static const Color iconContainerBackground = Color(0xFFF4F6F8);

  /// Modal/Reminders card gradient (matches Reminders layout)
  static const Color modalCardGradientTop = Color(0xFFE8EEF5);
  static const Color modalCardGradientBottom = Color(0xFFF2F6F0);
  static const Color modalSheetBackgroundTop = Color(0xFFF0F5FA);
  static const Color modalSheetBackgroundBottom = Color(0xFFF8FAF5);
  static const Color dateAccentGreen = Color(0xFF5A9B6E);

  // Traditional calendar (pixel-faithful to reference: dark blue, red, white)
  static const Color calendarBorderDark = Color(0xFF1A3A5C);   // thick borders, weekday text
  static const Color calendarBorderThin = Color(0xFF2E5090);   // thin grid lines
  static const Color calendarBannerRed = Color(0xFFB71C1C);     // JANUARY banner background
  static const Color calendarBannerRedLine = Color(0xFFC62828); // thin red line under banner
  static const Color calendarSundayRed = Color(0xFFB71C1C);   // Sunday numbers + SUN
  static const Color calendarMonthBannerText = Color(0xFFFFFFFF); // JANUARY text (white)
  static const Color calendarSmallText = Color(0xFF757575);     // faint labels under dates
  static const Color calendarPaperBg = Color(0xFFFFFFFF);      // white

  /// Extra bottom padding so scroll content can scroll above the floating nav bar.
  static const double floatingNavBarClearance = 96;

  /// Base width for layout scaling (typical small phone). Smaller screens scale down.
  static const double _designWidth = 360;

  /// Scale factor for current screen (0.82–1.1). Use for fonts, heights, and spacing on small screens.
  static double scaleFactor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 0) return 1.0;
    return (w / _designWidth).clamp(0.82, 1.1);
  }

  /// Scale a value by screen width so layout stays proportionate on small screens.
  static double scale(BuildContext context, double value) =>
      value * scaleFactor(context);

  /// Modern, standout style for the "Alagang RHU" app title. Pass context to scale on small screens.
  static TextStyle appTitleStyle({
    required Color color,
    double fontSize = 26,
    List<Shadow>? shadows,
    BuildContext? context,
  }) {
    final size = context != null ? fontSize * scaleFactor(context) : fontSize;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
      height: 1.08,
      color: color,
      shadows: shadows,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceWhite,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingRadiusMd)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchBarBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(spacingRadiusMd)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacingRadiusMd),
          borderSide: BorderSide(color: searchBarBackground),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
