import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/notifications/push_service.dart';
import 'package:marketplace_gig/core/storage/cloudinary_uploader.dart';
import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:marketplace_gig/data/repositories/firebase_chat_repository.dart';
import 'package:marketplace_gig/data/repositories/firebase_listing_repository.dart';
import 'package:marketplace_gig/data/repositories/firebase_profile_repository.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/firebase_options.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Bootstraps Firebase once. `Firebase.initializeApp` is idempotent-safe:
/// repeated calls with the same options return the existing app instead of
/// throwing, so the bootstrap retry button and hot restart just work.
Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline cache helps the chat backfill and feed survive flaky networks.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Tracks Firebase initialization so the UI can show a branded splash while
/// Firebase restores the session on slow storage. Completed after
/// `Firebase.initializeApp` succeeds; errors are surfaced to the bootstrap UI.
final firebaseInitProvider = FutureProvider<void>((ref) async {
  await initializeFirebase();
});

final authGatewayProvider = Provider<AuthGateway>((ref) {
  // Depend on init so this rebuilds after Firebase.initializeApp completes.
  final init = ref.watch(firebaseInitProvider);
  if (init.isLoading) throw StateError('Firebase initializing');
  if (init.hasError) throw init.error!;
  return FirebaseAuthGateway(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Stream of the signed-in user id (null when signed out). The router guard
/// listens to this to redirect between the app and the auth screens.
final authSessionProvider = StreamProvider<String?>((ref) {
  return ref.watch(authGatewayProvider).userIdChanges;
});

final currentUserIdProvider = Provider<String>((ref) {
  final id = ref.watch(authGatewayProvider).currentUserId;
  if (id == null) {
    throw StateError('Firebase auth is not signed in.');
  }
  return id;
});

/// Whether the signed-in user's email is verified. The router keeps
/// unverified users on `/verify-email` until this flips true.
final emailVerifiedProvider = StreamProvider<bool>((ref) {
  return ref.watch(authGatewayProvider).emailVerifiedChanges;
});

final cloudinaryProvider = Provider<CloudinaryUploader>((ref) {
  return const CloudinaryUploader(
    cloudName: CloudinaryConfig.cloudName,
    uploadPreset: CloudinaryConfig.uploadPreset,
  );
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return FirebaseListingRepository(
    FirebaseFirestore.instance,
    ref.watch(cloudinaryProvider),
    ref.watch(currentUserIdProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dbAsync = ref.watch(appDatabaseProvider);
  final db = dbAsync.value;
  if (db == null) return _PendingChatRepository();
  final repo = FirebaseChatRepository(
    FirebaseFirestore.instance,
    db,
    ref.watch(currentUserIdProvider),
  );
  ref.onDispose(() => unawaited(repo.dispose()));
  return repo;
});

class _PendingChatRepository implements ChatRepository {
  @override
  Stream<List<Conversation>> watchConversations() => const Stream.empty();

  @override
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) => const Stream.empty();

  @override
  Stream<DateTime?> watchTyping(String conversationId) => const Stream.empty();

  @override
  Future<void> setTyping(String conversationId, bool isTyping) async {}

  @override
  Future<List<Message>> getMessagesPage(
    String conversationId, {
    required int limit,
    required int offset,
  }) async => const [];

  @override
  Future<int> countMessages(String conversationId) async => 0;

  @override
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? id,
  }) async {}

  @override
  Future<String> startConversation(Listing listing) =>
      Future.error(StateError('Chat is still starting up — try again.'));

  @override
  Future<String> startDirectConversation(String otherUserId) =>
      Future.error(StateError('Chat is still starting up — try again.'));

  @override
  Future<void> markRead(String conversationId) async {}

  @override
  Future<void> setArchived(String conversationId, bool archived) async {}
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository(
    FirebaseFirestore.instance,
    ref.watch(cloudinaryProvider),
    FirebaseAuth.instance,
    ref.watch(currentUserIdProvider),
  );
});

final homeFiltersProvider = StateProvider<HomeFilters>(
  (ref) => const HomeFilters(),
);

final feedListingsProvider = StreamProvider<List<Listing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  final filters = ref.watch(homeFiltersProvider);
  final blocked = ref.watch(blockedUserIdsProvider);
  return repo.watchFeed().map(
    (list) => _applyFilters(
      blocked.isEmpty
          ? list
          : list.where((l) => !blocked.contains(l.ownerId)).toList(),
      filters,
    ),
  );
});

/// Users the signed-in user blocked (Settings → Blocked users).
final blockedUsersProvider = StreamProvider<List<BlockedUser>>((ref) {
  return ref.watch(profileRepositoryProvider).watchBlockedUsers();
});

/// Uids from [blockedUsersProvider]; empty while loading so nothing blocks
/// rendering. Used to hide blocked users' listings and threads.
final blockedUserIdsProvider = Provider<Set<String>>((ref) {
  final users = ref.watch(blockedUsersProvider).value ?? const [];
  return {for (final u in users) u.id};
});

final savedListingsProvider = StreamProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).watchSaved();
});

final passedListingsProvider = StreamProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).watchPassed();
});

final myListingsProvider = StreamProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).watchMyListings();
});

/// Single-listing lookup backing the `/listing/:id` detail route, so a deep
/// link resolves without a card having passed the object along.
final listingByIdProvider = StreamProvider.family<Listing?, String>((
  ref,
  listingId,
) {
  return ref.watch(listingRepositoryProvider).watchListingById(listingId);
});

/// The listing owner's public profile, shown in the detail screen's seller
/// card and on `/user/:uid`. Null when no profile exists yet.
final userProfileByIdProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(profileRepositoryProvider).watchUserProfile(uid);
});

/// One page of reviews about a user or listing (see [ReviewQuery]).
final reviewPageProvider = StreamProvider.autoDispose
    .family<List<Review>, (ReviewTarget, ReviewQuery)>((ref, args) {
      final (target, query) = args;
      return ref
          .watch(profileRepositoryProvider)
          .watchReviews(target, query: query);
    });

/// The viewer's own review of a user or listing, wherever it would page.
final myReviewProvider = StreamProvider.autoDispose
    .family<Review?, ReviewTarget>((ref, target) {
      return ref.watch(profileRepositoryProvider).watchMyReview(target);
    });

/// Exact per-star review counts (index 0 = 1★) for the distribution bars.
final reviewDistributionProvider = StreamProvider.autoDispose
    .family<List<int>, ReviewTarget>((ref, target) {
      return ref
          .watch(profileRepositoryProvider)
          .watchReviewDistribution(target);
    });

/// Chats with a user that a (verified) review of them can cite.
final reviewContextsProvider = StreamProvider.autoDispose
    .family<List<ReviewContext>, String>((ref, uid) {
      return ref.watch(profileRepositoryProvider).watchReviewContexts(uid);
    });

/// Whether the viewer has messaged about a listing, which reviewing needs.
final canReviewListingProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, listingId) {
      return ref
          .watch(profileRepositoryProvider)
          .watchCanReviewListing(listingId);
    });

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).watchConversations();
});

final threadMessagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final threadTypingProvider = StreamProvider.family<DateTime?, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatRepositoryProvider).watchTyping(conversationId);
});

/// Initializes FCM after sign-in (token store + foreground handler).
/// No-op until a Blaze sender backend exists; safe to call on Spark.
final pushInitProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(authGatewayProvider).currentUserId;
  if (uid == null) return;
  try {
    await ref.watch(firebaseInitProvider.future);
    await initPushNotifications(FirebaseFirestore.instance, uid);
  } catch (_) {
    // Push unavailable in tests/emulators — chat still works.
  }
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

/// Inbox threads: not archived by the viewer and not with a blocked user.
final activeConversationsProvider = Provider<AsyncValue<List<Conversation>>>((
  ref,
) {
  final blocked = ref.watch(blockedUserIdsProvider);
  return ref
      .watch(conversationsProvider)
      .whenData(
        (items) => items
            .where((c) => !c.isArchived && !blocked.contains(c.otherUserId))
            .toList(),
      );
});

/// Threads the viewer archived (blocked users' threads stay hidden).
final archivedConversationsProvider = Provider<AsyncValue<List<Conversation>>>((
  ref,
) {
  final blocked = ref.watch(blockedUserIdsProvider);
  return ref
      .watch(conversationsProvider)
      .whenData(
        (items) => items
            .where((c) => c.isArchived && !blocked.contains(c.otherUserId))
            .toList(),
      );
});

final inboxSearchProvider = StateProvider<String>((ref) => '');

final filteredConversationsProvider = Provider<AsyncValue<List<Conversation>>>((
  ref,
) {
  final query = ref.watch(inboxSearchProvider).toLowerCase();
  final conversations = ref.watch(activeConversationsProvider);
  return conversations.whenData((items) {
    if (query.isEmpty) return items;
    return items
        .where(
          (c) =>
              c.participantName.toLowerCase().contains(query) ||
              c.listingTitle.toLowerCase().contains(query) ||
              c.lastMessage.toLowerCase().contains(query),
        )
        .toList();
  });
});

class PostFormState {
  const PostFormState({
    this.type = ListingType.item,
    this.title = '',
    this.priceText = '',
    this.description = '',
    this.location = kDefaultListingLocation,
    this.photoPaths = const [],
    this.duration,
    this.remoteOnly = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final ListingType type;
  final String title;
  final String priceText;
  final String description;
  final String location;
  final List<String> photoPaths;
  final String? duration;
  final bool remoteOnly;
  final bool isSubmitting;

  /// User-facing error from a failed submit, cleared on any subsequent edit.
  final String? errorMessage;

  double? get parsedPrice {
    final cleaned = priceText.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  bool get canSubmit =>
      photoPaths.isNotEmpty &&
      title.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      priceText.trim().isNotEmpty &&
      parsedPrice != null &&
      !isSubmitting;

  PostFormState copyWith({
    ListingType? type,
    String? title,
    String? priceText,
    String? description,
    String? location,
    List<String>? photoPaths,
    String? duration,
    bool? remoteOnly,
    bool? isSubmitting,
    String? errorMessage,
    bool clearDuration = false,
    bool clearErrorMessage = false,
  }) {
    return PostFormState(
      type: type ?? this.type,
      title: title ?? this.title,
      priceText: priceText ?? this.priceText,
      description: description ?? this.description,
      location: location ?? this.location,
      photoPaths: photoPaths ?? this.photoPaths,
      duration: clearDuration ? null : (duration ?? this.duration),
      remoteOnly: remoteOnly ?? this.remoteOnly,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class PostFormNotifier extends StateNotifier<PostFormState> {
  PostFormNotifier(this._ref) : super(const PostFormState());

  final Ref _ref;

  void setType(ListingType type) {
    state = state.copyWith(
      type: type,
      clearDuration: type == ListingType.item,
      clearErrorMessage: true,
    );
  }

  void setTitle(String value) =>
      state = state.copyWith(title: value, clearErrorMessage: true);
  void setPrice(String value) =>
      state = state.copyWith(priceText: value, clearErrorMessage: true);
  void setDescription(String value) =>
      state = state.copyWith(description: value, clearErrorMessage: true);
  void setLocation(String value) =>
      state = state.copyWith(location: value, clearErrorMessage: true);
  void setDuration(String? value) =>
      state = state.copyWith(duration: value, clearErrorMessage: true);
  void setRemoteOnly(bool value) =>
      state = state.copyWith(remoteOnly: value, clearErrorMessage: true);

  void addPhotos(List<String> paths) {
    final merged = [...state.photoPaths, ...paths].take(5).toList();
    state = state.copyWith(photoPaths: merged, clearErrorMessage: true);
  }

  void removePhotoAt(int index) {
    final next = [...state.photoPaths]..removeAt(index);
    state = state.copyWith(photoPaths: next, clearErrorMessage: true);
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final price = state.parsedPrice!;
      final repository = _ref.read(listingRepositoryProvider);
      final listingId = const Uuid().v4();
      // Upload local photos to Cloudinary first so
      // `listings.image_urls` stores public URLs, not device file paths.
      final imageUrls = <String>[];
      for (final path in state.photoPaths) {
        imageUrls.add(
          await repository.uploadListingImage(path, listingId: listingId),
        );
      }
      final listing = Listing(
        id: listingId,
        type: state.type,
        title: state.title.trim(),
        price: price,
        description: state.description.trim(),
        imageUrls: imageUrls,
        category: state.type == ListingType.item ? 'General' : 'Services',
        location: state.location.trim(),
        duration: state.duration,
        remoteOnly: state.remoteOnly,
        ownerId: 'local-user',
      );
      await repository.createListing(listing);
      state = const PostFormState();
      return true;
    } catch (error) {
      // Keep the user's input so it is not lost, surface a readable message,
      // and log the underlying cause for debugging.
      debugPrint('Failed to create listing: $error');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not post your listing. Please try again.',
      );
      return false;
    }
  }
}

final postFormProvider = StateNotifierProvider<PostFormNotifier, PostFormState>(
  (ref) {
    return PostFormNotifier(ref);
  },
);

List<Listing> _applyFilters(List<Listing> list, HomeFilters filters) {
  return list.where((listing) {
    if (filters.type != null && listing.type != filters.type) return false;
    if (filters.category != null && listing.category != filters.category) {
      return false;
    }
    if (filters.minPrice != null && listing.price < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null && listing.price > filters.maxPrice!) {
      return false;
    }
    return true;
  }).toList();
}

Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'marketplace_gig.sqlite'));
  final db = AppDatabase(NativeDatabase.createInBackground(file));
  // Don't block first frame on the seed check; run it in the background
  // so low-end devices don't sit on a synchronous transaction. Failures are
  // benign and will be retried next launch.
  unawaited(
    seedDatabaseIfNeeded(db).catchError((Object e) {
      debugPrint('seedDatabaseIfNeeded failed: $e');
    }),
  );
  return db;
}

/// Previously seeded sample data (seed_data.dart) — now removed. The app
/// starts empty on first launch. Migrated installs that already contain
/// legacy seeded conversations (conv-1..5 / seed-*) are cleaned once so
/// the inbox also starts empty but real user conversations (Uuid v4) are kept.
Future<void> seedDatabaseIfNeeded(AppDatabase db) async {
  if (await db.isSeeded()) {
    try {
      final rows = await db.select(db.conversationsTable).get();
      final seededIds = rows
          .where(
            (r) => r.id.startsWith('conv-') || r.listingId.startsWith('seed-'),
          )
          .map((r) => r.id)
          .toList();
      if (seededIds.isNotEmpty) {
        await (db.delete(
          db.messagesTable,
        )..where((t) => t.conversationId.isIn(seededIds))).go();
        await (db.delete(
          db.conversationsTable,
        )..where((t) => t.id.isIn(seededIds))).go();
      }
    } catch (e) {
      debugPrint('seed migration cleanup failed: $e');
    }
    return;
  }
  await db.markSeeded();
}
