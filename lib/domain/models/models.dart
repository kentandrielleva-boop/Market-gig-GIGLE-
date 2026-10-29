/// Pre-filled place for new listings until the user changes it.
const kDefaultListingLocation = 'Tagum City';

enum ListingType { item, gig }

enum ListingStatus { active, paused, completed }

enum SwipeActionType { passed, saved }

/// Role of the *other* party in a conversation. Stored by index, so new
/// values go at the end; [direct] marks a thread not tied to a listing.
enum ParticipantRole { buyer, seller, gigClient, gigWorker, direct }

enum ReportReason { spam, scam, prohibited, inappropriate, other }

class Listing {
  const Listing({
    required this.id,
    required this.type,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.location,
    this.duration,
    this.remoteOnly = false,
    this.status = ListingStatus.active,
    this.ownerId = 'local-user',
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  final String id;
  final ListingType type;
  final String title;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String category;
  final String location;
  final String? duration;
  final bool remoteOnly;
  final ListingStatus status;
  final String ownerId;

  /// Product-review aggregate (total stars / number of reviews), kept in
  /// step with `listing_reviews` by the reviewer's transaction.
  final int ratingSum;
  final int ratingCount;

  double get rating =>
      ratingCount <= 0 ? 0 : (ratingSum / ratingCount).clamp(0.0, 5.0);

  bool get isGig => type == ListingType.gig;

  static const fallbackImageUrl =
      'https://picsum.photos/seed/marketplace/480/480';

  String get primaryImageUrl =>
      imageUrls.isEmpty ? fallbackImageUrl : imageUrls.first;

  Listing copyWith({
    String? title,
    double? price,
    String? description,
    String? location,
    String? duration,
    bool clearDuration = false,
    bool? remoteOnly,
    ListingStatus? status,
  }) {
    return Listing(
      id: id,
      type: type,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrls: imageUrls,
      category: category,
      location: location ?? this.location,
      duration: clearDuration ? null : (duration ?? this.duration),
      remoteOnly: remoteOnly ?? this.remoteOnly,
      status: status ?? this.status,
      ownerId: ownerId,
      ratingSum: ratingSum,
      ratingCount: ratingCount,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantAvatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.role,
    required this.listingTitle,
    required this.listingId,
    this.otherUserId = '',
    this.isArchived = false,
    this.otherLastReadAt,
  });

  final String id;
  final String participantName;
  final String participantAvatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final ParticipantRole role;
  final String listingTitle;
  final String listingId;

  /// Uid of the other participant; empty for legacy/offline threads.
  final String otherUserId;

  /// Archived by the signed-in user (per-user, the other side is unaffected).
  final bool isArchived;

  /// When the other participant last opened the thread ("Seen" marker).
  final DateTime? otherLastReadAt;

  bool get isDirect => role == ParticipantRole.direct;
}

/// Someone the signed-in user has blocked: they can't message each other and
/// their listings and threads are hidden.
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.blockedAt,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final DateTime blockedAt;
}

/// Thrown when a chat write is refused because either side blocked the other.
class MessagingBlockedException implements Exception {
  const MessagingBlockedException();

  @override
  String toString() => "This user isn't accepting messages.";
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.isOutgoing,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String text;
  final bool isOutgoing;
  final DateTime sentAt;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.bio = '',
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.listingsCount,
    required this.soldCount,
    required this.memberSince,
  });

  final String id;
  final String name;
  final String bio;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int listingsCount;
  final int soldCount;
  final DateTime memberSince;
}

/// Whether a review rates a user (`reviews/`) or a listing
/// (`listing_reviews/`).
enum ReviewKind { user, listing }

/// What a list of reviews is about: a user's profile or one listing.
typedef ReviewTarget = ({ReviewKind kind, String id});

enum ReviewSort { recent, highest, lowest }

/// One page of a review list: optional star filter, order, and how many to
/// load ("Load more" raises [limit] by [reviewPageSize]).
typedef ReviewQuery = ({int? stars, ReviewSort sort, int limit});

const reviewPageSize = 20;
const firstReviewPage = (
  stars: null,
  sort: ReviewSort.recent,
  limit: reviewPageSize,
);

/// Longest comment or owner reply (also enforced by firestore.rules).
const reviewTextMaxLength = 500;

class Review {
  const Review({
    required this.id,
    required this.raterName,
    required this.rating,
    required this.comment,
    required this.listingTitle,
    required this.createdAt,
    this.reviewerId = '',
    this.updatedAt,
    this.kind = ReviewKind.user,
    this.targetId = '',
    this.ownerId = '',
    this.verified = false,
    this.conversationId = '',
    this.reply = '',
    this.replyAt,
  });

  final String id;
  final String raterName;
  final int rating;
  final String comment;
  final String listingTitle;
  final DateTime createdAt;

  /// Author's uid, used to find the viewer's own review so it can be edited.
  final String reviewerId;

  /// Set once the author edits the review; [createdAt] keeps the original.
  final DateTime? updatedAt;

  final ReviewKind kind;

  /// The reviewed user's uid or the listing id, per [kind].
  final String targetId;

  /// Who may reply: the reviewed user, or the listing's owner.
  final String ownerId;

  /// Written after a chat between reviewer and [ownerId] (the rules check
  /// the [conversationId] thread before accepting `verified: true`).
  final bool verified;
  final String conversationId;

  /// The owner's public response; empty when there is none.
  final String reply;
  final DateTime? replyAt;

  bool get isEdited => updatedAt != null;
  bool get hasReply => reply.isNotEmpty;

  Review copyWith({
    ReviewKind? kind,
    String? targetId,
    String? ownerId,
    String? reply,
    DateTime? replyAt,
    bool clearReply = false,
  }) {
    return Review(
      id: id,
      raterName: raterName,
      rating: rating,
      comment: comment,
      listingTitle: listingTitle,
      createdAt: createdAt,
      reviewerId: reviewerId,
      updatedAt: updatedAt,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      ownerId: ownerId ?? this.ownerId,
      verified: verified,
      conversationId: conversationId,
      reply: clearReply ? '' : (reply ?? this.reply),
      replyAt: clearReply ? null : (replyAt ?? this.replyAt),
    );
  }
}

/// A chat the viewer shared with someone, which a user review can cite to
/// count as verified. [listingTitle] is empty for direct messages.
class ReviewContext {
  const ReviewContext({required this.conversationId, this.listingTitle = ''});

  final String conversationId;
  final String listingTitle;

  String get label => listingTitle.isEmpty ? 'Direct messages' : listingTitle;
}

class HomeFilters {
  const HomeFilters({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.maxDistanceKm,
    this.type,
  });

  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistanceKm;
  final ListingType? type;

  HomeFilters copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? maxDistanceKm,
    ListingType? type,
    bool clearCategory = false,
    bool clearType = false,
  }) {
    return HomeFilters(
      category: clearCategory ? null : (category ?? this.category),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      type: clearType ? null : (type ?? this.type),
    );
  }
}
