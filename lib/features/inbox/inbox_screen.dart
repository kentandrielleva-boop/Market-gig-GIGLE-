import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/core/widgets/section_header.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Swiped-away ids, hidden immediately: a dismissed [Dismissible] must
  /// leave the tree before the archive write reaches the Drift stream.
  final _dismissed = <String>{};

  void _archive(String conversationId) {
    final repo = ref.read(chatRepositoryProvider);
    setState(() => _dismissed.add(conversationId));
    repo.setArchived(conversationId, true).ignore();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (mounted) setState(() => _dismissed.remove(conversationId));
            repo.setArchived(conversationId, false).ignore();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(filteredConversationsProvider);

    return AppBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Inbox',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                hintText: 'Search conversations',
                leading: const Icon(Icons.search),
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(inboxSearchProvider.notifier).state = value,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SectionHeader(label: 'Conversations'),
            ),
            Expanded(
              child: conversations.when(
                data: (all) {
                  // Once the archive lands the id drops out of [all]; forget it
                  // so a later unarchive (Archived screen) shows the row again.
                  _dismissed.removeWhere((id) => !all.any((c) => c.id == id));
                  final items = _dismissed.isEmpty
                      ? all
                      : all.where((c) => !_dismissed.contains(c.id)).toList();
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No conversations yet'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      FloatingDock.bottomPadding,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final tier =
                          ref.watch(deviceTierProvider).value ?? DeviceTier.low;
                      final avatarSize = tier == DeviceTier.high ? 80 : 64;
                      final avatarUrl = item.participantAvatar;
                      final tile = ListTile(
                        leading: avatarUrl.isEmpty
                            ? const CircleAvatar(child: Icon(Icons.person))
                            : ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  memCacheWidth: avatarSize,
                                  memCacheHeight: avatarSize,
                                  placeholder: (_, _) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                    child: Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                        title: Text(item.participantName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text(roleLabel(item.role)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (item.listingTitle.isNotEmpty)
                                  Text(
                                    item.listingTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatTimestamp(item.timestamp)),
                            if (item.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Badge(label: Text('${item.unreadCount}')),
                            ],
                          ],
                        ),
                        onTap: () => context.push('/inbox/${item.id}'),
                      );
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.archive_outlined),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                        onDismissed: (_) => _archive(item.id),
                        child: tile,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => asyncErrorWidget(e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
