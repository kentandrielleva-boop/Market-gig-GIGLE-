import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_gig/data/local/app_database.dart';

void main() {
  test('v1 conversations gain the chat columns on upgrade to v2', () async {
    // A v1 install: conversations table without otherUserId/archived/
    // otherLastReadAt, and user_version 1.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE conversations_table (
              id TEXT NOT NULL PRIMARY KEY,
              participant_name TEXT NOT NULL,
              participant_avatar TEXT NOT NULL,
              last_message TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              unread_count INTEGER NOT NULL DEFAULT 0,
              role INTEGER NOT NULL,
              listing_title TEXT NOT NULL,
              listing_id TEXT NOT NULL
            );
          ''');
          raw.execute(
            "INSERT INTO conversations_table VALUES "
            "('c1', 'Ana', '', 'hi', 0, 2, 1, 'Bike', 'bike')",
          );
          raw.execute('PRAGMA user_version = 1;');
        },
      ),
    );
    addTearDown(db.close);

    final conversation = await db.getConversation('c1');
    expect(conversation, isNotNull);
    expect(conversation!.participantName, 'Ana');
    expect(conversation.unreadCount, 2);
    expect(conversation.otherUserId, '');
    expect(conversation.isArchived, isFalse);
    expect(conversation.otherLastReadAt, isNull);

    await db.setConversationArchived('c1', true);
    expect((await db.getConversation('c1'))!.isArchived, isTrue);
  });
}
