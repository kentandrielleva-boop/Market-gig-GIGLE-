import 'package:flutter/material.dart';

/// Single font family for the whole app.
///
/// The repo already sets Roboto in [buildAppTheme], so we keep it (per brief:
/// keep the current family; Poppins via google_fonts only when none is set).
/// This file locks weights + minimum sizes:
/// display 28/700 (screen titles) | title 20/700 | label/button 14/600 |
/// body 14-16/400 | caption 12/500 | overline 12/600 UPPERCASE +1.2 spacing.
/// Body >= 14sp, captions >= 12sp.
abstract final class AppTypography {
  static const String fontFamily = 'Roboto';

  /// Small uppercase letter-spaced section label (12sp, 600, +1.2 spacing).
  /// Callers uppercase the text (`label.toUpperCase()`); letter casing is a
  /// locale-sensitive widget concern, not a style concern.
  static TextStyle overline(ColorScheme scheme, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1.35,
      color: color ?? scheme.onSurfaceVariant,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true).textTheme;
    TextStyle? em(
      TextStyle? s, {
      required double size,
      required FontWeight weight,
      Color? color,
      double? height,
      double? tracking,
    }) => (s ?? const TextStyle()).copyWith(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? scheme.onSurface,
      height: height ?? 1.35,
      letterSpacing: tracking,
    );

    return TextTheme(
      displaySmall: em(
        base.displaySmall,
        size: 28,
        weight: FontWeight.w700,
        tracking: -0.5,
      ),
      headlineSmall: em(base.headlineSmall, size: 22, weight: FontWeight.w700),
      headlineMedium: em(
        base.headlineMedium,
        size: 24,
        weight: FontWeight.w700,
      ),
      titleLarge: em(base.titleLarge, size: 20, weight: FontWeight.w700),
      titleMedium: em(base.titleMedium, size: 16, weight: FontWeight.w700),
      titleSmall: em(base.titleSmall, size: 14, weight: FontWeight.w700),
      labelLarge: em(base.labelLarge, size: 14, weight: FontWeight.w600),
      labelMedium: em(base.labelMedium, size: 12, weight: FontWeight.w600),
      labelSmall: em(base.labelSmall, size: 12, weight: FontWeight.w500),
      bodyLarge: em(base.bodyLarge, size: 16, weight: FontWeight.w400),
      bodyMedium: em(base.bodyMedium, size: 14, weight: FontWeight.w400),
      bodySmall: em(
        base.bodySmall,
        size: 12,
        weight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
