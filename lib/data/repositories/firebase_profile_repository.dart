import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marketplace_gig/core/storage/cloudinary_uploader.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/data/repositories/stream_utils.dart';
import 'package:marketplace_gig/domain/models/models.dart';

/// Integer star total behind a profile/listing rating. Profiles written
/// before `rating_sum` existed only carry `rating_avg`; their sum is
/// reconstructed the same way firestore.rules does (`math.round`).
int ratingSumOf(Map<String, dynamic> row) {
  final sum = row['rating_sum'] as num?;
  if (sum != null) return sum.toInt();
  final avg = (row['rating_avg'] as num?)?.toDouble() ?? 0;
  return (avg * ratingCountOf(row)).round();
}

int ratingCountOf(Map<String, dynamic> row) =>
    (row['rating_count'] as num?)?.toInt() ?? 0;

/// Average from the integer aggregate; 0 with no reviews.
double ratingAverageOf(Map<String, dynamic> row) {
  final count = ratingCountOf(row);
  if (count <= 0) return 0;
  return (ratingSumOf(row) / count).clamp(0.0, 5.0);
}

/// [ProfileRepository] backed by Cloud Firestore.
///
/// Profile metadata lives in `profiles/{uid}`. User reviews live in
/// `reviews/{reviewerUid}_{revieweeUid}`, product reviews in
/// `listing_reviews/{reviewerUid}_{listingId}`. Each review write also moves
/// the integer aggregate (`rating_sum` / `rating_count`) on the profile or
/// listing in the same transaction, and the rules verify that delta
/// (ponytail: move to a Cloud Function when concurrent review writes
/// contend on one doc).
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(
    this._db,
    this._images,
    this._auth,
    this._profileOwnerId,
  );

  final FirebaseFirestore _db;
  final CloudinaryUploader _images;
  final FirebaseAuth _auth;
  final String _profileOwnerId;

  static const _reviews = 'reviews';
  static const _listingReviews = 'listing_reviews';
  static const _reviewReports = 'review_reports';
  static const _conversations = 'conversations';
  static const _profiles = 'profiles';
  static const _listings = 'listings';
  static const _blocks = 'blocks';
  static const _userReports = 'user_reports';
  static const _fallbackAvatar = 'https://picsum.photos/seed/profile/200/200';

  DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db.collection(_profiles).doc(_profileOwnerId);

  DocumentReference<Map<String, dynamic>> _profileDocFor(String uid) =>
      _db.collection(_profiles).doc(uid);

  /// Other users' listings are only readable while active (firestore.rules),
  /// and rules aren't filters — an unfiltered query on someone else's
  /// `owner_id` is rejected outright. So count all of our own listings but
  /// only the active ones for anyone else.
  Stream<int> _listingsCountFor(String uid) {
    Query<Map<String, dynamic>> query = _db
        .collection(_listings)
        .where('owner_id', isEqualTo: uid);
    if (uid != _profileOwnerId) {
      query = query.where('status', isEqualTo: ListingStatus.active.index);
    }
    return query.snapshots().map((s) => s.size);
  }

  @override
  Stream<UserProfile?> watchProfile() => _watchUserProfile(_profileOwnerId);

  @override
  Stream<UserProfile?> watchUserProfile(String uid) => _watchUserProfile(uid);

  Stream<UserProfile?> _watchUserProfile(String uid) {
    final row = _profileDocFor(uid).snapshots().map((s) => s.data());
    final listingsCount = _listingsCountFor(uid);
    return combineLatest2(row, listingsCount, (data, listingsTotal) {
      if (data == null) return null;
      return UserProfile(
        id: uid,
        name: _profileName(data),
        bio: data['bio'] as String? ?? '',
        avatarUrl: data['avatar_url'] as String? ?? _fallbackAvatar,
        rating: ratingAverageOf(data),
        reviewCount: ratingCountOf(data),
        listingsCount: listingsTotal,
        soldCount: 0,
        memberSince: _dateTime(data['created_at']),
      );
    });
  }

  CollectionReference<Map<String, dynamic>> _reviewsOf(ReviewKind kind) =>
      _db.collection(kind == ReviewKind.user ? _reviews : _listingReviews);

  /// All reviews about [target] (before paging/filters).
  Query<Map<String, dynamic>> _targetQuery(ReviewTarget target) =>
      _reviewsOf(target.kind).where(
        target.kind == ReviewKind.user ? 'reviewee_id' : 'listing_id',
        isEqualTo: target.id,
      );

  /// Profile or listing doc carrying [target]'s rating aggregate.
  DocumentReference<Map<String, dynamic>> _aggregateDoc(ReviewTarget target) =>
      target.kind == ReviewKind.user
      ? _profileDocFor(target.id)
      : _db.collection(_listings).doc(target.id);

  @override
  Stream<List<Review>> watchReviews(
    ReviewTarget target, {
    ReviewQuery query = firstReviewPage,
  }) {
    var q = _targetQuery(target);
    final stars = query.stars;
    if (stars != null) {
      // A star filter makes rating order moot: newest first within it.
      q = q
          .where('rating', isEqualTo: stars)
          .orderBy('created_at', descending: true);
    } else {
      q = switch (query.sort) {
        ReviewSort.recent => q.orderBy('created_at', descending: true),
        ReviewSort.highest =>
          q
              .orderBy('rating', descending: true)
              .orderBy('created_at', descending: true),
        ReviewSort.lowest =>
          q.orderBy('rating').orderBy('created_at', descending: true),
      };
    }
    return q
        .limit(query.limit)
        .snapshots()
        .map((s) => [for (final doc in s.docs) _reviewFromDoc(doc, target)]);
  }

  @override
  Stream<Review?> watchMyReview(ReviewTarget target) {
    return _reviewsOf(target.kind)
        .doc('${_profileOwnerId}_${target.id}')
        .snapshots()
        .map((snap) => snap.exists ? _reviewFromDoc(snap, target) : null);
  }

  /// Exact per-star counts via `count()` aggregation queries (one cheap
  /// read each). Every review create/edit/delete that changes a rating
  /// moves the target's integer aggregate, so recounting only when that
  /// aggregate changes keeps the bars live without a listener per review.
  @override
  Stream<List<int>> watchReviewDistribution(ReviewTarget target) {
    return _aggregateDoc(target)
        .snapshots()
        .map((snap) {
          final data = snap.data() ?? const <String, dynamic>{};
          return '${ratingSumOf(data)}/${ratingCountOf(data)}';
        })
        .distinct()
        .asyncMap(
          (_) => Future.wait([
            for (var stars = 1; stars <= 5; stars++)
              _targetQuery(target)
                  .where('rating', isEqualTo: stars)
                  .count()
                  .get()
                  .then((r) => r.count ?? 0),
          ]),
        );
  }

  /// Threads with [otherUid] in which a message was sent. Only these are
  /// accepted by the rules as backing a (verified) user review.
  @override
  Stream<List<ReviewContext>> watchReviewContexts(String otherUid) {
    return _db
        .collection(_conversations)
        .where('participant_ids', arrayContains: _profileOwnerId)
        .snapshots()
        .map(
          (s) => [
            for (final doc in s.docs)
              if ((doc.data()['participant_ids'] as List?)?.contains(
                        otherUid,
                      ) ==
                      true &&
                  (doc.data()['last_message'] as String? ?? '').isNotEmpty)
                ReviewContext(
                  conversationId: doc.id,
                  listingTitle: doc.data()['kind'] == 'direct'
                      ? ''
                      : doc.data()['listing_title'] as String? ?? '',
                ),
          ],
        );
  }

  /// The buyer's thread about a listing has the fixed id
  /// `{listingId}_{buyerUid}`; reviewing needs it to hold a message.
  @override
  Stream<bool> watchCanReviewListing(String listingId) {
    return _db
        .collection(_conversations)
        .doc('${listingId}_$_profileOwnerId')
        .snapshots()
        .map(
          (snap) =>
              snap.exists &&
              (snap.data()?['last_message'] as String? ?? '').isNotEmpty,
        )
        .handleError((Object _) => false);
  }

  @override
  Future<void> setReviewReply(Review review, String? reply) async {
    final text = (reply ?? '').trim();
    if (text.length > reviewTextMaxLength) {
      throw RangeError.range(text.length, 0, reviewTextMaxLength, 'reply');
    }
    await _reviewsOf(review.kind).doc(review.id).update({
      'reply': text.isEmpty ? FieldValue.delete() : text,
      'reply_at': text.isEmpty
          ? FieldValue.delete()
          : FieldValue.serverTimestamp(),
    });
  }

  /// `review_reports/{reporterUid}_{kind}_{reviewId}`: create-only, so a
  /// repeat report is refused by the rules (→ false).
  @override
  Future<bool> reportReview(
    Review review,
    ReportReason reason, {
    String? details,
  }) async {
    if (review.reviewerId == _profileOwnerId) {
      throw ArgumentError('You cannot report your own review.');
    }
    try {
      await _db
          .collection(_reviewReports)
          .doc('${_profileOwnerId}_${review.kind.name}_${review.id}')
          .set({
            'review_id': review.id,
            'review_kind': review.kind.name,
            'reporter_id': _profileOwnerId,
            'reason': reason.index,
            'details': (details ?? '').trim(),
            'created_at': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
    return true;
  }

  @override
  Future<void> addReview({
    required String revieweeId,
    required ReviewContext context,
    required int rating,
    required String comment,
  }) async {
    final reviewer = _requireReviewer();
    if (revieweeId == reviewer.uid) {
      throw ArgumentError.value(
        revieweeId,
        'revieweeId',
        "can't rate yourself",
      );
    }
    _checkRating(rating, comment);
    final title = context.listingTitle.trim();
    await _writeReview(
      reviewDoc: _db.collection(_reviews).doc('${reviewer.uid}_$revieweeId'),
      targetDoc: _profileDocFor(revieweeId),
      data: {
        'reviewee_id': revieweeId,
        'reviewer_id': reviewer.uid,
        'rater_name': _raterName(reviewer),
        'rating': rating,
        'comment': comment.trim(),
        if (title.isNotEmpty) 'listing_title': title,
        // The rules accept `verified` only with a real shared thread.
        'conversation_id': context.conversationId,
        'verified': true,
      },
    );
  }

  @override
  Future<void> deleteReview(String revieweeId) async {
    final reviewer = _requireReviewer();
    await _writeReview(
      reviewDoc: _db.collection(_reviews).doc('${reviewer.uid}_$revieweeId'),
      targetDoc: _profileDocFor(revieweeId),
      data: null,
    );
  }

  @override
  Future<void> deleteListingReview(String listingId) async {
    final reviewer = _requireReviewer();
    await _writeReview(
      reviewDoc: _db
          .collection(_listingReviews)
          .doc('${reviewer.uid}_$listingId'),
      targetDoc: _db.collection(_listings).doc(listingId),
      data: null,
    );
  }

  @override
  Future<void> addListingReview({
    required Listing listing,
    required int rating,
    required String comment,
  }) async {
    final reviewer = _requireReviewer();
    if (listing.ownerId == reviewer.uid) {
      throw ArgumentError.value(
        listing.id,
        'listing',
        "can't review your own listing",
      );
    }
    _checkRating(rating, comment);
    await _writeReview(
      reviewDoc: _db
          .collection(_listingReviews)
          .doc('${reviewer.uid}_${listing.id}'),
      targetDoc: _db.collection(_listings).doc(listing.id),
      data: {
        'listing_id': listing.id,
        'listing_owner_id': listing.ownerId,
        'reviewer_id': reviewer.uid,
        'rater_name': _raterName(reviewer),
        'rating': rating,
        'comment': comment.trim(),
        'listing_title': listing.title,
        // The buyer's thread about this listing; see watchCanReviewListing.
        'conversation_id': '${listing.id}_${reviewer.uid}',
        'verified': true,
      },
    );
  }

  User _requireReviewer() {
    final reviewer = _auth.currentUser;
    if (reviewer == null) {
      throw StateError('You must be signed in to review.');
    }
    return reviewer;
  }

  void _checkRating(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw RangeError.range(rating, 1, 5, 'rating');
    }
    final length = comment.trim().length;
    if (length > reviewTextMaxLength) {
      throw RangeError.range(length, 0, reviewTextMaxLength, 'comment');
    }
  }

  /// Creates, edits, or (with [data] null) deletes the caller's review at
  /// [reviewDoc], and in the same transaction moves the integer aggregate on
  /// [targetDoc] (a profile or listing) by exactly that review's delta:
  /// count +1 / 0 / -1, sum by new rating minus old. firestore.rules'
  /// `aggregateFollowsReview` recomputes the same delta and rejects any other
  /// value, so nobody can write an arbitrary average.
  ///
  /// The doc id is fixed per reviewer + target, so a repeat "add" edits the
  /// existing review: created_at stays put and updated_at marks the edit.
  Future<void> _writeReview({
    required DocumentReference<Map<String, dynamic>> reviewDoc,
    required DocumentReference<Map<String, dynamic>> targetDoc,
    required Map<String, dynamic>? data,
  }) {
    return _db.runTransaction((tx) async {
      final reviewSnap = await tx.get(reviewDoc);
      final targetSnap = await tx.get(targetDoc);
      final existed = reviewSnap.exists;
      if (data == null && !existed) return;

      if (data == null) {
        tx.delete(reviewDoc);
      } else {
        tx.set(reviewDoc, {
          ...data,
          if (existed)
            'updated_at': FieldValue.serverTimestamp()
          else
            'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // A deleted listing/profile has no aggregate left to maintain (the
      // rules skip the check then too).
      final target = targetSnap.data();
      if (target == null) return;
      final oldRating = existed
          ? (reviewSnap.data()?['rating'] as num? ?? 0).toInt()
          : 0;
      final newRating = data == null ? 0 : data['rating'] as int;
      final countDelta = (data == null ? 0 : 1) - (existed ? 1 : 0);
      tx.set(targetDoc, {
        'rating_sum': ratingSumOf(target) + newRating - oldRating,
        'rating_count': ratingCountOf(target) + countDelta,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    required String avatarUrl,
  }) async {
    await _profileDoc.set({
      'name': name.trim(),
      'bio': bio.trim(),
      if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
    }, SetOptions(merge: true));
  }

  @override
  Future<String> uploadAvatar(String filePath) {
    return _images.uploadImage(filePath, folder: 'market-gig/avatars');
  }

  @override
  Future<void> recordLegalAcceptance(String version) async {
    await _profileDoc.set({
      'terms_accepted_at': FieldValue.serverTimestamp(),
      'terms_version': version,
    }, SetOptions(merge: true));
  }

  @override
  Future<({DateTime? acceptedAt, String? version})?>
  fetchLegalAcceptance() async {
    final snap = await _profileDoc.get();
    final data = snap.data();
    if (data == null) return null;
    final rawAt = data['terms_accepted_at'];
    DateTime? acceptedAt;
    if (rawAt is Timestamp) {
      acceptedAt = rawAt.toDate();
    } else if (rawAt is String) {
      acceptedAt = DateTime.tryParse(rawAt);
    }
    return (acceptedAt: acceptedAt, version: data['terms_version'] as String?);
  }

  /// `blocks/{blockerUid}_{blockedUid}`: the rules check these docs to refuse
  /// chat between users who blocked each other.
  @override
  Stream<List<BlockedUser>> watchBlockedUsers() {
    return _db
        .collection(_blocks)
        .where('blocker_id', isEqualTo: _profileOwnerId)
        .snapshots()
        .map((snap) {
          final users = snap.docs
              .map((doc) {
                final row = doc.data();
                return BlockedUser(
                  id: row['blocked_id'] as String? ?? '',
                  name: row['blocked_name'] as String? ?? 'User',
                  avatarUrl: row['blocked_avatar'] as String? ?? '',
                  blockedAt: _dateTime(row['created_at']),
                );
              })
              .where((u) => u.id.isNotEmpty)
              .toList();
          users.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
          return users;
        });
  }

  @override
  Future<void> blockUser(
    String uid, {
    String name = '',
    String avatarUrl = '',
  }) async {
    if (uid == _profileOwnerId) {
      throw ArgumentError('You cannot block yourself.');
    }
    await _db.collection(_blocks).doc('${_profileOwnerId}_$uid').set({
      'blocker_id': _profileOwnerId,
      'blocked_id': uid,
      'blocked_name': name.trim().isEmpty ? 'User' : name.trim(),
      'blocked_avatar': avatarUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unblockUser(String uid) async {
    await _db.collection(_blocks).doc('${_profileOwnerId}_$uid').delete();
  }

  @override
  Future<bool> reportUser(
    String uid,
    ReportReason reason, {
    String? details,
    String? conversationId,
  }) async {
    if (uid == _profileOwnerId) {
      throw ArgumentError('You cannot report yourself.');
    }
    try {
      await _db.collection(_userReports).doc('${_profileOwnerId}_$uid').set({
        'reporter_id': _profileOwnerId,
        'reported_id': uid,
        'reason': reason.index,
        'details': (details ?? '').trim(),
        'conversation_id': ?conversationId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Reports are create-only, so re-reporting is rejected by the rules.
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
    return true;
  }

  String _profileName(Map<String, dynamic> row) {
    final name = row['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'User';
  }

  String _raterName(User user) {
    final display = user.displayName;
    if (display != null && display.trim().isNotEmpty) return display.trim();
    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'User';
  }

  DateTime _dateTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  Review _reviewFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    ReviewTarget target,
  ) {
    final row = doc.data() ?? const <String, dynamic>{};
    return Review(
      id: doc.id,
      raterName: row['rater_name'] as String? ?? 'User',
      rating: (row['rating'] as num? ?? 0).toInt(),
      comment: row['comment'] as String? ?? '',
      listingTitle: row['listing_title'] as String? ?? '',
      createdAt: _dateTime(row['created_at']),
      reviewerId: row['reviewer_id'] as String? ?? '',
      updatedAt: row['updated_at'] == null
          ? null
          : _dateTime(row['updated_at']),
      kind: target.kind,
      targetId: target.id,
      ownerId: target.kind == ReviewKind.user
          ? target.id
          : row['listing_owner_id'] as String? ?? '',
      verified: row['verified'] == true,
      conversationId: row['conversation_id'] as String? ?? '',
      reply: row['reply'] as String? ?? '',
      replyAt: row['reply_at'] == null ? null : _dateTime(row['reply_at']),
    );
  }
}
