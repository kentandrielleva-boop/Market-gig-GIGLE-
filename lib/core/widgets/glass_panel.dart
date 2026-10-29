import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';

/// Frosted-glass container: blur sigma 18 + [GiglTokens.surfaceGlass] fill +
/// 1px [GiglTokens.glassBorder], radius lg.
///
/// v3 note: the floating dock moved to an opaque ink fill (white-on-glass
/// text failed contrast), so this is currently available for header action
/// clusters / sheets only — max 2 blurred panels per screen, always inside
/// [ClipRRect] + [RepaintBoundary]. Falls back to solid surface @ 92% (no
/// blur) on low-end devices or when [MediaQuery.disableAnimations] is true.
class GlassPanel extends ConsumerWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = GiglTokens.radiusLg,
    this.padding,
    this.shadows,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Extra shadows (e.g. [GiglTokens.shadowEDock] for the floating dock).
  final List<BoxShadow>? shadows;

  /// Filter blur sigma; 0 means "use the no-blur fallback".
  static const double blurSigma = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final tier = ref.watch(deviceTierProvider).value ?? DeviceTier.low;
    final calm = MediaQuery.disableAnimationsOf(context);
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final decoration = BoxDecoration(
      color: calm || tier == DeviceTier.low
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.92)
          : tokens.surfaceGlass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: tokens.glassBorder, width: 1),
      boxShadow: shadows,
    );

    if (calm || tier == DeviceTier.low) {
      return RepaintBoundary(
        child: DecoratedBox(decoration: decoration, child: content),
      );
    }
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(decoration: decoration, child: content),
        ),
      ),
    );
  }
}
