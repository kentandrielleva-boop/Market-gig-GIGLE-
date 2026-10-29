import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/features/inbox/message_bubble.dart';
import 'package:marketplace_gig/features/profile/user_profile_screen.dart';
import 'package:marketplace_gig/features/shared/user_safety_actions.dart';
import 'package:uuid/uuid.dart';

const _pageSize = 20;

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  late final PagingController<int, Message> _pagingController;
  final _messageController = TextEditingController();
  Timer? _typingDebounce;
  DateTime _lastTypingSent = DateTime.fromMicrosecondsSinceEpoch(0);

  /// Raw (pre-dedupe) size of the page fetched last. Page keys are offsets
  /// into the history, so the next key is `last key + raw size`.
  int _lastRawCount = 0;

  DateTime _lastMarkedRead = DateTime.fromMicrosecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, Message>(
      getNextPageKey: _getNextPageKey,
      fetchPage: _fetchPage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead(force: true));
  }

  /// Clears the unread badge; throttled because every incoming message while
  /// the thread is open would otherwise write a read receipt.
  void _markRead({bool force = false}) {
    if (!mounted) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastMarkedRead).inSeconds < 2) return;
    _lastMarkedRead = now;
    ref.read(chatRepositoryProvider).markRead(widget.conversationId).ignore();
  }

  int? _getNextPageKey(PagingState<int, Message> state) {
    final keys = state.keys;
    if (keys == null || keys.isEmpty) return 0;
    if (_lastRawCount < _pageSize) return null;
    return keys.last + _lastRawCount;
  }

  Future<List<Message>> _fetchPage(int pageKey) async {
    if (!mounted) return const [];
    final repo = ref.read(chatRepositoryProvider);
    final knownIds =
        _pagingController.items?.map((m) => m.id).toSet() ?? const <String>{};
    final items = await repo.getMessagesPage(
      widget.conversationId,
      limit: _pageSize,
      offset: pageKey,
    );
    if (!mounted) return const [];
    _lastRawCount = items.length;
    return items.where((m) => !knownIds.contains(m.id)).toList();
  }

  /// Items are newest-first, so live messages go at the front of page 0.
  void _insertHead(List<Message> head) {
    final state = _pagingController.value;
    final pages = state.pages;
    if (pages == null || pages.isEmpty) return;
    _pagingController.value = state.copyWith(
      pages: [
        [...head, ...pages.first],
        ...pages.skip(1),
      ],
    );
  }

  void _mergeLiveHead(List<Message> head) {
    final current = _pagingController.items;
    if (current == null) return;
    final known = current.map((m) => m.id).toSet();
    final fresh = head.where((m) => !known.contains(m.id)).toList();
    if (fresh.isEmpty) return;
    _insertHead(fresh);
    if (fresh.any((m) => !m.isOutgoing)) _markRead();
  }

  void _onChanged(String value) {
    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastTypingSent).inSeconds < 2) return;
    _lastTypingSent = now;
    ref
        .read(chatRepositoryProvider)
        .setTyping(widget.conversationId, true)
        .ignore();
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingDebounce?.cancel();
    _typingDebounce = null;
    if (!mounted) return;
    ref
        .read(chatRepositoryProvider)
        .setTyping(widget.conversationId, false)
        .ignore();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _stopTyping();
    final optimistic = Message(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      text: text,
      isOutgoing: true,
      sentAt: DateTime.now(),
    );
    _insertHead([optimistic]);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(widget.conversationId, text, id: optimistic.id);
    } catch (e) {
      if (!mounted) return;
      _pagingController.value = _pagingController.value.filterItems(
        (m) => m.id != optimistic.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is MessagingBlockedException
                ? kMessagingBlockedText
                : 'Could not send. Try again.',
          ),
        ),
      );
    }
  }

  void _onMenu(UserMenuAction action, Conversation conversation) {
    switch (action) {
      case UserMenuAction.viewProfile:
        context.push('/user/${conversation.otherUserId}');
      case UserMenuAction.archive || UserMenuAction.unarchive:
        final archive = action == UserMenuAction.archive;
        ref
            .read(chatRepositoryProvider)
            .setArchived(conversation.id, archive)
            .ignore();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(archive ? 'Chat archived' : 'Chat restored')),
        );
      default:
        break;
    }
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _pagingController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    ref.listen<AsyncValue<List<Message>>>(
      threadMessagesProvider(widget.conversationId),
      (_, next) {
        final head = next.value;
        if (head != null) _mergeLiveHead(head);
      },
    );
    ref.watch(threadMessagesProvider(widget.conversationId));
    final typing = ref.watch(threadTypingProvider(widget.conversationId));
    final tier = ref.watch(deviceTierProvider).value ?? DeviceTier.low;
    final budget = ref.watch(animationBudgetProvider);

    final conversation = conversations.maybeWhen(
      data: (items) => items
          .where((c) => c.id == widget.conversationId)
          .cast<Conversation?>()
          .firstOrNull,
      orElse: () => null,
    );

    final otherId = conversation?.otherUserId ?? '';
    final isBlocked =
        otherId.isNotEmpty &&
        ref.watch(blockedUserIdsProvider).contains(otherId);
    final otherLastReadAt = conversation?.otherLastReadAt;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: otherId.isEmpty ? null : () => context.push('/user/$otherId'),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: conversation?.participantAvatar,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation?.participantName ?? 'Chat',
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (typing.value != null)
                      Text(
                        'typing…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (conversation != null && conversation.listingId.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: ActionChip(
                label: Text(
                  conversation.listingTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () =>
                    context.push('/listing/${conversation.listingId}'),
              ),
            ),
          if (conversation != null && otherId.isNotEmpty)
            UserSafetyMenu(
              uid: otherId,
              name: conversation.participantName,
              avatarUrl: conversation.participantAvatar,
              conversationId: conversation.id,
              extraActions: [
                UserMenuAction.viewProfile,
                conversation.isArchived
                    ? UserMenuAction.unarchive
                    : UserMenuAction.archive,
              ],
              onSelected: (action) => _onMenu(action, conversation),
            ),
        ],
      ),
      body: AppBackdrop(
        variant: AppBackdropVariant.detail,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PagingListener<int, Message>(
                  controller: _pagingController,
                  builder: (context, state, fetchNextPage) =>
                      PagedListView<int, Message>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        reverse: true,
                        builderDelegate: PagedChildBuilderDelegate<Message>(
                          itemBuilder: (context, message, index) {
                            // Items are newest-first: "Seen" goes under the
                            // latest outgoing message once the other side read it.
                            final latestOutgoing = state.items
                                ?.where((m) => m.isOutgoing)
                                .firstOrNull;
                            final seen =
                                latestOutgoing?.id == message.id &&
                                otherLastReadAt != null &&
                                !otherLastReadAt.isBefore(message.sentAt);
                            return MessageBubble(
                              message: message,
                              statusLabel: seen ? 'Seen' : null,
                              animate:
                                  tier == DeviceTier.high &&
                                  budget == AnimationBudget.full,
                            );
                          },
                          firstPageProgressIndicatorBuilder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                ),
              ),
              if (isBlocked)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "You blocked this user. You can't message each other.",
                          ),
                        ),
                        TextButton(
                          onPressed: () => unblockUser(
                            context,
                            ref,
                            uid: otherId,
                            name: conversation?.participantName ?? 'User',
                          ),
                          child: const Text('Unblock'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            // Matches the 2000-char cap in firestore.rules.
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2000),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _onChanged,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _messageController,
                          builder: (context, value, child) {
                            final hasText = value.text.trim().isNotEmpty;
                            return IconButton.filled(
                              onPressed: hasText ? _send : null,
                              icon: const Icon(Icons.send),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
