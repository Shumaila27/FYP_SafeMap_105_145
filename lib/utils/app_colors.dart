import 'package:flutter/material.dart';

class AppColor {
  // ===== PROFESSIONAL TEAL COLOR PALETTE =====

  // Primary Teal Colors - Main brand identity
  static const Color teal50 = Color(0xFFF0FDFA); // Lightest
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6); // Primary
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A); // Darkest

  // Safety & Alert Colors
  static const Color safetyGreen = Color(0xFF10B981);
  static const Color alertOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFFCD34D);

  // Neutral Colors for text and backgrounds
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // ===== THEME-AWARE COLOR GETTERS =====

  // Container colors for cards and sections
  static Color getContainerBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral800 : neutral50;
  }

  static Color getContainerBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral700 : neutral200;
  }

  // Interactive colors for buttons and controls
  static Color getInteractivePrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? teal400 : teal500;
  }

  static Color getInteractiveSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? teal600 : teal600;
  }

  // Icon colors
  static Color getIconPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? teal300 : teal500;
  }

  static Color getIconSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral400 : neutral600;
  }

  // Text colors with proper contrast
  static Color getTextPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral100 : neutral900;
  }

  static Color getTextSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral300 : neutral600;
  }

  static Color getTextTertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral400 : neutral500;
  }

  // Gradient colors for headers and accents
  static List<Color> getPrimaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? [teal600, teal700, teal800] : [teal400, teal500, teal600];
  }

  static List<Color> getSecondaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [teal700.withValues(alpha: 0.8), teal800.withValues(alpha: 0.8)]
        : [teal100.withValues(alpha: 0.6), teal200.withValues(alpha: 0.6)];
  }

  // Safety feature colors
  static Color getSafeZoneColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? safetyGreen : safetyGreen;
  }

  static Color getAlertColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? alertOrange : alertOrange;
  }

  static Color getDangerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dangerRed : dangerRed;
  }

  // ===== LEGACY COMPATIBILITY =====

  // Static colors for backward compatibility
  static final Color appPrimary = Colors.teal[100]!;
  static final Color appSecondary = Colors.teal[400]!;
  static const Color appText = Colors.black;
  static const Color appBackground = Colors.white;

  // Theme-aware colors - use these for proper dark mode support
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getOnSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  // Static brand colors for gradients and accents
  static const Color brandPrimary = Color(0xFF14B8A6);
  static const Color brandSecondary = Color(0xFF2DD4BF);
  static const Color brandLight = Color(0xFF5EEAD4);
}
