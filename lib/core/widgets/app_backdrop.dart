import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';
import 'package:marketplace_gig/core/motion/motion_tokens.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';

/// Reusable scaffold background for EVERY screen; screens never set their
/// own background.
///
/// Layer 1: cream (light) / near-black (dark) base.
/// Layer 2: MESH — 4 soft radial gradients (lavender top-left, peach right,
/// sage bottom-left, faint butter bottom-right) whose CENTERS drift on slow
/// Lissajous paths and whose colors cross-fade between palette neighbors
/// (all parameters in [MotionTokens]). Repaints from the shared ambient
/// clock's THROTTLED signal (~30fps; one full-screen animated painter per
/// screen) — deterministic in clock seconds, no widget rebuilds.
/// Layer 3: PATCHES — at most 4 geometric shapes per [AppBackdropVariant]
/// preset (circle, semicircle, arch, pill, rounded triangle) in
/// terracotta/sage/butter at 20-40% alpha (12-20% dark), placed by
/// fractional coordinates, partly bleeding off edges, rotated slightly,
/// each with its own slow drift/rotation/breathe motion.
/// Never centered behind body text; text sits on clear or surface zones.
///
/// Decoration only: painters are [IgnorePointer]-safe (painters override
/// `hitTest` to false so hits pass straight through to the child), excluded
/// from semantics, and each layer sits inside its own [RepaintBoundary] so
/// content repaints independently.
enum AppBackdropVariant { hub, list, detail, form }

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.variant = AppBackdropVariant.list,
  });

  final Widget child;
  final AppBackdropVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Read once per build: a stable MotionRead (never notifies dependents),
    // so route/motion-mode changes rebuild this widget but clock ticks don't.
    final motion = AmbientClock.motionOf(context);
    // NOTE: the base fill is painted inside [_MeshPainter] (drawPaint), not
    // via DecoratedBox/ColoredBox: a bg-painted box between a ListTile and
    // its Material ancestor trips Flutter's invisible-splash assertion.
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshPainter(tokens: tokens, motion: motion),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _PatchPainter(
              tokens: tokens,
              variant: variant,
              motion: motion,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Four soft radial washes. One shader per blob, transparent edges.
///
/// Animated: Lissajous center drift + neighbor color cross-fade, driven by
/// [MotionRead.slow] (the clock's throttled ~30fps signal).
class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.tokens, required this.motion})
    : super(repaint: motion.slow);

  final GiglTokens tokens;
  final MotionRead motion;

  /// Static base centers (fraction of canvas) for lavender/peach/sage/butter.
  static const List<Offset> _base = [
    Offset(0.08, 0.06), // lavender, top-left
    Offset(1.00, 0.42), // peach, right-middle
    Offset(0.02, 0.94), // sage, bottom-left
    Offset(0.62, 0.92), // butter (faint), bottom-right
  ];

  /// Radii as a fraction of canvas width per blob.
  static const List<double> _radius = [0.75, 0.70, 0.72, 0.60];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Opaque base (see AppBackdrop note about DecoratedBox + ListTile).
    canvas.drawPaint(Paint()..color = tokens.background);
    final t = motion.seconds();
    final alpha = tokens.brightness == Brightness.dark
        ? MotionTokens.meshAlphaDark
        : MotionTokens.meshAlphaLight;
    // Neighbor cross-fades (lavender<->peach<->sage); butter stays faint.
    final colors = <Color>[
      _mix(
        tokens.meshLavender,
        tokens.meshPeach,
        t,
        MotionTokens.meshCrossPeriodA,
        MotionTokens.meshCrossPhaseA,
      ),
      _mix(
        tokens.meshPeach,
        tokens.meshSage,
        t,
        MotionTokens.meshCrossPeriodB,
        MotionTokens.meshCrossPhaseB,
      ),
      _mix(
        tokens.meshSage,
        tokens.meshLavender,
        t,
        MotionTokens.meshCrossPeriodC,
        MotionTokens.meshCrossPhaseC,
      ),
      tokens.meshButter,
    ];

    for (var i = 0; i < colors.length; i++) {
      final drift = MotionTokens.meshDrift[i];
      final dx =
          _base[i].dx +
          drift.ax * math.sin(2 * math.pi * t / drift.periodX + drift.phase);
      final dy =
          _base[i].dy +
          drift.ay * math.sin(2 * math.pi * t / drift.periodY + drift.phase);
      final a = i == 3 ? alpha * MotionTokens.meshButterAlphaScale : alpha;
      _blob(
        canvas,
        size,
        center: Offset(size.width * dx, size.height * dy),
        radius: size.width * _radius[i],
        color: colors[i].withValues(alpha: a),
      );
    }
  }

  /// Slow cross-fade between two palette neighbors: mix in [0, 1].
  static Color _mix(Color a, Color b, double t, double period, double phase) {
    final m = 0.5 + 0.5 * math.sin(2 * math.pi * t / period + phase);
    return Color.lerp(a, b, m)!;
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  /// Decorative: never intercepts hit tests (the child underneath does).
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.tokens != tokens || oldDelegate.motion != motion;
}

enum _PatchShape { circle, semicircle, arch, pill, triangle }

/// One floating patch: fractional placement, slight rotation, bleeds off an
/// edge. Geometry is const per variant preset; motion (drift/rotation/
/// breathe, plus an optional corner-radius morph) is computed per index from
/// [MotionTokens] so no two patches ever move in sync.
@immutable
class _Patch {
  const _Patch({
    required this.shape,
    required this.color,
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotation,
    required this.alpha,
    this.morph = false,
  });

  final _PatchShape shape;
  final Color color;

  /// Center as a fraction of canvas size (may exceed [0,1] to bleed off).
  final double dx;
  final double dy;

  /// Diameter as a fraction of canvas width.
  final double size;
  final double rotation;
  final double alpha;

  /// The ONE patch per screen allowed to slowly morph (circle <-> rounded
  /// squircle by lerping corner radii); others stay geometric.
  final bool morph;
}

const _hubPatches = [
  _Patch(
    shape: _PatchShape.pill,
    color: AppColors.patchTerracotta,
    dx: -0.12,
    dy: 0.10,
    size: 0.42,
    rotation: 0.5,
    alpha: 0.30,
  ),
  _Patch(
    shape: _PatchShape.circle,
    color: AppColors.patchSage,
    dx: 1.08,
    dy: 0.30,
    size: 0.36,
    rotation: 0.0,
    alpha: 0.30,
    morph: true,
  ),
  _Patch(
    shape: _PatchShape.arch,
    color: AppColors.patchButter,
    dx: 0.06,
    dy: 1.02,
    size: 0.30,
    rotation: -0.2,
    alpha: 0.32,
  ),
];

const _listPatches = [
  _Patch(
    shape: _PatchShape.semicircle,
    color: AppColors.patchTerracotta,
    dx: 1.04,
    dy: 0.16,
    size: 0.34,
    rotation: -1.5708,
    alpha: 0.28,
  ),
  _Patch(
    shape: _PatchShape.pill,
    color: AppColors.patchSage,
    dx: -0.10,
    dy: 0.88,
    size: 0.40,
    rotation: 0.45,
    alpha: 0.26,
  ),
  _Patch(
    shape: _PatchShape.circle,
    color: AppColors.patchButter,
    dx: 0.94,
    dy: -0.06,
    size: 0.22,
    rotation: 0.0,
    alpha: 0.30,
    morph: true,
  ),
];

const _detailPatches = [
  _Patch(
    shape: _PatchShape.arch,
    color: AppColors.patchSage,
    dx: 1.02,
    dy: -0.04,
    size: 0.34,
    rotation: 0.35,
    alpha: 0.28,
  ),
  _Patch(
    shape: _PatchShape.pill,
    color: AppColors.patchTerracotta,
    dx: 0.30,
    dy: 1.04,
    size: 0.44,
    rotation: -0.15,
    alpha: 0.24,
  ),
];

const _formPatches = [
  _Patch(
    shape: _PatchShape.circle,
    color: AppColors.patchButter,
    dx: -0.08,
    dy: 0.06,
    size: 0.24,
    rotation: 0.0,
    alpha: 0.26,
    morph: true,
  ),
  _Patch(
    shape: _PatchShape.pill,
    color: AppColors.patchSage,
    dx: 1.02,
    dy: 0.94,
    size: 0.30,
    rotation: 0.5,
    alpha: 0.22,
  ),
];

/// Patches in motion: each patch drifts (<= 16dp Lissajous), rotates
/// (+/-6deg) and breathes (scale 0.96-1.04) on its own period/phase from
/// [MotionTokens]; the one `morph` patch lerps circle <-> rounded squircle.
/// Repaints from the clock's 60fps signal — deterministic in `t`, no widget
/// rebuilds.
class _PatchPainter extends CustomPainter {
  _PatchPainter({
    required this.tokens,
    required this.variant,
    required this.motion,
  }) : super(repaint: motion.fast);

  final GiglTokens tokens;
  final AppBackdropVariant variant;
  final MotionRead motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = motion.seconds();
    final patches = switch (variant) {
      AppBackdropVariant.hub => _hubPatches,
      AppBackdropVariant.list => _listPatches,
      AppBackdropVariant.detail => _detailPatches,
      AppBackdropVariant.form => _formPatches,
    };
    // Dark mode draws the same hues quieter (12-20%).
    final dim = tokens.brightness == Brightness.dark ? 0.55 : 1.0;
    final nPeriods = MotionTokens.patchPeriods.length;
    final nDrift = MotionTokens.patchDriftX.length;
    for (var i = 0; i < patches.length; i++) {
      final patch = patches[i];
      final periodX = MotionTokens.patchPeriods[i % nPeriods];
      // Different x/y periods => a slow Lissajous ellipse, never a straight
      // line, and two patches never move in sync.
      final periodY = MotionTokens.patchPeriods[(i + 2) % nPeriods];
      final phase = MotionTokens.patchPhases[i % nPeriods];
      final driftX =
          MotionTokens.patchDriftMaxDp *
          MotionTokens.patchDriftX[i % nDrift] *
          math.sin(2 * math.pi * t / periodX + phase);
      final driftY =
          MotionTokens.patchDriftMaxDp *
          MotionTokens.patchDriftY[i % nDrift] *
          math.sin(2 * math.pi * t / periodY + phase + 1.7);
      final rot =
          patch.rotation +
          MotionTokens.patchRotationMaxRad *
              math.sin(2 * math.pi * t / periodX + phase + 1.1);
      final scale =
          1.0 +
          MotionTokens.patchBreatheAmp *
              math.sin(2 * math.pi * t / periodX + phase + 2.3);

      canvas.save();
      canvas.translate(
        size.width * patch.dx + driftX,
        size.height * patch.dy + driftY,
      );
      canvas.rotate(rot);
      canvas.scale(scale);
      final d = size.width * patch.size;
      final paint = Paint()
        ..color = patch.color.withValues(alpha: patch.alpha * dim)
        ..style = PaintingStyle.fill;
      switch (patch.shape) {
        case _PatchShape.circle when patch.morph:
          // circle <-> rounded squircle via corner-radius lerp.
          final m =
              0.5 +
              0.5 *
                  math.sin(
                    2 * math.pi * t / MotionTokens.patchMorphPeriod +
                        MotionTokens.patchMorphPhase,
                  );
          final radius = Radius.circular(d * (0.5 - 0.22 * m));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: d, height: d),
              radius,
            ),
            paint,
          );
        case _PatchShape.circle:
          canvas.drawCircle(Offset.zero, d / 2, paint);
        case _PatchShape.semicircle:
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: d / 2),
            0,
            3.14159,
            true,
            paint,
          );
        case _PatchShape.arch:
          // Filled arch: stadium top + straight base.
          final path = Path()
            ..moveTo(-d / 2, d / 2)
            ..lineTo(-d / 2, 0)
            ..arcToPoint(Offset(d / 2, 0), radius: Radius.circular(d / 2))
            ..lineTo(d / 2, d / 2)
            ..close();
          canvas.drawPath(path, paint);
        case _PatchShape.pill:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: d, height: d * 0.44),
              Radius.circular(d * 0.22),
            ),
            paint,
          );
        case _PatchShape.triangle:
          // Rounded triangle via quadratic corners.
          final r = d * 0.12;
          final path = Path()
            ..moveTo(0, -d / 2)
            ..quadraticBezierTo(0, -d / 2, r * 0.9, -d * 0.32)
            ..lineTo(d * 0.32, d * 0.28)
            ..quadraticBezierTo(d / 2, d / 2, d * 0.22, d / 2)
            ..lineTo(-d * 0.22, d / 2)
            ..quadraticBezierTo(-d / 2, d / 2, -d * 0.32, d * 0.28)
            ..lineTo(-r * 0.9, -d * 0.32)
            ..quadraticBezierTo(0, -d / 2, 0, -d / 2)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
    // Hub keeps one thin outline arc in the top-right corner — the only
    // line motif, echoing the orbit rings (outline @ 50%, 1dp).
    if (variant == AppBackdropVariant.hub) {
      canvas.drawCircle(
        Offset(size.width * 1.02, -size.height * 0.06),
        size.width * 0.52,
        Paint()
          ..color = tokens.outline.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  /// Decorative: never intercepts hit tests (the child underneath does).
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant _PatchPainter oldDelegate) =>
      oldDelegate.tokens != tokens ||
      oldDelegate.variant != variant ||
      oldDelegate.motion != motion;
}
