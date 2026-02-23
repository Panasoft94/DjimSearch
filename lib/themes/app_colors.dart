import 'package:flutter/material.dart';

/// Palette de couleurs personnalisée pour DjimSearch
/// Inspirée du design minimaliste de Google avec une touche moderne
class AppColors {
  // Couleurs primaires - Bleu élégant et modéré
  static const Color primary = Color(0xFF1F7FFF);
  static const Color primaryLight = Color(0xFF4A9FFF);
  static const Color primaryDark = Color(0xFF0052CC);

  // Couleurs secondaires - Accent rouge léger
  static const Color secondary = Color(0xFFEA4335);
  static const Color secondaryLight = Color(0xFFF08080);
  static const Color secondaryDark = Color(0xFFC41C3B);

  // Couleurs tertiaires - Accent orange
  static const Color tertiary = Color(0xFFFBBC04);
  static const Color tertiaryLight = Color(0xFFFFD26A);
  static const Color tertiaryDark = Color(0xFFF8A804);

  // Surfaces neutres
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFF0F0F0);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFFAFAFA);

  // Textes
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF80868B);

  // Borders et outlines
  static const Color outline = Color(0xFFDADCE0);
  static const Color outlineVariant = Color(0xFFF1F3F4);

  // États
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
  static const Color errorLight = Color(0xFFFCE4E4);

  // Transparences
  static const Color scrim = Color(0x00000000);
  static const Color shadow = Color(0x1F000000);

  // Mode sombre (optionnel pour phase future)
  static const Color darkPrimary = Color(0xFF8AB4F8);
  static const Color darkSurface = Color(0xFF202124);
  static const Color darkBackground = Color(0xFF121212);
}

/// Extension pour accéder facilement aux couleurs
extension ColorSchemeExtension on ColorScheme {
  Color get googleBlue => AppColors.primary;
  Color get googleRed => AppColors.secondary;
  Color get googleYellow => AppColors.tertiary;
}

