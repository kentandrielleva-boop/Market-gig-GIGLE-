import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/home.dart';
import 'package:marketplace_gig/features/inbox/inbox_screen.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';

class _Auth implements AuthGateway {
  @override
  String? get currentEmail => 'tester@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingRepo extends LocalListingRepository {
  _RecordingRepo(super.db, {this.reportResult = true});

  final bool reportResult;
  final reports = <(String, ReportReason, String?)>[];

  @override
  Future<bool> reportListing(
    Listing listing,
    ReportReason reason, {
    String? details,
  }) async {
    reports.add((listing.id, reason, details));
    return reportResult;
  }
}

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

const _logo = Listing(
  id: 'logo',
  type: ListingType.gig,
  title: 'Logo Design',
  price: 800,
  description: '',
  imageUrls: [],
  category: 'Services',
  location: 'Quezon City',
);

const _lamp = Listing(
  id: 'lamp',
  type: ListingType.item,
  title: 'Vintage Lamp',
  price: 300,
  description: '',
  imageUrls: [],
  category: 'General',
  location: 'Quezon City',
  ownerId: 'someone-else',
);

const _strangerGig = Listing(
  id: 'tutor',
  type: ListingType.gig,
  title: 'Math Tutoring',
  price: 400,
  description: '',
  imageUrls: [],
  category: 'Services',
  location: 'Quezon City',
  ownerId: 'someone-else',
);

List<Override> _overrides(
  AppDatabase db, {
  ListingRepository? listings,
  bool withChatAndProfile = true,
}) => [
  listingRepositoryProvider.overrideWithValue(
    listings ?? LocalListingRepository(db),
  ),
  currentUserIdProvider.overrideWithValue('local-user'),
  if (withChatAndProfile) ...[
    chatRepositoryProvider.overrideWithValue(LocalChatRepository(db)),
    profileRepositoryProvider.overrideWithValue(LocalProfileRepository(db)),
    authGatewayProvider.overrideWithValue(_Auth()),
  ],
];

Future<AppDatabase> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Listing> listings = const [_bike, _logo],
  ListingRepository Function(AppDatabase)? repo,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() => db.insertListings(listings));
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(db, listings: repo?.call(db)),
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _dispose(WidgetTester tester, AppDatabase db) async {
  // Drift cancels stream queries on a zero-length timer: pump so it fires
  // before closing, or the close never completes under the fake clock.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 5));
  final closing = db.close();
  await tester.pump(const Duration(milliseconds: 5));
  await closing;
}

Finder _menuOf(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
  matching: find.byType(ListingMenuButton),
);

Future<void> _openMenu(WidgetTester tester, String title) async {
  await tester.tap(_menuOf(title));
  await tester.pumpAndSettle();
}

void main() {
  test('post form needs a photo and a location', () {
    const ready = PostFormState(
      title: 'Bike',
      priceText: '10',
      photoPaths: ['a.jpg'],
    );
    expect(ready.location, kDefaultListingLocation);
    expect(ready.canSubmit, isTrue);
    expect(ready.copyWith(location: '  ').canSubmit, isFalse);
    expect(ready.copyWith(photoPaths: const []).canSubmit, isFalse);
  });

  testWidgets('market screens split items and gigs, hiding own posts', (
    tester,
  ) async {
    const all = [_bike, _logo, _lamp, _strangerGig];
    var db = await _pump(tester, const AllItemsScreen(), listings: all);
    expect(find.text('Vintage Lamp'), findsOneWidget);
    expect(find.text('Math Tutoring'), findsNothing);
    // Own posts live under My listings / My gigs, not discovery.
    expect(find.text('Blue Bike'), findsNothing);
    await _dispose(tester, db);

    db = await _pump(tester, const BrowseGigsScreen(), listings: all);
    expect(find.text('Math Tutoring'), findsOneWidget);
    expect(find.text('Vintage Lamp'), findsNothing);
    expect(find.text('Logo Design'), findsNothing);
    await _dispose(tester, db);

    db = await _pump(tester, const DealsScreen(), listings: all);
    expect(find.text('Vintage Lamp'), findsOneWidget);
    expect(find.text('Blue Bike'), findsNothing);
    await _dispose(tester, db);

    db = await _pump(tester, const MyListingsScreen(), listings: all);
    expect(find.text('Blue Bike'), findsOneWidget);
    expect(find.text('Vintage Lamp'), findsNothing);
    await _dispose(tester, db);
  });

  testWidgets('my gigs shows own gigs with their status', (tester) async {
    final db = await _pump(tester, const MyGigsScreen());
    expect(find.text('Logo Design'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Blue Bike'), findsNothing);
    await _dispose(tester, db);
  });

  testWidgets('saved and history screens reflect swipes and can undo them', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await db.insertListings([_bike, _logo, _lamp]);
      await db.setSwipe('bike', SwipeActionType.saved);
      await db.setSwipe('logo', SwipeActionType.saved);
      await db.setSwipe('lamp', SwipeActionType.passed);
    });

    Future<void> show(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(db, withChatAndProfile: false),
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const LikedItemsScreen());
    expect(find.text('Blue Bike'), findsOneWidget);
    expect(find.text('Logo Design'), findsOneWidget);

    await show(const CollectionsScreen());
    expect(find.text('GENERAL · 1'), findsOneWidget);

    await show(const HistoryScreen());
    expect(find.text('Vintage Lamp'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing passed yet'), findsOneWidget);

    await _dispose(tester, db);
  });

  testWidgets('inbox, wallet, settings and filters render real content', (
    tester,
  ) async {
    var db = await _pump(tester, const RequestsScreen());
    expect(find.text('No new requests'), findsOneWidget);
    await _dispose(tester, db);

    db = await _pump(tester, const WalletScreen());
    expect(find.text('Total earned'), findsOneWidget);
    await _dispose(tester, db);

    db = await _pump(tester, const SettingsScreen());
    expect(find.text('tester@example.com'), findsOneWidget);
    await _dispose(tester, db);

    db = await _pump(tester, const FilterSheetScreen());
    expect(find.text('Show results'), findsOneWidget);
    await _dispose(tester, db);
  });

  group('chat organisation', () {
    Conversation conversation(
      String id, {
      int unread = 0,
      bool archived = false,
      String otherUserId = '',
    }) => Conversation(
      id: id,
      participantName: 'Name $id',
      participantAvatar: '',
      lastMessage: 'Last from $id',
      timestamp: DateTime(2024),
      unreadCount: unread,
      role: ParticipantRole.direct,
      listingTitle: '',
      listingId: '',
      otherUserId: otherUserId,
      isArchived: archived,
    );

    Future<AppDatabase> pumpWith(
      WidgetTester tester,
      Widget screen,
      List<Conversation> conversations, {
      LocalProfileRepository Function(AppDatabase)? profiles,
    }) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => db.insertConversations(conversations));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overrides(db, withChatAndProfile: false),
            chatRepositoryProvider.overrideWithValue(LocalChatRepository(db)),
            profileRepositoryProvider.overrideWithValue(
              profiles?.call(db) ?? LocalProfileRepository(db),
            ),
            authGatewayProvider.overrideWithValue(_Auth()),
          ],
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pumpAndSettle();
      return db;
    }

    testWidgets('requests lists unread threads, not archived ones', (
      tester,
    ) async {
      final db = await pumpWith(tester, const RequestsScreen(), [
        conversation('a', unread: 2),
        conversation('b'),
        conversation('c', unread: 1, archived: true),
      ]);
      expect(find.text('Name a'), findsOneWidget);
      expect(find.text('Name b'), findsNothing);
      expect(find.text('Name c'), findsNothing);
      await _dispose(tester, db);
    });

    testWidgets('archived lists archived threads and can unarchive', (
      tester,
    ) async {
      final db = await pumpWith(tester, const ArchivedChatsScreen(), [
        conversation('a', archived: true),
        conversation('b'),
      ]);
      expect(find.text('Name a'), findsOneWidget);
      expect(find.text('Name b'), findsNothing);

      await tester.tap(find.byTooltip('Unarchive'));
      await tester.pumpAndSettle();
      expect(find.text('No archived chats'), findsOneWidget);
      final row = await tester.runAsync(() => db.getConversation('a'));
      expect(row!.isArchived, isFalse);
      await _dispose(tester, db);
    });

    testWidgets('swiping an inbox thread archives it', (tester) async {
      final db = await pumpWith(tester, const Scaffold(body: InboxScreen()), [
        conversation('a'),
      ]);
      await tester.drag(find.text('Name a'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Name a'), findsNothing);
      expect(find.text('Chat archived'), findsOneWidget);
      final row = await tester.runAsync(() => db.getConversation('a'));
      expect(row!.isArchived, isTrue);
      await _dispose(tester, db);
    });

    testWidgets(
      'blocked users are hidden from the inbox and can be unblocked',
      (tester) async {
        late LocalProfileRepository profiles;
        final db = await pumpWith(tester, const BlockedUsersScreen(), [
          conversation('a', otherUserId: 'troll'),
        ], profiles: (db) => profiles = LocalProfileRepository(db));
        expect(find.text('No blocked users'), findsOneWidget);

        await profiles.blockUser('troll', name: 'Troll');
        await tester.pumpAndSettle();
        expect(find.text('Troll'), findsOneWidget);

        await tester.tap(find.text('Unblock'));
        await tester.pumpAndSettle();
        expect(find.text('No blocked users'), findsOneWidget);
        await _dispose(tester, db);
      },
    );

    testWidgets('a blocked user\'s thread drops out of the inbox', (
      tester,
    ) async {
      late LocalProfileRepository profiles;
      final db = await pumpWith(tester, const Scaffold(body: InboxScreen()), [
        conversation('a', otherUserId: 'troll'),
      ], profiles: (db) => profiles = LocalProfileRepository(db));
      expect(find.text('Name a'), findsOneWidget);
      await profiles.blockUser('troll');
      await tester.pumpAndSettle();
      expect(find.text('Name a'), findsNothing);
      await _dispose(tester, db);
    });
  });

  testWidgets('no menu screen falls back to a coming-soon page', (
    tester,
  ) async {
    for (final screen in const <Widget>[
      ArchivedChatsScreen(),
      RatingsScreen(),
    ]) {
      final db = await _pump(tester, screen);
      expect(find.textContaining('coming soon'), findsNothing);
      await _dispose(tester, db);
    }
  });

  group('listing menu', () {
    testWidgets('own listing offers Edit and Delete, never Report', (
      tester,
    ) async {
      final db = await _pump(tester, const MyListingsScreen());
      await _openMenu(tester, 'Blue Bike');
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Report'), findsNothing);
      await _dispose(tester, db);
    });

    testWidgets("someone else's listing offers only Report", (tester) async {
      final db = await _pump(
        tester,
        const AllItemsScreen(),
        listings: const [_bike, _lamp],
      );
      await _openMenu(tester, 'Vintage Lamp');
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      await _dispose(tester, db);
    });

    testWidgets('delete asks for confirmation, then removes the listing', (
      tester,
    ) async {
      final db = await _pump(tester, const MyListingsScreen());
      await _openMenu(tester, 'Blue Bike');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Blue Bike'), findsOneWidget);

      await _openMenu(tester, 'Blue Bike');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Blue Bike'), findsNothing);
      expect(find.text('Listing deleted'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('edit saves changed title and status', (tester) async {
      final db = await _pump(tester, const MyListingsScreen());
      expect(find.text('Active'), findsOneWidget);

      await _openMenu(tester, 'Blue Bike');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Red Bike',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Location'),
        'Tagum City',
      );
      await tester.tap(find.text('Completed'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Red Bike'), findsOneWidget);
      expect(find.textContaining('Tagum City'), findsOneWidget);
      expect(find.text('Blue Bike'), findsNothing);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Listing updated'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('report sends the chosen reason and confirms', (tester) async {
      late _RecordingRepo repo;
      final db = await _pump(
        tester,
        const AllItemsScreen(),
        listings: const [_lamp],
        repo: (db) => repo = _RecordingRepo(db),
      );
      await _openMenu(tester, 'Vintage Lamp');
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(FilledButton, 'Submit report');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.tap(find.text(reportReasonLabel(ReportReason.scam)));
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repo.reports.single.$1, 'lamp');
      expect(repo.reports.single.$2, ReportReason.scam);
      expect(find.textContaining('Thanks'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('reporting twice says it was already reported', (tester) async {
      final db = await _pump(
        tester,
        const AllItemsScreen(),
        listings: const [_lamp],
        repo: (db) => _RecordingRepo(db, reportResult: false),
      );
      await _openMenu(tester, 'Vintage Lamp');
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(reportReasonLabel(ReportReason.spam)));
      await tester.pump();
      final submit = find.widgetWithText(FilledButton, 'Submit report');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.textContaining('already reported'), findsOneWidget);
      await _dispose(tester, db);
    });
  });
}
