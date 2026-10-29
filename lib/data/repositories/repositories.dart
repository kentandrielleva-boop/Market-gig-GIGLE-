import 'dart:async';

import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:marketplace_gig/domain/models/models.dart';

abstract class ListingRepository {
  Stream<List<Listing>> watchFeed();
  Stream<List<Listing>> watchSaved();
  Stream<List<Listing>> watchPassed();
  Stream<List<Listing>> watchMyListings();

  /// Another user's active (publicly visible) items and gigs.
  Stream<List<Listing>> watchListingsByOwner(String ownerId);

  /// Live lookup of one listing by id, independent of the feed's swipe
  /// filtering, so the detail screen keeps working after a save/pass.
  /// Emits null once the listing no longer exists.
  Stream<Listing?> watchListingById(String listingId);
  Future<void> pass(String listingId);
  Future<void> save(String listingId);
  Future<void> restorePassed(String listingId);
  Future<void> createListing(Listing listing);

  /// Persists the editable fields (title, price, description, duration,
  /// remote-only, status) of a listing the caller owns.
  Future<void> updateListing(Listing listing);

  Future<void> deleteListing(String listingId);

  /// Files a report against someone else's listing and hides it from the
  /// reporter. Returns false if this user already reported it.
  Future<bool> reportListing(
    Listing listing,
    ReportReason reason, {
    String? details,
  });

  /// Uploads a local image to Cloudinary and returns its secure URL.
  /// Callers pass through already-remote (`http`) URLs unchanged.
  Future<String> uploadListingImage(String filePath, {String? listingId});
}

abstract class ChatRepository {
  Stream<List<Conversation>> watchConversations();
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50});
  Stream<DateTime?> watchTyping(String conversationId);
  Future<void> setTyping(String conversationId, bool isTyping);
  Future<List<Message>> getMessagesPage(
    String conversationId, {
    required int limit,
    required int offset,
  });
  Future<int> countMessages(String conversationId);

  /// [id] lets the UI reuse its optimistic row's id so the live Firestore
  /// echo of this message dedupes against it.
  Future<void> sendMessage(String conversationId, String text, {String? id});

  /// Opens (or reuses) the caller's thread with the owner of [listing] and
  /// returns its conversation id. One thread per listing per buyer.
  Future<String> startConversation(Listing listing);

  /// Opens (or reuses) the caller's one-to-one thread with [otherUserId],
  /// not tied to any listing. Throws [MessagingBlockedException] when either
  /// side has blocked the other.
  Future<String> startDirectConversation(String otherUserId);

  /// Marks the thread read up to now for the signed-in user (clears the
  /// unread badge and drives the other side's "Seen" marker). Best-effort.
  Future<void> markRead(String conversationId);

  /// Archives/unarchives the thread for the signed-in user only.
  Future<void> setArchived(String conversationId, bool archived);
}

abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile();

  /// Another user's public profile (listing detail → seller card).
  /// Emits null when no profile exists for [uid].
  Stream<UserProfile?> watchUserProfile(String uid);

  /// One page of reviews about [target] (a user or a listing), filtered and
  /// ordered per [query].
  Stream<List<Review>> watchReviews(
    ReviewTarget target, {
    ReviewQuery query = firstReviewPage,
  });

  /// The signed-in user's own review of [target], if any. Looked up by its
  /// fixed doc id, so paging or filters can never hide it.
  Stream<Review?> watchMyReview(ReviewTarget target);

  /// Exact review counts per star for [target]; index 0 is 1★.
  Stream<List<int>> watchReviewDistribution(ReviewTarget target);

  /// Chats the signed-in user shares with [otherUid] in which a message was
  /// sent; a user review must cite one to be accepted (verified reviews).
  Stream<List<ReviewContext>> watchReviewContexts(String otherUid);

  /// Whether the signed-in user has messaged the owner about [listingId],
  /// which reviewing the listing requires.
  Stream<bool> watchCanReviewListing(String listingId);

  /// Rates [revieweeId] as the signed-in user, citing the chat [context].
  /// One review per pair: a repeat edits the caller's existing review
  /// (keeping its original date). Throws [ArgumentError] for a self-review.
  Future<void> addReview({
    required String revieweeId,
    required ReviewContext context,
    required int rating,
    required String comment,
  });

  /// Deletes the signed-in user's review of [revieweeId] (if any) and takes
  /// it out of their rating average, so they can review them again later.
  Future<void> deleteReview(String revieweeId);

  /// Rates [listing] as the signed-in user (requires a chat about it, see
  /// [watchCanReviewListing]). One review per user per listing: a repeat
  /// edits the caller's existing review (keeping its original date).
  /// Throws [ArgumentError] when the caller owns the listing.
  Future<void> addListingReview({
    required Listing listing,
    required int rating,
    required String comment,
  });

  /// Deletes the signed-in user's review of [listingId] (if any).
  Future<void> deleteListingReview(String listingId);

  /// Sets (or with an empty/null [reply], removes) the owner's public
  /// response to [review]. Only the reviewed user / listing owner may.
  Future<void> setReviewReply(Review review, String? reply);

  /// Reports someone else's review for moderation. Returns false if the
  /// caller already reported it.
  Future<bool> reportReview(
    Review review,
    ReportReason reason, {
    String? details,
  });

  /// Persists editable profile fields (display name, bio, avatar URL).
  Future<void> updateProfile({
    required String name,
    required String bio,
    required String avatarUrl,
  });

  /// Uploads a local image as the user's avatar and returns its public URL.
  Future<String> uploadAvatar(String filePath);

  /// Stamps server-side Terms & EULA acceptance (profiles.terms_*).
  /// Offline/test doubles may no-op.
  Future<void> recordLegalAcceptance(String version);

  /// Returns the server-side acceptance, if any.
  Future<({DateTime? acceptedAt, String? version})?> fetchLegalAcceptance();

  /// Users the signed-in user has blocked, newest first.
  Stream<List<BlockedUser>> watchBlockedUsers();

  /// Blocks [uid]: neither side can message the other and the blocker stops
  /// seeing their listings and threads. [name]/[avatarUrl] label the entry
  /// in the blocked-users list.
  Future<void> blockUser(String uid, {String name = '', String avatarUrl = ''});

  Future<void> unblockUser(String uid);

  /// Files a report against another user. Returns false if the caller
  /// already reported them.
  Future<bool> reportUser(
    String uid,
    ReportReason reason, {
    String? details,
    String? conversationId,
  });
}

class LocalListingRepository implements ListingRepository {
  LocalListingRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Listing>> watchFeed() => _db.watchFeed();

  @override
  Stream<List<Listing>> watchSaved() => _db.watchSaved();

  @override
  Stream<List<Listing>> watchPassed() => _db.watchPassed();

  @override
  Stream<List<Listing>> watchMyListings() => _db.watchMyListings();

  @override
  Stream<List<Listing>> watchListingsByOwner(String ownerId) =>
      Stream.value(const []);

  @override
  Stream<Listing?> watchListingById(String listingId) =>
      _db.watchListingById(listingId);

  @override
  Future<void> pass(String listingId) =>
      _db.setSwipe(listingId, SwipeActionType.passed);

  @override
  Future<void> save(String listingId) =>
      _db.setSwipe(listingId, SwipeActionType.saved);

  @override
  Future<void> restorePassed(String listingId) => _db.removeSwipe(listingId);

  @override
  Future<void> createListing(Listing listing) => _db.insertListing(listing);

  @override
  Future<void> updateListing(Listing listing) => _db.updateListing(listing);

  @override
  Future<void> deleteListing(String listingId) => _db.deleteListing(listingId);

  @override
  Future<bool> reportListing(
    Listing listing,
    ReportReason reason, {
    String? details,
  }) {
    // Reports live in Firestore; the Drift implementation only keeps widget
    // tests offline.
    throw UnimplementedError(
      'Reporting listings is only supported by FirebaseListingRepository.',
    );
  }

  @override
  Future<String> uploadListingImage(
    String filePath, {
    String? listingId,
  }) async {
    // No remote storage in offline/local mode — keep the local path so the
    // post flow and widget tests stay functional without network access.
    return filePath;
  }
}

class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Conversation>> watchConversations() => _db.watchConversations();

  @override
  Stream<List<Message>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) => _db.watchMessages(conversationId, limit: limit);

  @override
  Stream<DateTime?> watchTyping(String conversationId) => const Stream.empty();

  @override
  Future<void> setTyping(String conversationId, bool isTyping) async {}

  @override
  Future<List<Message>> getMessagesPage(
    String conversationId, {
    required int limit,
    required int offset,
  }) {
    return _db.getMessagesPage(conversationId, limit: limit, offset: offset);
  }

  @override
  Future<int> countMessages(String conversationId) =>
      _db.countMessages(conversationId);

  @override
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? id,
  }) async {
    final message = Message(
      id: id ?? const Uuid().v4(),
      conversationId: conversationId,
      text: text,
      isOutgoing: true,
      sentAt: DateTime.now(),
    );
    await _db.insertMessages([message]);
    await _db.updateConversationLastMessage(conversationId, text);
  }

  // Offline mode has a single user and no seller profiles, so the thread is
  // keyed by listing alone and labelled generically.
  @override
  Future<String> startConversation(Listing listing) async {
    final id = 'local-${listing.id}';
    if (await _db.getConversation(id) == null) {
      await _db.insertConversations([
        Conversation(
          id: id,
          participantName: listing.isGig ? 'Gig poster' : 'Seller',
          participantAvatar: '',
          lastMessage: '',
          timestamp: DateTime.now(),
          unreadCount: 0,
          role: listing.isGig
              ? ParticipantRole.gigClient
              : ParticipantRole.seller,
          listingTitle: listing.title,
          listingId: listing.id,
          otherUserId: listing.ownerId,
        ),
      ]);
    }
    return id;
  }

  @override
  Future<String> startDirectConversation(String otherUserId) async {
    final id = 'local-dm-$otherUserId';
    if (await _db.getConversation(id) == null) {
      await _db.insertConversations([
        Conversation(
          id: id,
          participantName: 'User',
          participantAvatar: '',
          lastMessage: '',
          timestamp: DateTime.now(),
          unreadCount: 0,
          role: ParticipantRole.direct,
          listingTitle: '',
          listingId: '',
          otherUserId: otherUserId,
        ),
      ]);
    }
    return id;
  }

  @override
  Future<void> markRead(String conversationId) =>
      _db.setConversationUnread(conversationId, 0);

  @override
  Future<void> setArchived(String conversationId, bool archived) =>
      _db.setConversationArchived(conversationId, archived);
}

/// Applies [query] to an in-memory review list (offline repository):
/// star filter, then order (ties newest first), then the page limit.
List<Review> applyReviewQuery(List<Review> reviews, ReviewQuery query) {
  final stars = query.stars;
  final filtered = [
    for (final review in reviews)
      if (stars == null || review.rating == stars) review,
  ];
  int newestFirst(Review a, Review b) => b.createdAt.compareTo(a.createdAt);
  filtered.sort(switch (query.sort) {
    ReviewSort.recent => newestFirst,
    ReviewSort.highest => (a, b) {
      final byRating = b.rating.compareTo(a.rating);
      return byRating != 0 ? byRating : newestFirst(a, b);
    },
    ReviewSort.lowest => (a, b) {
      final byRating = a.rating.compareTo(b.rating);
      return byRating != 0 ? byRating : newestFirst(a, b);
    },
  });
  return filtered.take(query.limit).toList();
}

/// Review counts per star; index 0 is 1★.
List<int> reviewDistributionOf(Iterable<Review> reviews) {
  final counts = List.filled(5, 0);
  for (final review in reviews) {
    counts[review.rating.clamp(1, 5) - 1]++;
  }
  return counts;
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(
    this._db, {
    this.userId = 'local-user',
    this.chattedWith,
    this.chattedListings,
  });

  final AppDatabase _db;

  /// The offline "signed-in" user, recorded as the author of reviews.
  final String userId;

  /// Users / listings the offline user has chatted about, gating reviews the
  /// way the Firebase rules do. Null allows everything (most tests).
  final Set<String>? chattedWith;
  final Set<String>? chattedListings;

  // User reviews live on the single Drift profile row; product reviews and
  // review reports are kept in memory: the offline repository only backs
  // widget tests, which need the write → list round trip but not persistence.
  final _listingReviews = <String, List<Review>>{};
  final _reviewsChanged = StreamController<void>.broadcast();

  /// Reviews reported through [reportReview]; exposed for test assertions.
  final reportedReviewIds = <String>{};

  // Blocks and user reports are in memory for the same reason.
  final _blocked = <String, BlockedUser>{};
  final _blockedChanged = StreamController<void>.broadcast();

  /// Users reported through [reportUser]; exposed for test assertions.
  final reportedUserIds = <String>{};

  @override
  Stream<UserProfile?> watchProfile() {
    return _db.select(_db.userProfilesTable).watch().asyncMap((rows) async {
      if (rows.isEmpty) return null;
      final row = rows.first;
      return UserProfile(
        id: row.id,
        name: row.name,
        avatarUrl: row.avatarUrl,
        rating: row.rating,
        reviewCount: row.reviewCount,
        listingsCount: row.listingsCount,
        soldCount: row.soldCount,
        memberSince: row.memberSince,
      );
    });
  }

  // Offline mode keeps a single profile row, so "someone else's" profile can
  // only resolve when the ids match; the UI falls back to a placeholder.
  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _db.select(_db.userProfilesTable).watch().map((rows) {
      final match = rows.where((r) => r.id == uid);
      if (match.isEmpty) return null;
      final row = match.first;
      return UserProfile(
        id: row.id,
        name: row.name,
        avatarUrl: row.avatarUrl,
        rating: row.rating,
        reviewCount: row.reviewCount,
        listingsCount: row.listingsCount,
        soldCount: row.soldCount,
        memberSince: row.memberSince,
      );
    });
  }

  /// Offline user reviews exist only for the stored Drift profile.
  Future<List<Review>> _userReviews(String uid) async {
    final profile = await _db.getProfile();
    if (profile == null || profile.id != uid) return const [];
    return [
      for (final review in await _db.getReviews())
        review.copyWith(kind: ReviewKind.user, targetId: uid, ownerId: uid),
    ];
  }

  /// Persists [reviews] on the Drift profile row and recomputes its rating,
  /// like the Firebase transaction moves the aggregate.
  Future<void> _saveUserReviews(String uid, List<Review> reviews) async {
    final profile = await _db.getProfile();
    if (profile == null || profile.id != uid) {
      throw StateError('Offline reviews only exist for the stored profile.');
    }
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
    await _db.insertProfile(
      UserProfile(
        id: profile.id,
        name: profile.name,
        bio: profile.bio,
        avatarUrl: profile.avatarUrl,
        rating: average,
        reviewCount: reviews.length,
        listingsCount: profile.listingsCount,
        soldCount: profile.soldCount,
        memberSince: profile.memberSince,
      ),
      reviews,
    );
    _reviewsChanged.add(null);
  }

  Future<List<Review>> _allReviews(ReviewTarget target) async {
    return switch (target.kind) {
      ReviewKind.user => _userReviews(target.id),
      ReviewKind.listing => List.of(_listingReviews[target.id] ?? const []),
    };
  }

  Future<void> _saveReviews(ReviewTarget target, List<Review> reviews) async {
    switch (target.kind) {
      case ReviewKind.user:
        await _saveUserReviews(target.id, reviews);
      case ReviewKind.listing:
        _listingReviews[target.id] = reviews;
        _reviewsChanged.add(null);
    }
  }

  /// Emits [read] now and again after every local review change.
  Stream<T> _watch<T>(Future<T> Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    Future<void> emit() async {
      final value = await read();
      if (!controller.isClosed) controller.add(value);
    }

    controller = StreamController<T>(
      onListen: () {
        changes = _reviewsChanged.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  /// Inserts [review] as the caller's (replacing their earlier one).
  Future<void> _upsertMine(ReviewTarget target, Review review) async {
    final reviews = [...await _allReviews(target)]
      ..removeWhere((r) => r.reviewerId == userId);
    await _saveReviews(target, [review, ...reviews]);
  }

  Future<void> _deleteMine(ReviewTarget target) async {
    final reviews = await _allReviews(target);
    final kept = reviews.where((r) => r.reviewerId != userId).toList();
    if (kept.length != reviews.length) await _saveReviews(target, kept);
  }

  Future<Review?> _mine(ReviewTarget target) async {
    for (final review in await _allReviews(target)) {
      if (review.reviewerId == userId) return review;
    }
    return null;
  }

  @override
  Stream<List<Review>> watchReviews(
    ReviewTarget target, {
    ReviewQuery query = firstReviewPage,
  }) => _watch(() async => applyReviewQuery(await _allReviews(target), query));

  @override
  Stream<Review?> watchMyReview(ReviewTarget target) =>
      _watch(() => _mine(target));

  @override
  Stream<List<int>> watchReviewDistribution(ReviewTarget target) =>
      _watch(() async => reviewDistributionOf(await _allReviews(target)));

  @override
  Stream<List<ReviewContext>> watchReviewContexts(String otherUid) {
    final chatted = chattedWith == null || chattedWith!.contains(otherUid);
    return Stream.value([
      if (chatted && otherUid != userId)
        ReviewContext(conversationId: 'dm_${userId}_$otherUid'),
    ]);
  }

  @override
  Stream<bool> watchCanReviewListing(String listingId) => Stream.value(
    chattedListings == null || chattedListings!.contains(listingId),
  );

  @override
  Future<void> addReview({
    required String revieweeId,
    required ReviewContext context,
    required int rating,
    required String comment,
  }) async {
    if (revieweeId == userId) {
      throw ArgumentError.value(
        revieweeId,
        'revieweeId',
        "can't rate yourself",
      );
    }
    final target = (kind: ReviewKind.user, id: revieweeId);
    final existing = await _mine(target);
    await _upsertMine(
      target,
      Review(
        id: '${userId}_$revieweeId',
        raterName: 'You',
        rating: rating,
        comment: comment.trim(),
        listingTitle: context.listingTitle,
        createdAt: existing?.createdAt ?? DateTime.now(),
        reviewerId: userId,
        updatedAt: existing == null ? null : DateTime.now(),
        kind: ReviewKind.user,
        targetId: revieweeId,
        ownerId: revieweeId,
        verified: true,
        conversationId: context.conversationId,
        reply: existing?.reply ?? '',
        replyAt: existing?.replyAt,
      ),
    );
  }

  @override
  Future<void> deleteReview(String revieweeId) =>
      _deleteMine((kind: ReviewKind.user, id: revieweeId));

  @override
  Future<void> addListingReview({
    required Listing listing,
    required int rating,
    required String comment,
  }) async {
    if (listing.ownerId == userId) {
      throw ArgumentError.value(
        listing.id,
        'listing',
        "can't review your own listing",
      );
    }
    final target = (kind: ReviewKind.listing, id: listing.id);
    final existing = await _mine(target);
    await _upsertMine(
      target,
      Review(
        id: '${userId}_${listing.id}',
        raterName: 'You',
        rating: rating,
        comment: comment.trim(),
        listingTitle: listing.title,
        createdAt: existing?.createdAt ?? DateTime.now(),
        reviewerId: userId,
        updatedAt: existing == null ? null : DateTime.now(),
        kind: ReviewKind.listing,
        targetId: listing.id,
        ownerId: listing.ownerId,
        verified: true,
        conversationId: '${listing.id}_$userId',
        reply: existing?.reply ?? '',
        replyAt: existing?.replyAt,
      ),
    );
  }

  @override
  Future<void> deleteListingReview(String listingId) =>
      _deleteMine((kind: ReviewKind.listing, id: listingId));

  @override
  Future<void> setReviewReply(Review review, String? reply) async {
    if (review.ownerId != userId) {
      throw StateError('Only the reviewed user or listing owner can reply.');
    }
    final target = (kind: review.kind, id: review.targetId);
    final text = (reply ?? '').trim();
    final reviews = [
      for (final r in await _allReviews(target))
        if (r.id != review.id)
          r
        else if (text.isEmpty)
          r.copyWith(clearReply: true)
        else
          r.copyWith(reply: text, replyAt: DateTime.now()),
    ];
    await _saveReviews(target, reviews);
  }

  @override
  Future<bool> reportReview(
    Review review,
    ReportReason reason, {
    String? details,
  }) async {
    if (review.reviewerId == userId) {
      throw ArgumentError('You cannot report your own review.');
    }
    return reportedReviewIds.add('${review.kind.name}_${review.id}');
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    required String avatarUrl,
  }) {
    // Profile editing lives in the Firebase profile repository; the Drift
    // implementation is only used to keep widget tests offline.
    throw UnimplementedError(
      'Updating profiles is only supported by FirebaseProfileRepository.',
    );
  }

  @override
  Future<String> uploadAvatar(String filePath) {
    throw UnimplementedError(
      'Uploading avatars is only supported by FirebaseProfileRepository.',
    );
  }

  @override
  Future<void> recordLegalAcceptance(String version) async {
    // Offline/test double: local SharedPreferences is the source of truth.
  }

  @override
  Future<({DateTime? acceptedAt, String? version})?>
  fetchLegalAcceptance() async {
    return null;
  }

  @override
  Stream<List<BlockedUser>> watchBlockedUsers() async* {
    yield _sortedBlocked();
    await for (final _ in _blockedChanged.stream) {
      yield _sortedBlocked();
    }
  }

  List<BlockedUser> _sortedBlocked() => List.unmodifiable(
    _blocked.values.toList()
      ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt)),
  );

  @override
  Future<void> blockUser(
    String uid, {
    String name = '',
    String avatarUrl = '',
  }) async {
    if (uid == userId) throw ArgumentError('You cannot block yourself.');
    _blocked[uid] = BlockedUser(
      id: uid,
      name: name.isEmpty ? 'User' : name,
      avatarUrl: avatarUrl,
      blockedAt: DateTime.now(),
    );
    _blockedChanged.add(null);
  }

  @override
  Future<void> unblockUser(String uid) async {
    if (_blocked.remove(uid) != null) _blockedChanged.add(null);
  }

  @override
  Future<bool> reportUser(
    String uid,
    ReportReason reason, {
    String? details,
    String? conversationId,
  }) async => reportedUserIds.add(uid);
}
