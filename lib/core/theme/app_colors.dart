import 'package:flutter/material.dart';

/// Single source of truth for Gigl brand + tonal palette.
///
/// v2 "soft neo-organic minimalism": cream background, pastel mesh wash,
/// floating geometric patches, frosted glass, high-contrast charcoal pills.
/// Depth comes only from soft tinted shadows, 1px outlines, glass and tonal
/// surfaces (see [GiglTokens]).
abstract final class AppColors {
  // ---------------------------------------------------------------- Light
  static const lightBackground = Color(0xFFFDFBF7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceGlass = Color(0xA6FFFFFF);
  static const lightGlassBorder = Color(0xB3FFFFFF);
  static const lightPrimarySoft = Color(0xFFEFE9FB);
  static const lightOutline = Color(0xFFE8E1D6);
  static const lightInk = Color(0xFF222222);
  static const lightInkMuted = Color(0xFF5C5A66);
  static const lightPrimary = Color(0xFF5B2EC7);
  static const lightPrimaryPressed = Color(0xFF4A22A6);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFC62F3E);

  /// Fixed brand accents: unlike [lightPrimary], these NEVER follow the OS
  /// dynamic-color palette, so the Post pill / wordmark / hub stay vivid
  /// brand purple on high-tier devices with dynamic color enabled.
  static const brandPrimaryLight = Color(0xFF5B2EC7);
  static const brandOnPrimaryLight = Color(0xFFFFFFFF);

  /// Mesh wash (pastel, ~40-55% alpha at draw time).
  static const meshLavenderLight = Color(0xFFE7DEFA);
  static const meshPeachLight = Color(0xFFFADFD0);
  static const meshSageLight = Color(0xFFDDE8D6);
  static const meshButterLight = Color(0xFFF7E7C4);

  /// Patch hues (drawn at 20-40% alpha): terracotta, sage, buttery yellow.
  static const patchTerracotta = Color(0xFFC9684A);
  static const patchSage = Color(0xFF8FA98A);
  static const patchButter = Color(0xFFF2CF66);

  // ------------------------------------------------------------ Ink + wash
  // INK is the weight element: ink pill CTAs, ink-filled selected chips, the
  // floating ink dock, ink circular icon buttons. Ink + one primary accent.
  static const lightOnInk = Color(0xFFFFFFFF);
  static const washTopLight = Color(0xFFE9E2FA);
  static const washBottomLight = Color(0xFFF8EEE9);

  // ----------------------------------------------------------------- Dark
  static const darkBackground = Color(0xFF0F0B1A);
  static const darkSurface = Color(0xFF19132B);
  static const darkSurfaceRaised = Color(0xFF221A38);
  static const darkSurfaceGlass = Color(0x99221A38);
  static const darkGlassBorder = Color(0x1FFFFFFF);
  static const darkOutline = Color(0xFF3A2F5A);
  static const darkInk = Color(0xFFF3F0FB);
  static const darkInkMuted = Color(0xFFB2A9CC);
  static const darkPrimary = Color(0xFF9B7BFF);
  static const darkOnPrimary = Color(0xFF12082E);
  static const darkPrimarySoft = Color(0xFF2A1F4D);
  static const darkError = Color(0xFFF0808C);

  static const brandPrimaryDark = Color(0xFF9B7BFF);
  static const brandOnPrimaryDark = Color(0xFF12082E);

  /// Dark mesh wash (low-contrast so panels stay legible).
  static const meshLavenderDark = Color(0xFF2A1F4D);
  static const meshPeachDark = Color(0xFF3A2230);
  static const meshSageDark = Color(0xFF1E2F2A);
  static const meshButterDark = Color(0xFF3A3020);

  /// Inverted pill: near-white fill with near-black label. Used by ink CTAs
  /// and selected chips in dark mode (a #F3F0FB label on dark fills would
  /// vanish, and vice versa).
  static const darkPillFill = Color(0xFFF3F0FB);
  static const darkOnPillFill = Color(0xFF17122B);

  // Dark mode cannot use a true-black pill (it would vanish): the dock and
  // ink surfaces resolve to surfaceRaised + 1px outline instead, with
  // darkOnInk text.
  static const darkOnInk = Color(0xFFF3F0FB);
  static const washTopDark = Color(0xFF1A1230);
  static const washBottomDark = Color(0xFF0F0B1A);

  // ------------------------------------------------------- Category light
  // NOTE: gigs/saved were darkened one step from the brief (#0F7B5F/#A0670F)
  // because white 12sp labels on their 8%-lightened gradient starts missed
  // 4.5:1 (4.47/4.09). Gated by tool/check_contrast.dart; tonal weight kept.
  static const discoverLight = Color(0xFF5B2EC7);
  static const gigsLight = Color(0xFF0C6E54);
  static const marketLight = Color(0xFFB84A2E);
  static const chatsLight = Color(0xFF1D5FB0);
  static const savedLight = Color(0xFF8F5C0C);
  static const profileLight = Color(0xFF475467);

  // -------------------------------------------------------- Category dark
  static const discoverDark = Color(0xFF9B7BFF);
  static const gigsDark = Color(0xFF3FC6A0);
  static const marketDark = Color(0xFFF08A6A);
  static const chatsDark = Color(0xFF5FA2F0);
  static const savedDark = Color(0xFFE3A94A);
  static const profileDark = Color(0xFF9AA6B8);

  // ---------------------------------------------------------- Hub gradient
  static const hubGradientStart = Color(0xFF6D3FE0);
  static const hubGradientEnd = Color(0xFF4A22A6);

  /// Label/icon drawn *inside* a filled category node. Lives here (inside
  /// `lib/core/theme/`) so `node_data.dart` can reference it without
  /// introducing `Colors.`/`Color(0x` literals outside the theme directory.
  static const nodeOnCategory = Color(0xFFFFFFFF);

  // ------------------------------------------------- Legacy aliases (TODO
  // Phase 4: remove once every screen reads from Theme/tokens instead).
  /// Legacy teal seed. Prefer `Theme.of(context).colorScheme.primary`.
  static const deepTeal = lightPrimary;

  /// Legacy amber. Prefer `context.tokens.saved.base`.
  static const amber = savedLight;

  /// Legacy swipe-pass red. Prefer `Theme.of(context).colorScheme.error`.
  static const passRed = lightError;

  /// Legacy swipe-save green. Prefer `context.tokens.gigs.base`.
  static const saveGreen = gigsLight;
}
