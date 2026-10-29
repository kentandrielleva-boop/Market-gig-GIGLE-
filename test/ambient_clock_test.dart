import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';

/// Painter that only subscribes to the clock — mirrors how every ambient
/// painter in the app attaches (via `CustomPainter(repaint:)`).
class _SpyPainter extends CustomPainter {
  _SpyPainter(this.motion) : super(repaint: motion.fast);

  final MotionRead motion;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_SpyPainter oldDelegate) => oldDelegate.motion != motion;
}

void main() {
  MotionRead? captured;

  Widget tree({AmbientMotion mode = AmbientMotion.auto, bool calm = false}) =>
      ProviderScope(
        overrides: [ambientMotionProvider.overrideWith((_) => mode)],
        child: AmbientClock(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Consumers read reduce-motion from MediaQuery (as
                // AmbientClock.motionOf does); simulate it for the subtree.
                final media =
                    MediaQuery.maybeOf(context) ?? const MediaQueryData();
                return MediaQuery(
                  data: media.copyWith(disableAnimations: calm),
                  child: Builder(
                    builder: (inner) {
                      final motion = AmbientClock.motionOf(inner);
                      captured = motion;
                      return CustomPaint(painter: _SpyPainter(motion));
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

  // NOTE: never pumpAndSettle while the ticker runs — it schedules frames
  // continuously by design. Use explicit pumps.

  testWidgets('auto mode: painter subscribes, seconds advance', (tester) async {
    await tester.pumpWidget(tree());
    expect(captured, isNotNull);
    // One frame so the ticker lands its baseline tick; the next frame
    // accumulates real elapsed time and fires.
    await tester.pump();
    final before = captured!.seconds();
    await tester.pump(const Duration(seconds: 3));
    expect(captured!.seconds(), greaterThan(before));
    // Unmount so the ticker stops before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('motion off: static t=0 frame, ticker never starts', (
    tester,
  ) async {
    await tester.pumpWidget(tree(mode: AmbientMotion.off));
    expect(captured, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    expect(captured!.seconds(), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduce-motion: static t=0 frame even in auto mode', (
    tester,
  ) async {
    await tester.pumpWidget(tree(calm: true));
    expect(captured, isNotNull);
    await tester.pump(const Duration(seconds: 4));
    expect(captured!.seconds(), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
