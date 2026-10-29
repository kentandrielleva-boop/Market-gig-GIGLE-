import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/router/app_router.dart';
import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/listing_card.dart';
import 'package:marketplace_gig/features/legal/legal_consent_providers.dart';
import 'package:marketplace_gig/features/reviews/review_widgets.dart';

/// Signed-in, verified user so the real route table renders without Firebase.
class _FakeAuthGateway implements AuthGateway {
  @override
  Stream<String?> get userIdChanges => Stream.value('local-user');

  @override
  Stream<bool> get emailVerifiedChanges => Stream.value(true);

  @override
  String? get currentUserId => 'local-user';

  @override
  String? get currentEmail => 'tester@example.com';

  @override
  bool get isEmailVerified => true;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? captchaToken,
  }) async {
    throw UnimplementedError('Not used in widget tests.');
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    throw UnimplementedError('Not used in widget tests.');
  }

  @override
  Future<void> resendConfirmation(String email, {String? captchaToken}) async {
    throw UnimplementedError('Not used in widget tests.');
  }

  @override
  Future<bool> refreshEmailVerified() async => true;

  @override
  Future<void> signOut() async {}
}

class _AcceptedLegalNotifier extends LegalAcceptanceNotifier {
  @override
  Future<bool> build() async => true;
}

/// Reads the router during the first frame like `MarketplaceApp` does —
/// building it up front leaves the auth stream providers unstarted.
class _RouterHost extends ConsumerWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      MaterialApp.router(routerConfig: ref.watch(appRouterProvider));
}

const _gig = Listing(
  id: 'gig-1',
  type: ListingType.gig,
  title: 'Logo Design',
  price: 800,
  description: 'A clean minimal logo delivered in two days.',
  imageUrls: [],
  category: 'Services',
  location: 'Tagum City',
  ownerId: 'seller-1',
);

final _seller = UserProfile(
  id: 'seller-1',
  name: 'Maria Cruz',
  avatarUrl: '',
  rating: 4.8,
  reviewCount: 3,
  listingsCount: 5,
  soldCount: 2,
  memberSince: DateTime(2021, 6),
);

final _review = Review(
  id: 'rev-1',
  raterName: 'Joel',
  rating: 5,
  comment: 'Fast and friendly',
  listingTitle: 'Logo Design',
  createdAt: DateTime(2024, 2),
  reviewerId: 'joel-1',
);

/// Boots the real route table over offline repositories seeded with [_gig]
/// and the seller's profile (with [sellerReviews]), signed in as [userId].
Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  String userId = 'local-user',
  List<Review>? sellerReviews,
  Set<String>? chattedWith,
  Set<String>? chattedListings,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    await db.insertListings([_gig]);
    await db.insertProfile(_seller, sellerReviews ?? [_review]);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => db),
        firebaseInitProvider.overrideWith((ref) async {}),
        authGatewayProvider.overrideWithValue(_FakeAuthGateway()),
        emailVerifiedProvider.overrideWith((ref) => Stream.value(true)),
        legalAcceptanceProvider.overrideWith(() => _AcceptedLegalNotifier()),
        currentUserIdProvider.overrideWithValue(userId),
        listingRepositoryProvider.overrideWithValue(LocalListingRepository(db)),
        profileRepositoryProvider.overrideWithValue(
          LocalProfileRepository(
            db,
            userId: userId,
            chattedWith: chattedWith,
            chattedListings: chattedListings,
          ),
        ),
        chatRepositoryProvider.overrideWithValue(LocalChatRepository(db)),
      ],
      child: const _RouterHost(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

GoRouter _routerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MaterialApp)),
).read(appRouterProvider);

/// Scrolls the detail body so lower sections (description, seller card) are
/// built — ListView children past the viewport + cache extent do not exist.
Future<void> _scroll(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -400));
  await tester.pumpAndSettle();
}

/// Scrolls a profile's review list until [finder] is built (the filter
/// bars and sort row sit above the first card).
Future<void> _scrollToReview(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).last,
  );
  // Built in the cache extent isn't on screen yet; bring it fully in view.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Drift cancels stream queries on a zero-length timer: unmount first, then
/// pump so `close` completes under the fake clock (same dance as
/// `section_screens_test.dart`).
Future<void> _dispose(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 5));
  final closing = db.close();
  await tester.pump(const Duration(milliseconds: 5));
  await closing;
}

void main() {
  testWidgets('tapping a browse card shows the description and the seller', (
    tester,
  ) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/gigs');
    await tester.pumpAndSettle();
    expect(find.text('Logo Design'), findsOneWidget);

    await tester.tap(find.text('Logo Design'));
    await tester.pumpAndSettle();
    await _scroll(tester);

    expect(find.text('Gig details'), findsOneWidget);
    expect(
      find.text('A clean minimal logo delivered in two days.'),
      findsOneWidget,
    );
    expect(find.text('Tagum City'), findsOneWidget);
    expect(find.text('Maria Cruz'), findsOneWidget);
    expect(find.text('4.8 (3 reviews)'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('the seller card opens their public profile with reviews', (
    tester,
  ) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/listing/gig-1');
    await tester.pumpAndSettle();
    await _scroll(tester);
    expect(find.text('Maria Cruz'), findsOneWidget);

    await tester.tap(find.text('Maria Cruz'));
    await tester.pumpAndSettle();

    expect(find.text('Leave a review'), findsOneWidget);
    expect(find.text('Rating distribution'), findsOneWidget);
    await _scrollToReview(tester, find.text('Fast and friendly'));
    expect(find.text('Fast and friendly'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('a buyer can rate and review the listing', (tester) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/listing/gig-1');
    await tester.pumpAndSettle();
    final write = find.text('Write a review');
    await tester.ensureVisible(write);
    await tester.pumpAndSettle();
    expect(find.text('No reviews yet — be the first.'), findsOneWidget);

    await tester.tap(write);
    await tester.pumpAndSettle();
    expect(find.text('Rate this gig'), findsOneWidget);
    final stars = find.descendant(
      of: find.byType(ReviewSheet),
      matching: find.byType(IconButton),
    );
    await tester.tap(stars.at(3));
    await tester.enterText(
      find.descendant(
        of: find.byType(ReviewSheet),
        matching: find.byType(TextField),
      ),
      'Great logo, quick turnaround',
    );
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSheet), findsNothing);
    expect(find.text('Great logo, quick turnaround'), findsOneWidget);
    expect(find.text('4.0 · 1 review'), findsOneWidget);

    // Only one review per user: the button now edits the existing one.
    expect(find.text('Write a review'), findsNothing);
    await tester.tap(find.text('Edit your review'));
    await tester.pumpAndSettle();
    expect(find.text('Update review'), findsOneWidget);
    final comment = find.descendant(
      of: find.byType(ReviewSheet),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(comment).controller!.text,
      'Great logo, quick turnaround',
    );
    await tester.tap(stars.at(1));
    await tester.enterText(comment, 'Okay, but needed revisions');
    await tester.tap(find.text('Update review'));
    await tester.pumpAndSettle();

    expect(find.text('Great logo, quick turnaround'), findsNothing);
    expect(find.text('Okay, but needed revisions'), findsOneWidget);
    expect(find.text('2.0 · 1 review'), findsOneWidget);
    expect(find.text('Edited'), findsOneWidget);

    // Deleting asks first, then frees the user to write a new review.
    await tester.tap(find.text('Edit your review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete review'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your review?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSheet), findsNothing);
    expect(find.text('Okay, but needed revisions'), findsNothing);
    expect(find.text('No reviews yet — be the first.'), findsOneWidget);
    expect(find.text('Write a review'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('a returning reviewer edits and deletes their user review', (
    tester,
  ) async {
    final mine = Review(
      id: 'local-user_seller-1',
      raterName: 'Me',
      rating: 3,
      comment: 'Decent',
      listingTitle: 'Logo Design',
      createdAt: DateTime(2024, 3),
      reviewerId: 'local-user',
    );
    final db = await _pumpApp(tester, sellerReviews: [_review, mine]);
    _routerOf(tester).go('/user/seller-1');
    await tester.pumpAndSettle();

    expect(find.text('Leave a review'), findsNothing);
    await tester.tap(find.text('Edit your review'));
    await tester.pumpAndSettle();
    expect(find.text('Update review'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(ReviewSheet),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      'Decent',
    );

    await tester.tap(find.text('Delete review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Decent'), findsNothing);
    expect(find.text('Leave a review'), findsOneWidget);
    await _scrollToReview(tester, find.text('Fast and friendly'));
    expect(find.text('Fast and friendly'), findsOneWidget);
    // The average now only counts the remaining 5★ review.
    expect(find.text('5.0 (1 reviews)'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('owners cannot review their own listing', (tester) async {
    final db = await _pumpApp(tester, userId: 'seller-1');
    _routerOf(tester).go('/listing/gig-1');
    await tester.pumpAndSettle();
    await _scroll(tester);

    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('No reviews yet.'), findsOneWidget);
    expect(find.text('Write a review'), findsNothing);

    await _dispose(tester, db);
  });

  testWidgets('users cannot leave a review on their own profile', (
    tester,
  ) async {
    final db = await _pumpApp(tester, userId: 'seller-1');
    _routerOf(tester).go('/user/seller-1');
    await tester.pumpAndSettle();

    expect(find.text('Fast and friendly'), findsOneWidget);
    expect(find.text('Leave a review'), findsNothing);

    await _dispose(tester, db);
  });

  testWidgets('a card in the swipe deck opens the detail screen', (
    tester,
  ) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/home/discover/feed');
    await tester.pumpAndSettle();
    expect(find.text('Gig details'), findsNothing);

    await tester.tap(find.text('Logo Design'));
    await tester.pumpAndSettle();
    await _scroll(tester);

    expect(find.text('Gig details'), findsOneWidget);
    expect(
      find.text('A clean minimal logo delivered in two days.'),
      findsOneWidget,
    );

    await _dispose(tester, db);
  });

  testWidgets('a deep link to a missing listing says it is unavailable', (
    tester,
  ) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/listing/gone');
    await tester.pumpAndSettle();

    expect(find.text('This listing is no longer available'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('message poster opens a thread about the listing, once', (
    tester,
  ) async {
    final db = await _pumpApp(tester);
    _routerOf(tester).go('/listing/gig-1');
    await tester.pumpAndSettle();
    await _scroll(tester);

    await tester.tap(find.text('Message poster'));
    await tester.pumpAndSettle();

    expect(find.text('Gig poster'), findsOneWidget);
    expect(find.text('Logo Design'), findsWidgets);

    // A second tap reuses the same thread instead of creating another.
    _routerOf(tester).go('/listing/gig-1');
    await tester.pumpAndSettle();
    await _scroll(tester);
    await tester.tap(find.text('Message poster'));
    await tester.pumpAndSettle();
    final count = await tester.runAsync(
      () => db.select(db.conversationsTable).get().then((r) => r.length),
    );
    expect(count, 1);

    await _dispose(tester, db);
  });

  group('direct chat and safety', () {
    LocalProfileRepository profileRepo(WidgetTester tester) =>
        ProviderScope.containerOf(
              tester.element(find.byType(MaterialApp)),
            ).read(profileRepositoryProvider)
            as LocalProfileRepository;

    Future<void> openMenuItem(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('Message on a profile opens a direct thread, once', (
      tester,
    ) async {
      final db = await _pumpApp(tester);
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();
      expect(find.text('Type a message'), findsOneWidget);
      // Direct threads have no listing chip.
      expect(find.byType(ActionChip), findsNothing);

      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();
      final rows = await tester.runAsync(
        () => db.select(db.conversationsTable).get(),
      );
      expect(rows!.map((r) => r.id), ['local-dm-seller-1']);
      expect(rows.single.otherUserId, 'seller-1');

      await _dispose(tester, db);
    });

    testWidgets('your own profile has no Message button or safety menu', (
      tester,
    ) async {
      final db = await _pumpApp(tester, userId: 'seller-1');
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      expect(find.text('Maria Cruz'), findsWidgets);
      expect(find.text('Message'), findsNothing);
      expect(find.byTooltip('More options'), findsNothing);

      await _dispose(tester, db);
    });

    testWidgets('blocking from a profile swaps Message for Unblock', (
      tester,
    ) async {
      final db = await _pumpApp(tester);
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      await openMenuItem(tester, 'Block user');
      await tester.tap(find.widgetWithText(FilledButton, 'Block'));
      await tester.pumpAndSettle();

      expect(find.text('Message'), findsNothing);
      expect(find.text('Unblock'), findsOneWidget);

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();
      expect(find.text('Message'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets('reporting a user files a report through the sheet', (
      tester,
    ) async {
      final db = await _pumpApp(tester);
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      await openMenuItem(tester, 'Report user');
      expect(find.text('Report user'), findsOneWidget);
      await tester.tap(find.text('Scam or fraud'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(profileRepo(tester).reportedUserIds, {'seller-1'});
      expect(find.text('Thanks — we will review this report.'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets('the thread header opens the other user\'s profile', (
      tester,
    ) async {
      final db = await _pumpApp(tester);
      final id = await tester.runAsync(
        () => LocalChatRepository(db).startDirectConversation('seller-1'),
      );
      _routerOf(tester).push('/inbox/$id');
      await tester.pumpAndSettle();

      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();
      await _scrollToReview(tester, find.text('Fast and friendly'));
      expect(find.text('Fast and friendly'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets('a blocked user\'s thread replaces the composer', (
      tester,
    ) async {
      final db = await _pumpApp(tester);
      final id = await tester.runAsync(
        () => LocalChatRepository(db).startDirectConversation('seller-1'),
      );
      await profileRepo(tester).blockUser('seller-1', name: 'Maria Cruz');
      _routerOf(tester).push('/inbox/$id');
      await tester.pumpAndSettle();

      expect(find.textContaining('You blocked this user'), findsOneWidget);
      expect(find.text('Type a message'), findsNothing);

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();
      expect(find.text('Type a message'), findsOneWidget);

      await _dispose(tester, db);
    });
  });

  group('review safeguards and browsing', () {
    LocalProfileRepository profileRepo(WidgetTester tester) =>
        ProviderScope.containerOf(
              tester.element(find.byType(MaterialApp)),
            ).read(profileRepositoryProvider)
            as LocalProfileRepository;

    VoidCallback? onPressedOf(WidgetTester tester, String label) => tester
        .widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        )
        .onPressed;

    testWidgets('reviewing a listing needs a chat with its seller', (
      tester,
    ) async {
      final db = await _pumpApp(tester, chattedListings: {});
      _routerOf(tester).go('/listing/gig-1');
      await tester.pumpAndSettle();
      await _scroll(tester);

      expect(find.text('Message the seller to leave a review.'), findsOne);
      expect(onPressedOf(tester, 'Write a review'), isNull);

      await _dispose(tester, db);
    });

    testWidgets('rating a user needs a chat with them', (tester) async {
      final db = await _pumpApp(tester, chattedWith: {});
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      expect(find.text('Chat with them first to leave a review.'), findsOne);
      expect(onPressedOf(tester, 'Leave a review'), isNull);

      await _dispose(tester, db);
    });

    testWidgets('a review written after chatting shows as verified', (
      tester,
    ) async {
      final db = await _pumpApp(tester, chattedWith: {'seller-1'});
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leave a review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit review'));
      await tester.pumpAndSettle();

      await _scrollToReview(tester, find.text('Verified chat'));
      expect(find.text('Your review'), findsOneWidget);
      expect(find.text('Verified chat'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets('the reviewed user can reply to a review', (tester) async {
      final db = await _pumpApp(tester, userId: 'seller-1');
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();
      await _scrollToReview(tester, find.text('Reply'));
      // Reviews about you can be answered, and reported if abusive.
      expect(find.byTooltip('Review options'), findsOneWidget);

      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
      expect(find.text('Reply to review'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'Thanks, Joel!',
      );
      await tester.pump();
      await tester.tap(find.text('Save reply'));
      await tester.pumpAndSettle();
      await _scrollToReview(tester, find.text('Edit reply'));

      expect(find.text('Thanks, Joel!'), findsOneWidget);
      expect(find.text('Response from you'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets("someone else's review can be reported once", (tester) async {
      final db = await _pumpApp(tester);
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();
      await _scrollToReview(tester, find.text('Fast and friendly'));

      Future<void> report() async {
        await tester.tap(find.byTooltip('Review options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Report review'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spam or misleading'));
        await tester.pump();
        await tester.tap(find.text('Submit report'));
        await tester.pumpAndSettle();
      }

      await report();
      expect(profileRepo(tester).reportedReviewIds, {'user_rev-1'});
      expect(
        find.text('Thanks — we will look into this review.'),
        findsOneWidget,
      );

      // Let the snackbar go before reporting again.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await report();
      expect(find.text('You already reported this review.'), findsOneWidget);

      await _dispose(tester, db);
    });

    testWidgets('own review is pinned; bars filter; Load more pages', (
      tester,
    ) async {
      final others = [
        for (var i = 0; i < 24; i++)
          Review(
            id: 'r$i',
            raterName: 'Rater $i',
            rating: i == 0 ? 1 : 5,
            comment: 'Comment $i',
            listingTitle: '',
            createdAt: DateTime(2024, 1, 1).add(Duration(days: i)),
            reviewerId: 'u$i',
          ),
      ];
      final mine = Review(
        id: 'local-user_seller-1',
        raterName: 'Me',
        rating: 3,
        comment: 'My take',
        listingTitle: '',
        // Oldest, so unpinned it would only show up after "Load more".
        createdAt: DateTime(2023),
        reviewerId: 'local-user',
      );
      final db = await _pumpApp(tester, sellerReviews: [...others, mine]);
      _routerOf(tester).go('/user/seller-1');
      await tester.pumpAndSettle();

      await _scrollToReview(tester, find.text('My take'));
      expect(find.text('Your review'), findsOneWidget);

      // First page: the newest 20 reviews (one of them the pinned own one,
      // listed only once), so the oldest of the others need "Load more".
      await _scrollToReview(tester, find.text('Load more reviews'));
      expect(find.text('Comment 0'), findsNothing);
      await tester.tap(find.text('Load more reviews'));
      await tester.pumpAndSettle();
      await _scrollToReview(tester, find.text('Comment 0'));
      expect(find.text('Comment 0'), findsOneWidget);

      // Tapping the 1★ bar keeps only 1★ reviews (and hides the 3★ pin).
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Show 1 star reviews'),
        -300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.bySemanticsLabel('Show 1 star reviews'));
      await tester.pumpAndSettle();
      expect(find.text('Showing 1★'), findsOneWidget);
      await _scrollToReview(tester, find.text('Comment 0'));
      expect(find.text('Comment 5'), findsNothing);
      expect(find.text('My take'), findsNothing);

      await _dispose(tester, db);
    });
  });

  testWidgets('listing cards show the product rating once reviewed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 480,
              child: ListingCard(
                listing: Listing(
                  id: 'l1',
                  type: ListingType.item,
                  title: 'Bike',
                  price: 100,
                  description: '',
                  imageUrls: [],
                  category: 'General',
                  location: 'Tagum City',
                  ratingSum: 9,
                  ratingCount: 2,
                ),
                showMenu: false,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('4.5 (2)'), findsOneWidget);
  });
}
