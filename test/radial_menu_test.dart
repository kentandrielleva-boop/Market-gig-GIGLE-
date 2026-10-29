import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/features/home/home.dart';

Rect _screenRect(String label) {
  final node = find.semantics.byLabel(label).evaluate().single;
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    if (n.transform != null) {
      rect = MatrixUtils.transformRect(n.transform!, rect);
    }
  }
  return rect;
}

bool _shown(String label) =>
    find.semantics.byLabel(label).evaluate().isNotEmpty;

void main() {
  testWidgets('expands a branch, then steps back on empty-space tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NodeHomeScreen()),
      ),
    );

    expect(_shown('Nearby'), isFalse);

    await tester.tapAt(_screenRect('Discover').center);
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(nodeHomeProvider).expandedIds, contains('discover'));
    await tester.pumpAndSettle();

    final canvas = tester.getRect(find.byType(CustomPaint).last);
    for (final label in ['Nearby', 'Trending', 'For you', 'Filters']) {
      final rect = _screenRect(label);
      expect(canvas.contains(rect.center), isTrue, reason: '$label on screen');
    }

    await tester.tapAt(canvas.topLeft + const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(container.read(nodeHomeProvider).breadcrumb, ['root']);
    expect(_shown('Nearby'), isFalse);

    semantics.dispose();
  });

  testWidgets('tapping a leaf label opens the leaf', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const NodeHomeScreen(),
          routes: [
            GoRoute(
              path: 'discover/nearby',
              builder: (_, _) => const Text('nearby page'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.tapAt(_screenRect('Discover').center);
    await tester.pumpAndSettle();

    // Lower half of the label, outside the circle's own tap slack.
    final leaf = _screenRect('Nearby');
    final scale = leaf.height / (2 * kLeafNodeRadius);
    await tester.tapAt(leaf.center + Offset(0, (kLeafNodeRadius + 12) * scale));
    await tester.pumpAndSettle();

    expect(find.text('nearby page'), findsOneWidget);
    semantics.dispose();
  });
}
