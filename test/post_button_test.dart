import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/router/app_router.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/swipe_card_stack.dart';

const _bike = Listing(
  id: 'bike',
  type: ListingType.item,
  title: 'Blue Bike',
  price: 1500,
  description: '',
  imageUrls: [],
  category: 'General',
  location: 'Quezon City',
);

void main() {
  testWidgets('swipe row has Post between Info and Save without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserIdProvider.overrideWithValue('me')],
        child: const MaterialApp(
          home: Scaffold(body: SwipeCardStack(listings: [_bike])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Pass', 'Info', 'Post', 'Save']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    final x = [
      for (final l in ['Pass', 'Info', 'Post', 'Save'])
        tester.getCenter(find.text(l)).dx,
    ];
    expect(x, orderedEquals([...x]..sort()));

    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Sell an Item'), findsOneWidget);
  });

  testWidgets('floating dock Post is hidden on the swipe feed only', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (_, _, child) => ShellScaffold(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Text('menu'),
              routes: [
                GoRoute(
                  path: 'discover/feed',
                  builder: (_, _) => const Text('feed'),
                ),
              ],
            ),
            GoRoute(path: '/profile', builder: (_, _) => const Text('me')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingDock), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);

    router.go('/home/discover/feed');
    await tester.pumpAndSettle();
    expect(find.text('feed'), findsOneWidget);
    expect(find.byType(FloatingDock), findsNothing);

    router.go('/profile');
    await tester.pumpAndSettle();
    expect(find.byType(FloatingDock), findsOneWidget);
  });
}
