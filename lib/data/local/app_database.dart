import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:marketplace_gig/data/local/tables.dart';
import 'package:marketplace_gig/domain/models/models.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ListingsTable,
    SwipeStatesTable,
    ConversationsTable,
    MessagesTable,
    UserProfilesTable,
    AppMetaTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(conversationsTable, conversationsTable.otherUserId);
        await m.addColumn(conversationsTable, conversationsTable.archived);
        await m.addColumn(
          conversationsTable,
          conversationsTable.otherLastReadAt,
        );
      }
    },
  );

  Future<bool> isSeeded() async {
    final row = await (select(
      appMetaTable,
    )..where((t) => t.key.equals('seed'))).getSingleOrNull();
    return row?.seeded ?? false;
  }

  Future<void> markSeeded() async {
    await into(appMetaTable).insertOnConflictUpdate(
      AppMetaTableCompanion.insert(key: 'seed', seeded: const Value(true)),
    );
  }

  Stream<List<Listing>> watchFeed() {
    final query =
        select(listingsTable).join([
          leftOuterJoin(
            swipeStatesTable,
            swipeStatesTable.listingId.equalsExp(listingsTable.id),
          ),
        ])..where(
          swipeStatesTable.listingId.isNull() &
              listingsTable.ownerId.equals('local-user').not(),
        );

    return query.watch().map((rows) {
      return rows
          .map((row) => _listingFromRow(row.readTable(listingsTable)))
          .toList();
    });
  }

  Stream<List<Listing>> watchSaved() {
    return _watchBySwipeAction(SwipeActionType.saved);
  }

  Stream<List<Listing>> watchPassed() {
    return _watchBySwipeAction(SwipeActionType.passed);
  }

  Stream<List<Listing>> _watchBySwipeAction(SwipeActionType action) {
    final query = select(listingsTable).join([
      innerJoin(
        swipeStatesTable,
        swipeStatesTable.listingId.equalsExp(listingsTable.id),
      ),
    ])..where(swipeStatesTable.action.equals(action.index));
    return query.watch().map((rows) {
      return rows
          .map((row) => _listingFromRow(row.readTable(listingsTable)))
          .toList();
    });
  }

  Stream<List<Listing>> watchMyListings() {
    return (select(listingsTable)..where((t) => t.ownerId.equals('local-user')))
        .watch()
        .map((rows) => rows.map(_listingFromRow).toList());
  }

  Stream<Listing?> watchListingById(String listingId) {
    final query = select(listingsTable)..where((t) => t.id.equals(listingId));
    return query.watch().map(
      (rows) => rows.isEmpty ? null : _listingFromRow(rows.first),
    );
  }

  Future<void> insertListing(Listing listing) {
    return into(listingsTable).insertOnConflictUpdate(_listingToRow(listing));
  }

  Future<void> updateListing(Listing listing) {
    return (update(listingsTable)..where((t) => t.id.equals(listing.id))).write(
      ListingsTableCompanion(
        title: Value(listing.title),
        price: Value(listing.price),
        description: Value(listing.description),
        location: Value(listing.location),
        duration: Value(listing.duration),
        remoteOnly: Value(listing.remoteOnly),
        status: Value(listing.status.index),
      ),
    );
  }

  Future<void> deleteListing(String listingId) async {
    await transaction(() async {
      await (delete(
        swipeStatesTable,
      )..where((t) => t.listingId.equals(listingId))).go();
      await (delete(listingsTable)..where((t) => t.id.equals(listingId))).go();
    });
  }

  Future<void> insertListings(List<Listing> listings) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(
        listingsTable,
        listings.map(_listingToRow).toList(),
      );
    });
  }

  Future<void> setSwipe(String listingId, SwipeActionType action) {
    return into(swipeStatesTable).insertOnConflictUpdate(
      SwipeStatesTableCompanion.insert(
        listingId: listingId,
        action: action.index,
        actedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeSwipe(String listingId) {
    return (delete(
      swipeStatesTable,
    )..where((t) => t.listingId.equals(listingId))).go();
  }

  Stream<List<Conversation>> watchConversations() {
    return (select(conversationsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch()
        .map((rows) => rows.map(_conversationFromRow).toList());
  }

  Future<void> insertConversations(List<Conversation> items) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(
        conversationsTable,
        items.map(_conversationToRow).toList(),
      );
    });
  }

  Future<Conversation?> getConversation(String id) async {
    final row = await (select(
      conversationsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _conversationFromRow(row);
  }

  Future<void> updateConversationLastMessage(
    String conversationId,
    String text,
  ) async {
    await (update(
      conversationsTable,
    )..where((t) => t.id.equals(conversationId))).write(
      ConversationsTableCompanion(
        lastMessage: Value(text),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setConversationUnread(String conversationId, int count) async {
    await (update(conversationsTable)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsTableCompanion(unreadCount: Value(count)));
  }

  Future<void> setConversationArchived(
    String conversationId,
    bool archived,
  ) async {
    await (update(conversationsTable)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsTableCompanion(archived: Value(archived)));
  }

  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50}) {
    return (select(messagesTable)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.desc(t.sentAt)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(_messageFromRow).toList());
  }

  Future<List<Message>> getMessagesPage(
    String conversationId, {
    required int limit,
    required int offset,
  }) async {
    final rows =
        await (select(messagesTable)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => OrderingTerm.desc(t.sentAt)])
              ..limit(limit, offset: offset))
            .get();
    return rows.map(_messageFromRow).toList();
  }

  Future<int> countMessages(String conversationId) async {
    final count = countAll();
    final query = selectOnly(messagesTable)
      ..addColumns([count])
      ..where(messagesTable.conversationId.equals(conversationId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insertMessages(List<Message> messages) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(
        messagesTable,
        messages.map(_messageToRow).toList(),
      );
    });
  }

  Future<void> insertProfile(UserProfile profile, List<Review> reviews) {
    return into(userProfilesTable).insertOnConflictUpdate(
      UserProfilesTableCompanion.insert(
        id: profile.id,
        name: profile.name,
        avatarUrl: profile.avatarUrl,
        rating: profile.rating,
        reviewCount: profile.reviewCount,
        listingsCount: profile.listingsCount,
        soldCount: profile.soldCount,
        memberSince: profile.memberSince,
        reviewsJson: Value(jsonEncode(reviews.map(_reviewToJson).toList())),
      ),
    );
  }

  Future<UserProfile?> getProfile() async {
    final row = await select(userProfilesTable).getSingleOrNull();
    if (row == null) return null;
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
  }

  Future<List<Review>> getReviews() async {
    final row = await select(userProfilesTable).getSingleOrNull();
    if (row == null) return [];
    final Object? decoded;
    try {
      decoded = jsonDecode(row.reviewsJson);
    } catch (_) {
      return [];
    }
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_reviewFromJson)
        .toList();
  }

  Listing _listingFromRow(ListingsTableData row) {
    return Listing(
      id: row.id,
      type: _enumAt(ListingType.values, row.type, ListingType.item),
      title: row.title,
      price: row.price,
      description: row.description,
      imageUrls: (jsonDecode(row.imageUrls) as List<dynamic>).cast<String>(),
      category: row.category,
      location: row.location,
      duration: row.duration,
      remoteOnly: row.remoteOnly,
      status: _enumAt(ListingStatus.values, row.status, ListingStatus.active),
      ownerId: row.ownerId,
    );
  }

  ListingsTableCompanion _listingToRow(Listing listing) {
    return ListingsTableCompanion.insert(
      id: listing.id,
      type: listing.type.index,
      title: listing.title,
      price: listing.price,
      description: listing.description,
      imageUrls: jsonEncode(listing.imageUrls),
      category: listing.category,
      location: listing.location,
      duration: Value(listing.duration),
      remoteOnly: Value(listing.remoteOnly),
      status: Value(listing.status.index),
      ownerId: Value(listing.ownerId),
    );
  }

  Conversation _conversationFromRow(ConversationsTableData row) {
    return Conversation(
      id: row.id,
      participantName: row.participantName,
      participantAvatar: row.participantAvatar,
      lastMessage: row.lastMessage,
      timestamp: row.timestamp,
      unreadCount: row.unreadCount,
      role: _enumAt(ParticipantRole.values, row.role, ParticipantRole.buyer),
      listingTitle: row.listingTitle,
      listingId: row.listingId,
      otherUserId: row.otherUserId,
      isArchived: row.archived,
      otherLastReadAt: row.otherLastReadAt,
    );
  }

  ConversationsTableCompanion _conversationToRow(Conversation item) {
    return ConversationsTableCompanion.insert(
      id: item.id,
      participantName: item.participantName,
      participantAvatar: item.participantAvatar,
      lastMessage: item.lastMessage,
      timestamp: item.timestamp,
      unreadCount: Value(item.unreadCount),
      role: item.role.index,
      listingTitle: item.listingTitle,
      listingId: item.listingId,
      otherUserId: Value(item.otherUserId),
      archived: Value(item.isArchived),
      otherLastReadAt: Value(item.otherLastReadAt),
    );
  }

  Message _messageFromRow(MessagesTableData row) {
    return Message(
      id: row.id,
      conversationId: row.conversationId,
      text: row.body,
      isOutgoing: row.isOutgoing,
      sentAt: row.sentAt,
    );
  }

  MessagesTableCompanion _messageToRow(Message message) {
    return MessagesTableCompanion.insert(
      id: message.id,
      conversationId: message.conversationId,
      body: message.text,
      isOutgoing: message.isOutgoing,
      sentAt: message.sentAt,
    );
  }

  Map<String, dynamic> _reviewToJson(Review review) => {
    'id': review.id,
    'raterName': review.raterName,
    'rating': review.rating,
    'comment': review.comment,
    'listingTitle': review.listingTitle,
    'createdAt': review.createdAt.toIso8601String(),
    'reviewerId': review.reviewerId,
    'updatedAt': review.updatedAt?.toIso8601String(),
    'verified': review.verified,
    'conversationId': review.conversationId,
    'reply': review.reply,
    'replyAt': review.replyAt?.toIso8601String(),
  };

  Review _reviewFromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    raterName: json['raterName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String,
    listingTitle: json['listingTitle'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reviewerId: json['reviewerId'] as String? ?? '',
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    verified: json['verified'] as bool? ?? false,
    conversationId: json['conversationId'] as String? ?? '',
    reply: json['reply'] as String? ?? '',
    replyAt: DateTime.tryParse(json['replyAt'] as String? ?? ''),
  );
}

T _enumAt<T extends Enum>(List<T> values, int index, T fallback) {
  if (index < 0 || index >= values.length) return fallback;
  return values[index];
}
