import 'package:drift/drift.dart';

class ListingsTable extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get description => text()();
  TextColumn get imageUrls => text()();
  TextColumn get category => text()();
  TextColumn get location => text()();
  TextColumn get duration => text().nullable()();
  BoolColumn get remoteOnly => boolean().withDefault(const Constant(false))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get ownerId => text().withDefault(const Constant('local-user'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SwipeStatesTable extends Table {
  TextColumn get listingId => text()();
  IntColumn get action => integer()();
  DateTimeColumn get actedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listingId};
}

class ConversationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get participantName => text()();
  TextColumn get participantAvatar => text()();
  TextColumn get lastMessage => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get role => integer()();
  TextColumn get listingTitle => text()();
  TextColumn get listingId => text()();
  // Added in schema v2.
  TextColumn get otherUserId => text().withDefault(const Constant(''))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get otherLastReadAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MessagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get body => text()();
  BoolColumn get isOutgoing => boolean()();
  DateTimeColumn get sentAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserProfilesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text()();
  RealColumn get rating => real()();
  IntColumn get reviewCount => integer()();
  IntColumn get listingsCount => integer()();
  IntColumn get soldCount => integer()();
  DateTimeColumn get memberSince => dateTime()();
  TextColumn get reviewsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppMetaTable extends Table {
  TextColumn get key => text()();
  BoolColumn get seeded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}
