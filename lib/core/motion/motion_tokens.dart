/// Motion parameters for the v3 ambient pass — ALL periods, amplitudes and
/// alphas live here so they can be tuned in one place.
///
/// Rules encoded by these tokens:
/// * Calm/slow/premium: nothing is faster than the 18s comet; no bouncing,
///   flashing, or fast parallax.
/// * Deterministic: any animated value is `base + A * sin(2*pi*t/T + phase)`
///   (or a linear sweep) computed from clock seconds `t` — no randomness.
/// * Non-looping feel: periods are a prime-ish family (14/17/21/26/30/31/…)
///   with distinct phases per element so the composition never visibly
///   repeats.
library;

import 'package:flutter/foundation.dart';

class MotionTokens {
  const MotionTokens._();

  // ---- Shared clock -------------------------------------------------------

  /// Full-screen mesh repaints at 60fps / divisor = 30fps (budget: one
  /// full-screen animated painter per screen). Degradation ladder if frames
  /// drop: 1) raise to 3 (20fps) 2) disable satellites/ripple
  /// 3) static mesh 4) static patches.
  static const int meshTickDivisor = 2;

  // ---- Ambient mesh (animated gradient background) ------------------------

  /// Lissajous drift for one mesh blob:
  /// `center = base + (ax*sin(2πt/periodX + phase), ay*sin(2πt/periodY + phase))`.
  /// Amplitudes are fractions of the canvas size (spec: 12-18%).
  static const List<Lissajous> meshDrift = [
    // lavender (top-left)
    Lissajous(ax: 0.14, ay: 0.12, periodX: 26, periodY: 34, phase: 0.0),
    // peach (right)
    Lissajous(ax: 0.16, ay: 0.14, periodX: 31, periodY: 23, phase: 1.3),
    // sage (bottom-left)
    Lissajous(ax: 0.12, ay: 0.16, periodX: 20, periodY: 40, phase: 2.6),
    // butter (faint, center-top)
    Lissajous(ax: 0.13, ay: 0.11, periodX: 37, periodY: 29, phase: 4.1),
  ];

  /// Neighbor cross-fades: blob colors slowly mix between palette neighbors
  /// (lavender<->peach<->sage). `mix = 0.5 + 0.5*sin(2πt/T + phase)`.
  static const double meshCrossPeriodA = 34; // lavender <-> peach
  static const double meshCrossPhaseA = 0.5;
  static const double meshCrossPeriodB = 40; // peach <-> sage
  static const double meshCrossPhaseB = 2.1;
  static const double meshCrossPeriodC = 29; // sage <-> lavender
  static const double meshCrossPhaseC = 3.7;

  /// Draw alphas: 40-55% light / 25-35% dark (spec ranges).
  static const double meshAlphaLight = 0.50;
  static const double meshAlphaDark = 0.30;

  /// Butter blob is the faint fourth wash.
  static const double meshButterAlphaScale = 0.6;

  // ---- Geometric patches --------------------------------------------------

  /// Drift <= 16dp, rotation +/-6deg, breathe 0.96-1.04 (spec maxima).
  static const double patchDriftMaxDp = 16;
  static const double patchRotationMaxRad = 0.1047; // ~6 degrees
  static const double patchBreatheAmp = 0.04; // scale = 1 +/- amp

  /// Per-patch-index periods (14-30s) and phases; index patches by their
  /// position in the variant preset so neighbors never move in sync.
  static const List<double> patchPeriods = [14, 17, 21, 26, 30];
  static const List<double> patchPhases = [0.0, 1.1, 2.4, 3.9, 5.2];

  /// Independent x/y drift fractions of [patchDriftMaxDp] per index.
  static const List<double> patchDriftX = [1.0, 0.75, 0.88, 0.62, 1.0];
  static const List<double> patchDriftY = [0.62, 1.0, 0.75, 0.88, 0.69];

  /// ONE patch per screen morphs circle <-> rounded squircle by lerping its
  /// corner radius; period/phase of that morph.
  static const double patchMorphPeriod = 26;
  static const double patchMorphPhase = 0.7;

  // ---- Hub orbit rings ----------------------------------------------------

  /// Inner dashed orbit: dashes march clockwise, one revolution ~40s.
  static const double ringDashPeriod = 40;

  /// Outer ring comet: ~70 degree sweep, COUNTER-clockwise, one revolution
  /// ~18s (the fastest motion in the app).
  static const double ringCometPeriod = 18;
  static const double ringCometSweepRad = 1.2217; // ~70 degrees

  /// Comet head glow (droppable #2 if it costs frames).
  static const double ringCometGlowAlpha = 0.16;

  /// Three satellites riding the outer ring at different speeds/phases.
  static const List<double> ringSatellitePeriods = [21, 26, 31];
  static const List<double> ringSatellitePhases = [0.0, 2.1, 4.2];
  static const double ringSatelliteDiameter = 4.5; // 4-5dp dots

  /// Soft ripple expanding hub -> orbit, one every ~6s, primary @ 12%.
  static const double ripplePeriod = 6;
  static const double rippleGrowSeconds = 2.4;
  static const double rippleAlpha = 0.12;
}

/// One Lissajous center path (fractions of canvas for ax/ay, seconds for
/// periods, radians for phase).
@immutable
class Lissajous {
  const Lissajous({
    required this.ax,
    required this.ay,
    required this.periodX,
    required this.periodY,
    required this.phase,
  });

  final double ax;
  final double ay;
  final double periodX;
  final double periodY;
  final double phase;
}
