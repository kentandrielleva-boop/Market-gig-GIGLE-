import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_gig/app.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/legal/legal_consent_providers.dart';
import 'package:marketplace_gig/features/legal/legal_docs.dart';
import 'package:marketplace_gig/features/legal/legal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test double that pretends a signed-in, verified user exists, so the router
/// guard lets the app into /home without touching the network.
class _FakeAuthGateway implements AuthGateway {
  @override
  Stream<String?> get userIdChanges => Stream.value('test-user');

  @override
  Stream<bool> get emailVerifiedChanges => Stream.value(true);

  @override
  String? get currentUserId => 'test-user';

  @override
  String? get currentEmail => 'test@example.com';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('empty database is marked seeded without sample rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDatabaseIfNeeded(db);
    expect(await db.isSeeded(), isTrue);
  });

  testWidgets('Marketplace app loads home screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await seedDatabaseIfNeeded(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => Future.value(db)),
          firebaseInitProvider.overrideWith((ref) async {}),
          emailVerifiedProvider.overrideWith((ref) => Stream.value(true)),
          // Keep the widget test offline: swap the Firebase-backed repositories
          // for the local Drift implementations and stub the auth session.
          authGatewayProvider.overrideWithValue(_FakeAuthGateway()),
          listingRepositoryProvider.overrideWithValue(
            LocalListingRepository(db),
          ),
          profileRepositoryProvider.overrideWithValue(
            LocalProfileRepository(db),
          ),
          // Legal gate is accepted so the router stays on /home.
          legalAcceptanceProvider.overrideWith(() => _AcceptedLegalNotifier()),
          // Ambient motion off: the shared ticker must not run during
          // pumpAndSettle (it would never settle).
          ambientMotionProvider.overrideWith((_) => AmbientMotion.off),
        ],
        child: const AppBootstrap(child: MarketplaceApp()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gigl'), findsWidgets);

    await db.close();
    await tester.pump();
  });

  testWidgets('LegalScreen renders combined Terms & EULA', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LegalScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text(kLegalTitle), findsOneWidget);
    // Header badge + in-body version stamp both mention the version
    // (SelectableText body counts as a second match).
    expect(find.textContaining('Version $kLegalVersion'), findsWidgets);
    expect(find.textContaining('LICENSE (EULA)'), findsWidgets);
  });

  test('legal pref keys are versioned and per-user', () {
    expect(legalAcceptedKey('u1'), isNot(legalAcceptedKey('u2')));
    expect(legalAcceptedKey(null), contains('guest'));
    expect(legalVersionKey('u1'), contains('u1'));
  });

  test('accept() persists versioned acceptance locally', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWithValue(_FakeAuthGateway()),
        authSessionProvider.overrideWith((ref) => Stream.value('test-user')),
        profileRepositoryProvider.overrideWithValue(_NoopProfileRepository()),
      ],
    );
    addTearDown(container.dispose);
    // Keep a subscription alive: a bare read(provider.future) with no
    // listener lets the container auto-dispose the notifier mid-build.
    container.listen<AsyncValue<bool>>(legalAcceptanceProvider, (_, _) {});
    await container.read(legalAcceptanceProvider.future);
    await container.read(legalAcceptanceProvider.notifier).accept();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(legalAcceptedKey('test-user')), isTrue);
    expect(prefs.getString(legalVersionKey('test-user')), kLegalVersion);
    await expectLater(
      container.read(legalAcceptanceProvider.future),
      completion(isTrue),
    );
  });
}

/// Forces the legal gate open in widget tests.
class _AcceptedLegalNotifier extends LegalAcceptanceNotifier {
  @override
  Future<bool> build() async => true;
}

class _NoopProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> watchProfile() => const Stream.empty();

  @override
  Stream<UserProfile?> watchUserProfile(String uid) => const Stream.empty();

  @override
  Stream<List<Review>> watchReviews(
    ReviewTarget target, {
    ReviewQuery query = firstReviewPage,
  }) => const Stream.empty();

  @override
  Stream<Review?> watchMyReview(ReviewTarget target) => const Stream.empty();

  @override
  Stream<List<int>> watchReviewDistribution(ReviewTarget target) =>
      const Stream.empty();

  @override
  Stream<List<ReviewContext>> watchReviewContexts(String otherUid) =>
      const Stream.empty();

  @override
  Stream<bool> watchCanReviewListing(String listingId) => const Stream.empty();

  @override
  Future<void> addReview({
    required String revieweeId,
    required ReviewContext context,
    required int rating,
    required String comment,
  }) async {}

  @override
  Future<void> setReviewReply(Review review, String? reply) async {}

  @override
  Future<bool> reportReview(
    Review review,
    ReportReason reason, {
    String? details,
  }) async => true;

  @override
  Future<void> deleteReview(String revieweeId) async {}

  @override
  Future<void> deleteListingReview(String listingId) async {}

  @override
  Future<void> addListingReview({
    required Listing listing,
    required int rating,
    required String comment,
  }) async {}

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    required String avatarUrl,
  }) async {}

  @override
  Future<String> uploadAvatar(String filePath) async => '';

  @override
  Future<void> recordLegalAcceptance(String version) async {}

  @override
  Future<({DateTime? acceptedAt, String? version})?>
  fetchLegalAcceptance() async {
    return null;
  }

  @override
  Stream<List<BlockedUser>> watchBlockedUsers() => const Stream.empty();

  @override
  Future<void> blockUser(
    String uid, {
    String name = '',
    String avatarUrl = '',
  }) async {}

  @override
  Future<void> unblockUser(String uid) async {}

  @override
  Future<bool> reportUser(
    String uid,
    ReportReason reason, {
    String? details,
    String? conversationId,
  }) async => true;
}
