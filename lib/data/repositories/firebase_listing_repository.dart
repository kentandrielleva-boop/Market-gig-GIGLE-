import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketplace_gig/core/storage/cloudinary_uploader.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/data/repositories/stream_utils.dart';
import 'package:marketplace_gig/domain/models/models.dart';

/// [ListingRepository] backed by Cloud Firestore (Spark plan) + Cloudinary.
///
/// Collections:
/// `listings/{id}`, `swipes/{uid}_{listingId}`. Enums are stored as their
/// integer index, `image_urls` as a string array of Cloudinary `secure_url`s.
/// Firestore snapshots push updates, so no shared-channel multiplexing
/// class is needed.
class FirebaseListingRepository implements ListingRepository {
  FirebaseListingRepository(this._db, this._images, this._userId);

  final FirebaseFirestore _db;
  final CloudinaryUploader _images;
  final String _userId;

  static const _listings = 'listings';
  static const _swipes = 'swipes';
  static const feedWindowSize = 100;

  CollectionReference<Map<String, dynamic>> get _listingsCol =>
      _db.collection(_listings);

  CollectionReference<Map<String, dynamic>> get _swipesCol =>
      _db.collection(_swipes);

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _db.collection('reports');

  Stream<List<Map<String, dynamic>>> get _activeListings => _listingsCol
      .where('status', isEqualTo: ListingStatus.active.index)
      .orderBy('created_at', descending: true)
      .limit(feedWindowSize)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get _myListings => _listingsCol
      .where('owner_id', isEqualTo: _userId)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get _mySwipes => _swipesCol
      .where('user_id', isEqualTo: _userId)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  @override
  /// Discovery feed: other users' active listings the caller hasn't swiped.
  /// Own posts only appear under My listings / My gigs. Filtered client-side
  /// because Firestore can't combine `owner_id !=` with the created_at order.
  Stream<List<Listing>> watchFeed() {
    return combineLatest2(_activeListings, _mySwipes, (listingRows, swipeRows) {
      final swipedIds = {
        for (final row in swipeRows) row['listing_id'] as String,
      };
      return [
        for (final row in listingRows)
          if (row['owner_id'] != _userId && !swipedIds.contains(row['id']))
            _listingFromDoc(row),
      ];
    });
  }

  @override
  Stream<List<Listing>> watchSaved() => _watchBySwipe(_isSaved);

  @override
  Stream<List<Listing>> watchPassed() => _watchBySwipe(_isPassed);

  @override
  Stream<List<Listing>> watchMyListings() {
    return _myListings.map((rows) => rows.map(_listingFromDoc).toList());
  }

  /// The `status == active` filter is required, not cosmetic: the security
  /// rules only let non-owners read active listings, so the query must prove it.
  @override
  Stream<List<Listing>> watchListingsByOwner(String ownerId) {
    return _listingsCol
        .where('owner_id', isEqualTo: ownerId)
        .where('status', isEqualTo: ListingStatus.active.index)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => _listingFromDoc({'id': d.id, ...d.data()}))
              .toList(),
        );
  }

  @override
  Stream<Listing?> watchListingById(String listingId) {
    return _listingsCol.doc(listingId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return _listingFromDoc({'id': snap.id, ...data});
    });
  }

  @override
  Future<void> pass(String listingId) =>
      _upsertSwipe(listingId, SwipeActionType.passed);

  @override
  Future<void> save(String listingId) =>
      _upsertSwipe(listingId, SwipeActionType.saved);

  @override
  Future<void> restorePassed(String listingId) async {
    await _swipesCol.doc(_swipeId(listingId)).delete();
  }

  @override
  Future<void> createListing(Listing listing) async {
    await _listingsCol
        .doc(listing.id)
        .set(_listingToDoc(listing, ownerId: _userId), SetOptions(merge: true));
  }

  @override
  Future<void> updateListing(Listing listing) async {
    // Only owner-editable fields: `owner_id`, `type`, `image_urls` and
    // `created_at` stay untouched so the update satisfies firestore.rules.
    await _listingsCol.doc(listing.id).update({
      'title': listing.title,
      'price': listing.price,
      'description': listing.description,
      'location': listing.location,
      'duration': listing.duration,
      'remote_only': listing.remoteOnly,
      'status': listing.status.index,
    });
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await _listingsCol.doc(listingId).delete();
    // Our own swipe on it is now dangling; clean up best-effort.
    try {
      await _swipesCol.doc(_swipeId(listingId)).delete();
    } on FirebaseException catch (_) {}
  }

  @override
  Future<bool> reportListing(
    Listing listing,
    ReportReason reason, {
    String? details,
  }) async {
    if (listing.ownerId == _userId) {
      throw StateError('You cannot report your own listing.');
    }
    try {
      await _reportsCol.doc('${_userId}_${listing.id}').set({
        'listing_id': listing.id,
        'listing_owner_id': listing.ownerId,
        'reporter_id': _userId,
        'reason': reason.index,
        'details': (details ?? '').trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Reports are create-only, so re-reporting is rejected by the rules.
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
    await pass(listing.id);
    return true;
  }

  @override
  Future<String> uploadListingImage(String filePath, {String? listingId}) {
    final scope = (listingId != null && listingId.isNotEmpty)
        ? listingId
        : 'misc';
    return _images.uploadImage(filePath, folder: 'market-gig/listings/$scope');
  }

  String _swipeId(String listingId) => '${_userId}_$listingId';

  bool _isSaved(Map<String, dynamic> row) =>
      row['action'] == SwipeActionType.saved.index;

  bool _isPassed(Map<String, dynamic> row) =>
      row['action'] == SwipeActionType.passed.index;

  Future<void> _upsertSwipe(String listingId, SwipeActionType action) async {
    await _swipesCol.doc(_swipeId(listingId)).set({
      'listing_id': listingId,
      'user_id': _userId,
      'action': action.index,
      'acted_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Listing>> _watchBySwipe(
    bool Function(Map<String, dynamic>) matches,
  ) {
    return _mySwipes.asyncExpand((swipeRows) async* {
      final ids = [
        for (final row in swipeRows)
          if (matches(row)) row['listing_id'] as String,
      ];
      if (ids.isEmpty) {
        yield const [];
        return;
      }
      // `whereIn` caps at 10 ids per query — chunk larger swipe lists.
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }
      final snaps = await Future.wait(
        chunks.map(
          (c) => _listingsCol.where(FieldPath.documentId, whereIn: c).get(),
        ),
      );
      final rows = [
        for (final s in snaps)
          for (final d in s.docs) {'id': d.id, ...d.data()},
      ];
      rows.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
      yield rows.map(_listingFromDoc).toList();
    });
  }

  DateTime _createdAt(Map<String, dynamic> row) {
    final raw = row['created_at'];
    if (raw is Timestamp) return raw.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Listing _listingFromDoc(Map<String, dynamic> row) {
    return Listing(
      id: row['id'] as String,
      type: _enumAt(ListingType.values, row['type'] as int?, ListingType.item),
      title: row['title'] as String? ?? '',
      price: (row['price'] as num? ?? 0).toDouble(),
      description: row['description'] as String? ?? '',
      imageUrls: List<String>.from(row['image_urls'] as List? ?? const []),
      category: row['category'] as String? ?? 'General',
      location: row['location'] as String? ?? '',
      duration: row['duration'] as String?,
      remoteOnly: row['remote_only'] as bool? ?? false,
      status: _enumAt(
        ListingStatus.values,
        row['status'] as int?,
        ListingStatus.active,
      ),
      ownerId: row['owner_id'] as String? ?? 'local-user',
      ratingSum: (row['rating_sum'] as num?)?.toInt() ?? 0,
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _listingToDoc(
    Listing listing, {
    required String ownerId,
  }) {
    return {
      'type': listing.type.index,
      'title': listing.title,
      'price': listing.price,
      'description': listing.description,
      'image_urls': listing.imageUrls,
      'category': listing.category,
      'location': listing.location,
      'duration': listing.duration,
      'remote_only': listing.remoteOnly,
      'status': listing.status.index,
      'owner_id': ownerId,
      // Product-review aggregate; only reviewers' transactions move it.
      'rating_sum': 0,
      'rating_count': 0,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}

T _enumAt<T extends Enum>(List<T> values, int? index, T fallback) {
  if (index == null || index < 0 || index >= values.length) return fallback;
  return values[index];
}
