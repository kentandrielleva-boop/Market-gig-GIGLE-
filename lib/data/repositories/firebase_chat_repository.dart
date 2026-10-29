import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:marketplace_gig/data/local/app_database.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:uuid/uuid.dart';

/// [ChatRepository] with Firestore as source of truth and Drift as read cache.
///
/// The inbox UI pages with offset/limit, which Firestore can't do
/// efficiently per conversation, so reads stay on Drift (`LocalChatRepository`
/// semantics). Writes go to `conversations/{id}/messages/{msgId}` first, then
/// mirror locally; a best-effort snapshot listener backfills remote rows into
/// Drift for offline paging (ponytail: paginate the backfill per conversation
/// when threads grow past the latest-20 window).
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this._db, this._localDb, this._userId)
    : _local = LocalChatRepository(_localDb) {
    _listenRemote();
  }

  final FirebaseFirestore _db;
  final AppDatabase _localDb;
  final LocalChatRepository _local;
  final String _userId;

  static const _conversations = 'conversations';
  static const _backfillWindow = 20;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversationsSub;

  CollectionReference<Map<String, dynamic>> get _conversationsCol =>
      _db.collection(_conversations);

  void _listenRemote() {
    _conversationsSub = _conversationsCol
        .where('participant_ids', arrayContains: _userId)
        .snapshots()
        .listen((snap) {
          unawaited(
            _backfill(snap).catchError((Object e) {
              debugPrint('chat backfill failed: $e');
            }),
          );
        }, onError: (Object e) => debugPrint('chat listener failed: $e'));
  }

  /// Only changed docs are re-fetched, so a read-receipt or archive write
  /// doesn't re-download every thread. Unread counts are derived from the
  /// backfill window (so they cap at [_backfillWindow]).
  Future<void> _backfill(QuerySnapshot<Map<String, dynamic>> snap) async {
    final conversations = <Conversation>[];
    final messages = <Message>[];
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final doc = change.doc;
      final data = doc.data();
      if (data == null) continue;
      final threadMessages = <Message>[];
      try {
        final msgs = await doc.reference
            .collection('messages')
            .orderBy('sent_at', descending: true)
            .limit(_backfillWindow)
            .get();
        for (final m in msgs.docs) {
          threadMessages.add(_messageFromDoc(doc.id, m.id, m.data()));
        }
      } catch (e) {
        debugPrint('chat message backfill failed: $e');
      }
      // A just-written `last_read` serverTimestamp reads back as null in the
      // local snapshot; the key being present means "read just now".
      final readMap = data['last_read'];
      final lastRead =
          _readStamp(data, _userId) ??
          (readMap is Map && readMap.containsKey(_userId)
              ? DateTime.now()
              : null);
      final unread = threadMessages
          .where(
            (m) =>
                !m.isOutgoing &&
                (lastRead == null || m.sentAt.isAfter(lastRead)),
          )
          .length;
      conversations.add(_conversationFromDoc(doc.id, data, unread: unread));
      messages.addAll(threadMessages);
    }
    if (conversations.isNotEmpty) {
      await _localDb.insertConversations(conversations);
    }
    if (messages.isNotEmpty) {
      await _localDb.insertMessages(messages);
      for (final c in conversations) {
        final latest = messages
            .where((m) => m.conversationId == c.id)
            .fold<Message?>(
              null,
              (a, b) => a == null || b.sentAt.isAfter(a.sentAt) ? b : a,
            );
        if (latest != null) {
          await _localDb.updateConversationLastMessage(c.id, latest.text);
        }
      }
    }
  }

  @override
  Stream<List<Conversation>> watchConversations() =>
      _local.watchConversations();

  /// Live "head" of a thread (newest [limit] rows) straight from Firestore.
  /// `chat_thread_screen` merges this into the paged Drift history so new
  /// messages appear without waiting for the backfill listener.
  @override
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50}) {
    return _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => _messageFromDoc(conversationId, d.id, d.data()))
              .toList(),
        );
  }

  /// Typing presence: newest stamp from any *other* participant, or null when
  /// nobody typed in the last 5 seconds (client-side expiry).
  @override
  Stream<DateTime?> watchTyping(String conversationId) {
    return _conversationsCol
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .map((snap) {
          DateTime? latest;
          for (final d in snap.docs) {
            if (d.id == _userId) continue;
            final ts = d.data()['updated_at'];
            final at = ts is Timestamp ? ts.toDate() : null;
            if (at == null) continue;
            if (DateTime.now().difference(at).inSeconds > 5) continue;
            if (latest == null || at.isAfter(latest)) latest = at;
          }
          return latest;
        });
  }

  @override
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final ref = _conversationsCol
        .doc(conversationId)
        .collection('typing')
        .doc(_userId);
    if (isTyping) {
      try {
        await ref.set({'updated_at': FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint('setTyping failed: $e');
      }
    } else {
      await ref.delete().catchError((Object _) {});
    }
  }

  @override
  Future<List<Message>> getMessagesPage(
    String conversationId, {
    required int limit,
    required int offset,
  }) => _local.getMessagesPage(conversationId, limit: limit, offset: offset);

  @override
  Future<int> countMessages(String conversationId) =>
      _local.countMessages(conversationId);

  @override
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? id,
  }) async {
    final messageId = id ?? const Uuid().v4();
    final now = DateTime.now();
    try {
      // Message first: its rule enforces membership and blocks, so a refused
      // send never bumps the thread's last_message.
      final conversationRef = _conversationsCol.doc(conversationId);
      await conversationRef.collection('messages').doc(messageId).set({
        'sender_id': _userId,
        'text': text,
        'sent_at': Timestamp.fromDate(now),
      });
      await conversationRef.update({
        'last_message': text,
        'last_sender_id': _userId,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const MessagingBlockedException();
      }
      debugPrint('chat remote send failed (kept locally): $e');
    } catch (e) {
      debugPrint('chat remote send failed (kept locally): $e');
    }
    final message = Message(
      id: messageId,
      conversationId: conversationId,
      text: text,
      isOutgoing: true,
      sentAt: now,
    );
    await _localDb.insertMessages([message]);
    await _localDb.updateConversationLastMessage(conversationId, text);
  }

  /// Deterministic id (`{listingId}_{buyerId}`) so tapping "Message seller"
  /// twice reopens the same thread instead of forking a new one. The doc
  /// carries both sides' names under `participants` because each user must
  /// see the *other* party in their inbox.
  @override
  Future<String> startConversation(Listing listing) async {
    if (listing.ownerId == _userId) {
      throw StateError('You cannot message yourself about your own listing.');
    }
    return _getOrCreate(
      id: '${listing.id}_$_userId',
      otherUserId: listing.ownerId,
      participantIds: [_userId, listing.ownerId],
      extra: {
        'kind': 'listing',
        'seller_id': listing.ownerId,
        'listing_id': listing.id,
        'listing_title': listing.title,
        'listing_type': listing.type.index,
      },
    );
  }

  /// Deterministic `dm_{lowUid}_{highUid}` id so both users land in the same
  /// thread whoever starts it; `participant_ids` is stored sorted to match
  /// (the security rules check the id against it).
  @override
  Future<String> startDirectConversation(String otherUserId) async {
    if (otherUserId == _userId) {
      throw StateError('You cannot message yourself.');
    }
    final ids = [_userId, otherUserId]..sort();
    return _getOrCreate(
      id: 'dm_${ids[0]}_${ids[1]}',
      otherUserId: otherUserId,
      participantIds: ids,
      extra: const {'kind': 'direct', 'listing_id': '', 'listing_title': ''},
    );
  }

  Future<String> _getOrCreate({
    required String id,
    required String otherUserId,
    required List<String> participantIds,
    required Map<String, dynamic> extra,
  }) async {
    final ref = _conversationsCol.doc(id);

    Map<String, dynamic>? data;
    try {
      data = (await ref.get()).data();
    } on FirebaseException catch (e) {
      // Older rules deny reads of a doc that doesn't exist yet; treat that as
      // "missing" and create it below.
      if (e.code != 'permission-denied') rethrow;
    }

    if (data == null) {
      final profiles = _db.collection('profiles');
      final snaps = await Future.wait([
        profiles.doc(_userId).get(),
        profiles.doc(otherUserId).get(),
      ]);
      data = {
        'participant_ids': participantIds,
        'participants': {
          _userId: _participantEntry(snaps[0].data()),
          otherUserId: _participantEntry(snaps[1].data()),
        },
        ...extra,
        'last_message': '',
      };
      try {
        await ref.set({...data, 'updated_at': FieldValue.serverTimestamp()});
      } on FirebaseException catch (e) {
        // The create rule refuses threads between users who blocked each
        // other.
        if (e.code == 'permission-denied') {
          throw const MessagingBlockedException();
        }
        rethrow;
      }
    }

    // Mirror into Drift right away so the thread header resolves before the
    // snapshot listener catches up.
    if (await _localDb.getConversation(id) == null) {
      await _localDb.insertConversations([_conversationFromDoc(id, data)]);
    }
    return id;
  }

  @override
  Future<void> markRead(String conversationId) async {
    await _localDb.setConversationUnread(conversationId, 0);
    try {
      await _conversationsCol.doc(conversationId).update({
        'last_read.$_userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }

  @override
  Future<void> setArchived(String conversationId, bool archived) async {
    await _localDb.setConversationArchived(conversationId, archived);
    try {
      await _conversationsCol.doc(conversationId).update({
        'archived.$_userId': archived,
      });
    } catch (e) {
      // Keep the local state; it's re-synced from the next snapshot.
      debugPrint('setArchived failed: $e');
    }
  }

  Map<String, String> _participantEntry(Map<String, dynamic>? profile) {
    final name = (profile?['name'] as String?)?.trim();
    return {
      'name': name == null || name.isEmpty ? 'User' : name,
      'avatar': profile?['avatar_url'] as String? ?? '',
    };
  }

  /// Closes the remote listener; the Drift cache keeps serving reads.
  Future<void> dispose() async => _conversationsSub?.cancel();

  Conversation _conversationFromDoc(
    String id,
    Map<String, dynamic> data, {
    int unread = 0,
  }) {
    final updated = data['updated_at'];
    final other = _otherParticipant(data);
    final otherId = _otherUserId(data);
    final archived = data['archived'];
    return Conversation(
      id: id,
      participantName:
          other?['name'] as String? ??
          data['participant_name'] as String? ??
          'Chat',
      participantAvatar:
          other?['avatar'] as String? ??
          data['participant_avatar'] as String? ??
          '',
      lastMessage: data['last_message'] as String? ?? '',
      timestamp: updated is Timestamp ? updated.toDate() : DateTime.now(),
      unreadCount: unread,
      role: _otherRole(data),
      listingTitle: data['listing_title'] as String? ?? '',
      listingId: data['listing_id'] as String? ?? '',
      otherUserId: otherId,
      isArchived: archived is Map && archived[_userId] == true,
      otherLastReadAt: otherId.isEmpty ? null : _readStamp(data, otherId),
    );
  }

  String _otherUserId(Map<String, dynamic> data) {
    final ids = data['participant_ids'];
    if (ids is! List) return '';
    for (final id in ids) {
      if (id is String && id != _userId) return id;
    }
    return '';
  }

  /// `last_read.{uid}` as a DateTime; null when [uid] never opened the thread
  /// (or the server timestamp is still pending).
  DateTime? _readStamp(Map<String, dynamic> data, String uid) {
    final lastRead = data['last_read'];
    if (lastRead is! Map) return null;
    final ts = lastRead[uid];
    return ts is Timestamp ? ts.toDate() : null;
  }

  /// Name/avatar of whoever isn't [_userId] in a listing-started thread;
  /// null for legacy docs that only have flat `participant_*` fields.
  Map<String, dynamic>? _otherParticipant(Map<String, dynamic> data) {
    final participants = data['participants'];
    if (participants is! Map) return null;
    for (final entry in participants.entries) {
      if (entry.key != _userId && entry.value is Map) {
        return Map<String, dynamic>.from(entry.value as Map);
      }
    }
    return null;
  }

  /// Role of the *other* party: the listing owner is the seller (or gig
  /// client), the one who reached out is the buyer (or gig worker).
  ParticipantRole _otherRole(Map<String, dynamic> data) {
    if (data['kind'] == 'direct') return ParticipantRole.direct;
    final sellerId = data['seller_id'] as String?;
    if (sellerId == null) {
      return _enumAt(
        ParticipantRole.values,
        data['role'] as int?,
        ParticipantRole.buyer,
      );
    }
    final isGig = data['listing_type'] == ListingType.gig.index;
    final otherIsOwner = sellerId != _userId;
    if (isGig) {
      return otherIsOwner
          ? ParticipantRole.gigClient
          : ParticipantRole.gigWorker;
    }
    return otherIsOwner ? ParticipantRole.seller : ParticipantRole.buyer;
  }

  Message _messageFromDoc(
    String conversationId,
    String id,
    Map<String, dynamic> data,
  ) {
    final sent = data['sent_at'];
    return Message(
      id: id,
      conversationId: conversationId,
      text: data['text'] as String? ?? '',
      isOutgoing: (data['sender_id'] as String?) == _userId,
      sentAt: sent is Timestamp ? sent.toDate() : DateTime.now(),
    );
  }
}

T _enumAt<T extends Enum>(List<T> values, int? index, T fallback) {
  if (index == null || index < 0 || index >= values.length) return fallback;
  return values[index];
}
