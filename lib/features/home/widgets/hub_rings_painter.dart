import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';
import 'package:marketplace_gig/core/motion/motion_tokens.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/features/home/data/node_data.dart';
import 'package:marketplace_gig/features/home/providers/node_home_provider.dart';
import 'package:marketplace_gig/features/home/widgets/radial_layout.dart';

/// The animated hub orbit system, painted BEHIND the nodes:
///
/// * inner dashed orbit with dashes that march clockwise (~40s/rev);
/// * faint solid outer ring + a "comet" (70° sweep-gradient arc with round
///   cap) rotating counter-clockwise (~18s/rev) with a soft head glow;
/// * three satellite dots (terracotta/sage/butter) riding the outer ring at
///   their own speeds/phases, tying rings and blobs into one system;
/// * a soft ripple expanding from the hub to the orbit every ~6s.
///
/// Decoration only: [IgnorePointer]-wrapped by the caller, no semantics,
/// repaints from the ambient clock (no widget rebuilds), geometry derives
/// from the same [RadialCamera] as the nodes so alignment is exact. Nodes,
/// labels, connectors and ALL gestures stay with the node layer.
class HubRingsPainter extends CustomPainter {
  HubRingsPainter({
    required this.frame,
    required this.state,
    required this.tokens,
    required this.scheme,
    required this.motion,
  }) : super(repaint: motion.fast);

  final RadialFrame frame;
  final NodeHomeState state;
  final GiglTokens tokens;
  final ColorScheme scheme;
  final MotionRead motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Same visibility gate as the previous static orbit.
    final rootPos = frame.positions['root'];
    if (rootPos == null) return;
    if (!state.expandedIds.contains('root')) return;
    String? firstMain;
    for (final id in nodeById['root']!.childIds) {
      if (frame.positions.containsKey(id)) {
        firstMain = id;
        break;
      }
    }
    if (firstMain == null) return;
    final mainPos = frame.positions[firstMain]!;
    final radius = (mainPos - rootPos).distance;
    if (radius <= 0) return;

    // Identical camera transform as NodePainter -> pixel-exact alignment.
    final camera = RadialCamera.fit(frame.bounds, size);
    canvas
      ..save()
      ..translate(camera.offset.dx, camera.offset.dy)
      ..scale(camera.scale);

    final t = motion.seconds();
    final outer = radius * 1.35;
    _drawBaseRing(canvas, rootPos, outer);
    _drawMarchingDashes(canvas, rootPos, radius, t);
    _drawComet(canvas, rootPos, outer, t);
    _drawSatellites(canvas, rootPos, outer, t);
    _drawRipple(canvas, rootPos, radius, t);

    canvas.restore();
  }

  /// Faint solid outer ring (outline @ 40%, 1dp) — the base the comet rides.
  void _drawBaseRing(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = scheme.outline.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Inner dashed orbit `- - - - -` (1dp outline) with the dashes FLOWING
  /// around the circle: arc segments advanced by a time-based phase,
  /// one full revolution ~40s, clockwise.
  void _drawMarchingDashes(
    Canvas canvas,
    Offset center,
    double radius,
    double t,
  ) {
    const dash = 4.0;
    const gap = 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    if (count <= 0) return;
    final sweep = dash / radius;
    final step = 2 * math.pi / count;
    final phase = 2 * math.pi * (t / MotionTokens.ringDashPeriod);
    final path = Path();
    for (var i = 0; i < count; i++) {
      path.addArc(rect, i * step + phase, sweep);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = scheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Comet on the outer ring: ~70° arc with a SweepGradient
  /// (primary opaque at the head -> transparent tail), round cap, 2dp,
  /// rotating COUNTER-clockwise, one revolution ~18s. Plus an optional soft
  /// glow behind the head (drop it first if frames drop).
  void _drawComet(Canvas canvas, Offset center, double radius, double t) {
    const sweep = MotionTokens.ringCometSweepRad;
    // Negative direction = counter-clockwise (canvas y grows downward).
    final start = -2 * math.pi * (t / MotionTokens.ringCometPeriod);
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Map the fade across the ARC: 0 -> head, 0.7*sweep -> 70% of the arc,
    // sweep -> tail tip (transparent).
    const f = sweep / (2 * math.pi);
    final shader = SweepGradient(
      transform: GradientRotation(start),
      colors: [
        tokens.brandPrimary,
        tokens.brandPrimary.withValues(alpha: 0.7),
        tokens.brandPrimary.withValues(alpha: 0.0),
      ],
      stops: [0.0, 0.7 * f, f],
    ).createShader(rect);

    // Soft head glow (cheap: short blurred stroke at the leading edge).
    canvas.drawArc(
      rect,
      start - 0.06,
      0.22,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = tokens.brandPrimary.withValues(
          alpha: MotionTokens.ringCometGlowAlpha,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  /// Three tiny satellites (4-5dp) riding the outer ring at different
  /// speeds/phases, in the same hues as the blobs.
  void _drawSatellites(Canvas canvas, Offset center, double radius, double t) {
    final dim = tokens.brightness == Brightness.dark ? 0.55 : 1.0;
    const hues = [
      AppColors.patchTerracotta,
      AppColors.patchSage,
      AppColors.patchButter,
    ];
    for (var i = 0; i < hues.length; i++) {
      final period = MotionTokens.ringSatellitePeriods[i];
      final phase = MotionTokens.ringSatellitePhases[i];
      // Counter-clockwise, matching the comet on the same ring.
      final a = -2 * math.pi * (t / period) + phase;
      final pos = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      canvas.drawCircle(
        pos,
        MotionTokens.ringSatelliteDiameter / 2,
        Paint()..color = hues[i].withValues(alpha: dim),
      );
    }
  }

  /// One soft ripple every ~6s expanding from the hub to the dashed-orbit
  /// radius and fading out (primary @ 12%, 1dp).
  void _drawRipple(Canvas canvas, Offset center, double radius, double t) {
    final cycle = t % MotionTokens.ripplePeriod;
    if (cycle >= MotionTokens.rippleGrowSeconds) return;
    final p = cycle / MotionTokens.rippleGrowSeconds;
    final eased = 1 - (1 - p) * (1 - p); // easeOutQuad
    final from = nodeRadius('root');
    final r = from + (radius - from) * eased;
    final alpha = MotionTokens.rippleAlpha * (1 - p);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = tokens.brandPrimary.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Decorative: never intercepts hit tests (the node layer and the
  /// enclosing GestureDetector own every tap).
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant HubRingsPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.state != state ||
      oldDelegate.tokens != tokens ||
      oldDelegate.scheme != scheme ||
      oldDelegate.motion != motion;
}
