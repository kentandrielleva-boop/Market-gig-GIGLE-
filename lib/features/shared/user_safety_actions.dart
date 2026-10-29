import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';

/// Shown when a chat write is refused because of a block.
const kMessagingBlockedText = "This user isn't accepting messages.";

/// User-facing text for a failed "start chat" / "send" call.
String chatErrorText(Object error) => switch (error) {
  MessagingBlockedException() => kMessagingBlockedText,
  _ => "Couldn't open the chat. Try again.",
};

/// Asks for confirmation, then blocks [uid]. Returns true when blocked.
Future<bool> confirmBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required String name,
  String avatarUrl = '',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(profileRepositoryProvider);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block $name?'),
      content: const Text(
        "You won't be able to message each other, and you'll stop seeing "
        'their listings and conversations. You can unblock them in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await repo.blockUser(uid, name: name, avatarUrl: avatarUrl);
    messenger.showSnackBar(SnackBar(content: Text('$name blocked')));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not block: $e')));
    return false;
  }
}

Future<void> unblockUser(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(profileRepositoryProvider).unblockUser(uid);
    messenger.showSnackBar(SnackBar(content: Text('$name unblocked')));
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not unblock: $e')));
  }
}

/// Opens the report sheet for [uid]; once filed, offers to block them too.
Future<void> reportUser(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required String name,
  String avatarUrl = '',
  String? conversationId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(profileRepositoryProvider);
  final filed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ReportSheet(
      title: 'Report user',
      subtitle: name,
      onSubmit: (reason, details) => repo.reportUser(
        uid,
        reason,
        details: details,
        conversationId: conversationId,
      ),
    ),
  );
  if (filed == null) return;
  if (!filed) {
    messenger.showSnackBar(
      const SnackBar(content: Text('You already reported this user.')),
    );
    return;
  }
  final isBlocked = ref.read(blockedUserIdsProvider).contains(uid);
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Thanks — we will review this report.'),
      action: isBlocked
          ? null
          : SnackBarAction(
              label: 'Block',
              onPressed: () =>
                  repo.blockUser(uid, name: name, avatarUrl: avatarUrl),
            ),
    ),
  );
}

enum UserMenuAction { viewProfile, archive, unarchive, block, unblock, report }

/// Overflow menu with the safety actions for another user. [onSelected]
/// receives actions the menu doesn't handle itself (profile, archive).
class UserSafetyMenu extends ConsumerWidget {
  const UserSafetyMenu({
    super.key,
    required this.uid,
    required this.name,
    this.avatarUrl = '',
    this.conversationId,
    this.extraActions = const [],
    this.onSelected,
    this.color,
  });

  final String uid;
  final String name;
  final String avatarUrl;
  final String? conversationId;
  final List<UserMenuAction> extraActions;
  final ValueChanged<UserMenuAction>? onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked = ref.watch(blockedUserIdsProvider).contains(uid);
    final actions = [
      ...extraActions,
      isBlocked ? UserMenuAction.unblock : UserMenuAction.block,
      UserMenuAction.report,
    ];
    return PopupMenuButton<UserMenuAction>(
      tooltip: 'More options',
      icon: Icon(Icons.more_vert, color: color),
      onSelected: (action) => switch (action) {
        UserMenuAction.block => confirmBlockUser(
          context,
          ref,
          uid: uid,
          name: name,
          avatarUrl: avatarUrl,
        ),
        UserMenuAction.unblock => unblockUser(
          context,
          ref,
          uid: uid,
          name: name,
        ),
        UserMenuAction.report => reportUser(
          context,
          ref,
          uid: uid,
          name: name,
          avatarUrl: avatarUrl,
          conversationId: conversationId,
        ),
        _ => onSelected?.call(action),
      },
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: ListTile(
              leading: Icon(_icon(action)),
              title: Text(_label(action)),
            ),
          ),
      ],
    );
  }

  static IconData _icon(UserMenuAction action) => switch (action) {
    UserMenuAction.viewProfile => Icons.person_outline,
    UserMenuAction.archive => Icons.archive_outlined,
    UserMenuAction.unarchive => Icons.unarchive_outlined,
    UserMenuAction.block => Icons.block,
    UserMenuAction.unblock => Icons.lock_open_outlined,
    UserMenuAction.report => Icons.flag_outlined,
  };

  static String _label(UserMenuAction action) => switch (action) {
    UserMenuAction.viewProfile => 'View profile',
    UserMenuAction.archive => 'Archive chat',
    UserMenuAction.unarchive => 'Unarchive chat',
    UserMenuAction.block => 'Block user',
    UserMenuAction.unblock => 'Unblock user',
    UserMenuAction.report => 'Report user',
  };
}
