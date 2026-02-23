/// Constantes d'espacements pour maintenir la cohérence dans l'UI
/// Basé sur une échelle 4px (design system standard)
class Spacing {
  // Pequeños espacios
  static const double xs = 4.0;      // 4px - très petit (entre éléments)
  static const double sm = 8.0;      // 8px - petit
  static const double md = 12.0;     // 12px - moyen-petit
  static const double lg = 16.0;     // 16px - moyen
  static const double xl = 24.0;     // 24px - grand
  static const double xxl = 32.0;    // 32px - très grand
  static const double xxxl = 48.0;   // 48px - énorme

  // Espacements pour listas
  static const double listItemPadding = 16.0;
  static const double listVerticalSpacing = 8.0;

  // Espacements pour formulaires
  static const double formVerticalSpacing = 20.0;
  static const double formHorizontalPadding = 16.0;

  // Padding estándar
  static const double appPadding = 16.0;
  static const double appHorizontalPadding = 16.0;
  static const double appVerticalPadding = 12.0;

  // Border radii
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 24.0;
  static const double radiusCircle = 999.0;
}

/// Radii standards pour les widgets
class BorderRadii {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double xLarge = 16.0;
  static const double round = 24.0;
  static const double circle = 999.0;
}

/// Elevations pour les shadows
class Elevations {
  static const double none = 0.0;
  static const double small = 1.0;
  static const double medium = 4.0;
  static const double large = 8.0;
  static const double xLarge = 12.0;
  static const double xxLarge = 16.0;
}

/// Durées d'animation standard
class AnimationDurations {
  static const Duration veryFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration entrance = Duration(milliseconds: 1000);
}

