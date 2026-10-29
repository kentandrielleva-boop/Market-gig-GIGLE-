import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';

/// One accent hue per category, each exposing the same three stops so none
/// looks dull next to the others:
///
/// * [base] — solid fill / icon / connector hue.
/// * [soft] — `base @ 14% alpha` tint for chips, badges, selected rows.
/// * [gradientStart]/[gradientEnd] — `base lightened 8% -> base` for nodes.
@immutable
class GiglCategoryColors {
  const GiglCategoryColors({
    required this.base,
    required this.soft,
    required this.gradientStart,
    required this.gradientEnd,
  });

  factory GiglCategoryColors.fromBase(Color base) {
    return GiglCategoryColors(
      base: base,
      soft: base.withValues(alpha: 0.14),
      gradientStart: Color.lerp(base, Colors.white, 0.08) ?? base,
      gradientEnd: base,
    );
  }

  final Color base;
  final Color soft;
  final Color gradientStart;
  final Color gradientEnd;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  @override
  bool operator ==(Object other) =>
      other is GiglCategoryColors &&
      other.base == base &&
      other.soft == soft &&
      other.gradientStart == gradientStart &&
      other.gradientEnd == gradientEnd;

  @override
  int get hashCode => Object.hash(base, soft, gradientStart, gradientEnd);
}

/// Design tokens resolved per brightness and read via `context.tokens`.
///
/// Radii: sm 12, md 20, lg 28, xl 36, pill 999. Spacing follows a 4-pt scale.
/// Shadows are soft, diffused and tinted (never pure black):
/// e1 = 0 2 4 rgba(34,34,34,.04) + 0 8 24 rgba(91,46,199,.08);
/// e2 = 0 16 40 rgba(91,46,199,.14);
/// eDock = 0 14 36 rgba(34,34,34,.26) (floating dock only).
@immutable
class GiglTokens extends ThemeExtension<GiglTokens> {
  const GiglTokens({
    required this.brightness,
    required this.background,
    required this.surfaceRaised,
    required this.surfaceGlass,
    required this.glassBorder,
    required this.primarySoft,
    required this.outline,
    required this.ink,
    required this.onInk,
    required this.inkMuted,
    required this.primaryPressed,
    required this.brandPrimary,
    required this.brandOnPrimary,
    required this.pillFill,
    required this.onPillFill,
    required this.meshLavender,
    required this.meshPeach,
    required this.meshSage,
    required this.meshButter,
    required this.washTop,
    required this.washBottom,
    required this.dockSurface,
    required this.discover,
    required this.gigs,
    required this.market,
    required this.chats,
    required this.saved,
    required this.profile,
    required this.hubGradientStart,
    required this.hubGradientEnd,
  });

  final Brightness brightness;
  final Color background;
  final Color surfaceRaised;

  /// Frosted-glass fill + 1px border. Max 2 blurred panels per screen, always
  /// inside ClipRRect + RepaintBoundary; solid surface @ 92% fallback.
  final Color surfaceGlass;
  final Color glassBorder;
  final Color primarySoft;
  final Color outline;
  final Color ink;
  final Color onInk;
  final Color inkMuted;
  final Color primaryPressed;

  /// Fixed brand accents immune to the OS dynamic-color override (Post pill,
  /// wordmark, hub).
  final Color brandPrimary;
  final Color brandOnPrimary;

  /// Ink-pill fill + label: charcoal/white in light, INVERTED
  /// (near-white fill, near-black label) in dark. Used by the single ink CTA
  /// and selected chips. The dock instead uses [dockSurface]/[onInk].
  final Color pillFill;
  final Color onPillFill;

  /// Pastel mesh wash hues (drawn ~40-55% alpha) + patch hues (drawn
  /// 20-40% light / 12-20% dark). Shared across brightnesses for patches.
  final Color meshLavender;
  final Color meshPeach;
  final Color meshSage;

  /// Faint fourth mesh wash (drawn at `MotionTokens.meshButterAlphaScale`).
  final Color meshButter;

  /// Vertical gradient wash behind content: washTop -> background ->
  /// washBottom (lavender -> warm peach in light mode). Surfaces float above
  /// it; screens must not set their own background color.
  final Color washTop;
  final Color washBottom;

  /// Floating dock fill: raw [ink] in light mode, [surfaceRaised] (+ 1px
  /// outline, applied by the dock widget) in dark mode.
  final Color dockSurface;
  final GiglCategoryColors discover;
  final GiglCategoryColors gigs;
  final GiglCategoryColors market;
  final GiglCategoryColors chats;
  final GiglCategoryColors saved;
  final GiglCategoryColors profile;
  final Color hubGradientStart;
  final Color hubGradientEnd;

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;
  static const double radiusPill = 999;

  /// 44dp circular header icon buttons.
  static const double iconButtonSize = 44;

  /// 4dp x 36dp sheet drag handle.
  static const double dragHandleWidth = 36;
  static const double dragHandleHeight = 4;

  /// 4-pt scale: `spacing(n) = 4 * n`.
  static double spacing(int n) => 4.0 * n;

  static const _e1 = [
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 4,
      color: Color.fromRGBO(34, 34, 34, 0.04),
    ),
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color.fromRGBO(91, 46, 199, 0.08),
    ),
  ];

  static const _e2 = [
    BoxShadow(
      offset: Offset(0, 16),
      blurRadius: 40,
      color: Color.fromRGBO(91, 46, 199, 0.14),
    ),
  ];

  static const _eDock = [
    BoxShadow(
      offset: Offset(0, 14),
      blurRadius: 36,
      color: Color.fromRGBO(34, 34, 34, 0.26),
    ),
  ];

  List<BoxShadow> get shadowE1 => _e1;
  List<BoxShadow> get shadowE2 => _e2;
  List<BoxShadow> get shadowEDock => _eDock;

  /// Scaffold wash: washTop -> background -> washBottom, vertical.
  LinearGradient get washGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [washTop, background, washBottom],
    stops: const [0.0, 0.55, 1.0],
  );

  LinearGradient get hubGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hubGradientStart, hubGradientEnd],
  );

  GiglCategoryColors categoryFor(String id) {
    return switch (id) {
      'discover' || 'nearby' || 'trending' || 'foryou' || 'filters' => discover,
      'gigs' || 'browse-gigs' || 'mygigs' || 'gig-reviews' => gigs,
      'market' || 'all-items' || 'my-listings' || 'deals' => market,
      'chats' || 'active' || 'requests' || 'archived' || 'calls' => chats,
      'saved' || 'liked-items' || 'collections' || 'history' => saved,
      'profile' ||
      'my-profile' ||
      'ratings' ||
      'settings' ||
      'wallet' => profile,
      _ => discover,
    };
  }

  static final light = GiglTokens(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surfaceRaised: AppColors.lightSurface,
    surfaceGlass: AppColors.lightSurfaceGlass,
    glassBorder: AppColors.lightGlassBorder,
    primarySoft: AppColors.lightPrimarySoft,
    outline: AppColors.lightOutline,
    ink: AppColors.lightInk,
    onInk: AppColors.lightOnInk,
    inkMuted: AppColors.lightInkMuted,
    primaryPressed: AppColors.lightPrimaryPressed,
    brandPrimary: AppColors.brandPrimaryLight,
    brandOnPrimary: AppColors.brandOnPrimaryLight,
    pillFill: AppColors.lightInk,
    onPillFill: AppColors.lightOnInk,
    meshLavender: AppColors.meshLavenderLight,
    meshPeach: AppColors.meshPeachLight,
    meshSage: AppColors.meshSageLight,
    meshButter: AppColors.meshButterLight,
    washTop: AppColors.washTopLight,
    washBottom: AppColors.washBottomLight,
    dockSurface: AppColors.lightInk,
    discover: GiglCategoryColors.fromBase(AppColors.discoverLight),
    gigs: GiglCategoryColors.fromBase(AppColors.gigsLight),
    market: GiglCategoryColors.fromBase(AppColors.marketLight),
    chats: GiglCategoryColors.fromBase(AppColors.chatsLight),
    saved: GiglCategoryColors.fromBase(AppColors.savedLight),
    profile: GiglCategoryColors.fromBase(AppColors.profileLight),
    hubGradientStart: AppColors.hubGradientStart,
    hubGradientEnd: AppColors.hubGradientEnd,
  );

  static final dark = GiglTokens(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surfaceRaised: AppColors.darkSurfaceRaised,
    surfaceGlass: AppColors.darkSurfaceGlass,
    glassBorder: AppColors.darkGlassBorder,
    primarySoft: AppColors.darkPrimarySoft,
    outline: AppColors.darkOutline,
    ink: AppColors.darkInk,
    onInk: AppColors.darkOnInk,
    inkMuted: AppColors.darkInkMuted,
    primaryPressed: AppColors.darkPrimary,
    brandPrimary: AppColors.brandPrimaryDark,
    brandOnPrimary: AppColors.brandOnPrimaryDark,
    pillFill: AppColors.darkPillFill,
    onPillFill: AppColors.darkOnPillFill,
    meshLavender: AppColors.meshLavenderDark,
    meshPeach: AppColors.meshPeachDark,
    meshSage: AppColors.meshSageDark,
    meshButter: AppColors.meshButterDark,
    washTop: AppColors.washTopDark,
    washBottom: AppColors.washBottomDark,
    dockSurface: AppColors.darkSurfaceRaised,
    discover: GiglCategoryColors.fromBase(AppColors.discoverDark),
    gigs: GiglCategoryColors.fromBase(AppColors.gigsDark),
    market: GiglCategoryColors.fromBase(AppColors.marketDark),
    chats: GiglCategoryColors.fromBase(AppColors.chatsDark),
    saved: GiglCategoryColors.fromBase(AppColors.savedDark),
    profile: GiglCategoryColors.fromBase(AppColors.profileDark),
    hubGradientStart: AppColors.hubGradientStart,
    hubGradientEnd: AppColors.hubGradientEnd,
  );

  @override
  GiglTokens copyWith({
    Brightness? brightness,
    Color? background,
    Color? surfaceRaised,
    Color? surfaceGlass,
    Color? glassBorder,
    Color? primarySoft,
    Color? outline,
    Color? ink,
    Color? onInk,
    Color? inkMuted,
    Color? primaryPressed,
    Color? brandPrimary,
    Color? brandOnPrimary,
    Color? pillFill,
    Color? onPillFill,
    Color? meshLavender,
    Color? meshPeach,
    Color? meshSage,
    Color? meshButter,
    Color? washTop,
    Color? washBottom,
    Color? dockSurface,
  }) {
    return GiglTokens(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      glassBorder: glassBorder ?? this.glassBorder,
      primarySoft: primarySoft ?? this.primarySoft,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      inkMuted: inkMuted ?? this.inkMuted,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandOnPrimary: brandOnPrimary ?? this.brandOnPrimary,
      pillFill: pillFill ?? this.pillFill,
      onPillFill: onPillFill ?? this.onPillFill,
      meshLavender: meshLavender ?? this.meshLavender,
      meshPeach: meshPeach ?? this.meshPeach,
      meshSage: meshSage ?? this.meshSage,
      meshButter: meshButter ?? this.meshButter,
      washTop: washTop ?? this.washTop,
      washBottom: washBottom ?? this.washBottom,
      dockSurface: dockSurface ?? this.dockSurface,
      discover: discover,
      gigs: gigs,
      market: market,
      chats: chats,
      saved: saved,
      profile: profile,
      hubGradientStart: hubGradientStart,
      hubGradientEnd: hubGradientEnd,
    );
  }

  @override
  GiglTokens lerp(ThemeExtension<GiglTokens>? other, double t) {
    if (other is! GiglTokens) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    GiglCategoryColors lerpCat(GiglCategoryColors a, GiglCategoryColors b) {
      return GiglCategoryColors(
        base: lerpColor(a.base, b.base),
        soft: lerpColor(a.soft, b.soft),
        gradientStart: lerpColor(a.gradientStart, b.gradientStart),
        gradientEnd: lerpColor(a.gradientEnd, b.gradientEnd),
      );
    }

    return GiglTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: lerpColor(background, other.background),
      surfaceRaised: lerpColor(surfaceRaised, other.surfaceRaised),
      surfaceGlass: lerpColor(surfaceGlass, other.surfaceGlass),
      glassBorder: lerpColor(glassBorder, other.glassBorder),
      primarySoft: lerpColor(primarySoft, other.primarySoft),
      outline: lerpColor(outline, other.outline),
      ink: lerpColor(ink, other.ink),
      onInk: lerpColor(onInk, other.onInk),
      inkMuted: lerpColor(inkMuted, other.inkMuted),
      primaryPressed: lerpColor(primaryPressed, other.primaryPressed),
      brandPrimary: lerpColor(brandPrimary, other.brandPrimary),
      brandOnPrimary: lerpColor(brandOnPrimary, other.brandOnPrimary),
      pillFill: lerpColor(pillFill, other.pillFill),
      onPillFill: lerpColor(onPillFill, other.onPillFill),
      meshLavender: lerpColor(meshLavender, other.meshLavender),
      meshPeach: lerpColor(meshPeach, other.meshPeach),
      meshSage: lerpColor(meshSage, other.meshSage),
      meshButter: lerpColor(meshButter, other.meshButter),
      washTop: lerpColor(washTop, other.washTop),
      washBottom: lerpColor(washBottom, other.washBottom),
      dockSurface: lerpColor(dockSurface, other.dockSurface),
      discover: lerpCat(discover, other.discover),
      gigs: lerpCat(gigs, other.gigs),
      market: lerpCat(market, other.market),
      chats: lerpCat(chats, other.chats),
      saved: lerpCat(saved, other.saved),
      profile: lerpCat(profile, other.profile),
      hubGradientStart: lerpColor(hubGradientStart, other.hubGradientStart),
      hubGradientEnd: lerpColor(hubGradientEnd, other.hubGradientEnd),
    );
  }
}

/// `Theme.of(context)` shorthand: `context.tokens`.
extension GiglThemeX on BuildContext {
  GiglTokens get tokens =>
      Theme.of(this).extension<GiglTokens>() ?? GiglTokens.light;
}
