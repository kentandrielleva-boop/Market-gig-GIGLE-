import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/theme/app_typography.dart';

ColorScheme _lightScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    primaryContainer: AppColors.lightPrimarySoft,
    onPrimaryContainer: AppColors.lightPrimary,
    secondary: AppColors.lightPrimary,
    onSecondary: AppColors.lightOnPrimary,
    secondaryContainer: AppColors.lightPrimarySoft,
    onSecondaryContainer: AppColors.lightPrimary,
    tertiary: AppColors.savedLight,
    onTertiary: AppColors.lightOnPrimary,
    tertiaryContainer: AppColors.lightPrimarySoft,
    onTertiaryContainer: AppColors.savedLight,
    error: AppColors.lightError,
    onError: Colors.white,
    errorContainer: Color(0xFFF9DDE1),
    onErrorContainer: Color(0xFF7A1F28),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightInk,
    surfaceContainerHighest: AppColors.lightSurface,
    onSurfaceVariant: AppColors.lightInkMuted,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutline,
    scrim: AppColors.lightInk,
    inverseSurface: AppColors.lightInk,
    onInverseSurface: AppColors.lightBackground,
    inversePrimary: AppColors.darkPrimary,
    shadow: AppColors.lightPrimary,
    surfaceTint: AppColors.lightPrimary,
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    primaryContainer: AppColors.darkSurfaceRaised,
    onPrimaryContainer: AppColors.darkPrimary,
    secondary: AppColors.darkPrimary,
    onSecondary: AppColors.darkOnPrimary,
    secondaryContainer: AppColors.darkSurfaceRaised,
    onSecondaryContainer: AppColors.darkPrimary,
    tertiary: AppColors.savedDark,
    onTertiary: AppColors.darkOnPrimary,
    tertiaryContainer: AppColors.darkSurfaceRaised,
    onTertiaryContainer: AppColors.savedDark,
    error: AppColors.darkError,
    onError: AppColors.darkOnPrimary,
    errorContainer: Color(0xFF4A1620),
    onErrorContainer: Color(0xFFF6C4CA),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkInk,
    surfaceContainerHighest: AppColors.darkSurfaceRaised,
    onSurfaceVariant: AppColors.darkInkMuted,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutline,
    scrim: Colors.black,
    inverseSurface: AppColors.darkInk,
    onInverseSurface: AppColors.darkBackground,
    inversePrimary: AppColors.lightPrimary,
    shadow: AppColors.lightPrimary,
    surfaceTint: AppColors.darkPrimary,
  );
}

ThemeData buildGiglTheme({
  required Brightness brightness,
  required DeviceTier tier,
  ColorScheme? dynamicScheme,
}) {
  final isDark = brightness == Brightness.dark;
  final tokens = isDark ? GiglTokens.dark : GiglTokens.light;
  var scheme = isDark ? _darkScheme() : _lightScheme();

  // High-tier devices keep the OS dynamic palette when available, but brand
  // tokens (category hues, radii, tinted shadows) still come from GiglTokens.
  // A palette whose brightness disagrees with the requested one is ignored:
  // installing it would trip the ThemeData/ColorScheme brightness assertion.
  if (tier == DeviceTier.high &&
      dynamicScheme != null &&
      dynamicScheme.brightness == brightness) {
    scheme = dynamicScheme.copyWith(
      tertiary: isDark ? AppColors.savedDark : AppColors.savedLight,
    );
  }

  final textTheme = AppTypography.textTheme(scheme);
  final high = tier == DeviceTier.high;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    fontFamily: AppTypography.fontFamily,
    textTheme: textTheme,
    extensions: [tokens],
    // Cards: pure-white surface, radius lg (xl for hero cards, applied at
    // the call site), 1px outline @ 60%, soft diffused e1.
    cardTheme: CardThemeData(
      elevation: high ? 1 : 0,
      shadowColor: AppColors.lightPrimary.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusLg),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    // Chips: UNSELECTED = surface + 1px outline + ink 600 text; SELECTED =
    // inverted-pill fill + label (charcoal/white light, near-white fill with
    // near-black label in dark) + onInk checkmark. Selected label color is
    // applied by the filter-chip widgets (ChipTheme carries one labelStyle).
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: tokens.pillFill,
      checkmarkColor: tokens.onPillFill,
      labelStyle: textTheme.labelLarge?.copyWith(color: tokens.ink),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: tokens.onInk),
      side: BorderSide(color: scheme.outline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    // Buttons: filled primary = solid + white 600 label + pill + tinted
    // shadow; secondary (tonal/elevated/outlined) = primarySoft + primary.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
        ),
        minimumSize: const Size.fromHeight(48),
        elevation: high ? 2 : 0,
        shadowColor: scheme.primary.withValues(alpha: 0.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
        ),
        elevation: 0,
        side: BorderSide(color: scheme.outline, width: 1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
        ),
        side: BorderSide(color: scheme.outline, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
          ),
        ),
      ),
    ),
    // Inputs: filled surface, 1px outline, primary 2px on focus.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusMd),
        borderSide: BorderSide(color: scheme.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusMd),
        borderSide: BorderSide(color: scheme.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusMd),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusMd),
        borderSide: BorderSide(color: scheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusMd),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(scheme.surface),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
      hintStyle: WidgetStatePropertyAll(
        textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    ),
    // App bar: transparent over the tinted background, wordmark in primary.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: high ? 2 : 0,
      elevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: high ? 3 : 0,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GiglTokens.radiusXl),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      dragHandleSize: const Size(
        GiglTokens.dragHandleWidth,
        GiglTokens.dragHandleHeight,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      indicatorColor: scheme.primary,
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Legacy entry point (light only). Prefer [buildGiglTheme] with an explicit
/// [Brightness]. Kept so previews/tests keep compiling during the migration.
ThemeData buildAppTheme({
  required DeviceTier tier,
  ColorScheme? dynamicScheme,
}) {
  return buildGiglTheme(
    brightness: Brightness.light,
    tier: tier,
    dynamicScheme: dynamicScheme,
  );
}

double surfaceElevation(DeviceTier tier) => tier == DeviceTier.high ? 1 : 0;
