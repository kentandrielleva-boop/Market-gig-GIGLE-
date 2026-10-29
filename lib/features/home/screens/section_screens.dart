import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/app_header.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/core/widgets/section_header.dart';
import 'package:marketplace_gig/core/widgets/tonal_tile.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/reviews/review_widgets.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';
import 'package:marketplace_gig/features/profile/user_profile_screen.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';
import 'package:marketplace_gig/features/shared/user_safety_actions.dart';

/// Every listing visible to the user, unaffected by the home feed filters
/// (blocked users' listings are still hidden).
final browseListingsProvider = StreamProvider<List<Listing>>((ref) {
  final blocked = ref.watch(blockedUserIdsProvider);
  return ref
      .watch(listingRepositoryProvider)
      .watchFeed()
      .map(
        (list) => blocked.isEmpty
            ? list
            : list.where((l) => !blocked.contains(l.ownerId)).toList(),
      );
});

void _leave(BuildContext context) {
  context.go('/home');
}

/// App bar + back handling for screens opened from the radial menu, which
/// arrive via `context.go` and may have no history to pop.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        body: AppBackdrop(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: title,
                  onBack: () => _leave(context),
                  trailing: actions,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingAction {
  const ListingAction({
    required this.label,
    required this.icon,
    required this.run,
  });

  final String label;
  final IconData icon;
  final Future<void> Function(WidgetRef ref, Listing listing) run;
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({
    required this.listing,
    this.showStatus = false,
    this.action,
    this.onTap,
  });

  final Listing listing;
  final bool showStatus;
  final ListingAction? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ListingImage(
                  url: listing.primaryImageUrl,
                  borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TypeBadge(type: listing.type),
                        if (showStatus) StatusChip(status: listing.status),
                        ListingRating(listing: listing),
                      ],
                    ),
                    Text(
                      '${listing.category} · ${listing.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriceLabel(price: listing.price),
                      ListingMenuButton(listing: listing),
                    ],
                  ),
                  if (action != null)
                    TextButton.icon(
                      onPressed: () => action!.run(ref, listing),
                      icon: Icon(action!.icon, size: 16),
                      label: Text(action!.label),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled list of listings from any provider, with filter/sort hooks and an
/// empty state.
class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({
    super.key,
    required this.title,
    required this.source,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.where,
    this.sort,
    this.showStatus = false,
    this.action,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<Listing>>> source;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final bool Function(Listing)? where;
  final int Function(Listing, Listing)? sort;
  final bool showStatus;
  final ListingAction? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionScaffold(
      title: title,
      body: ref
          .watch(source)
          .when(
            data: (all) {
              var items = where == null ? all : all.where(where!).toList();
              if (sort != null) items = [...items]..sort(sort);
              if (items.isEmpty) {
                return EmptyState(
                  icon: emptyIcon,
                  title: emptyTitle,
                  message: emptyMessage,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ListingCard(
                  listing: items[i],
                  showStatus: showStatus,
                  action: action,
                  onTap: () => openListingDetail(context, items[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

ListingAction _removeSwipeAction(String label, IconData icon) => ListingAction(
  label: label,
  icon: icon,
  run: (ref, l) => ref.read(listingRepositoryProvider).restorePassed(l.id),
);

// ---------------------------------------------------------------- Saved

class LikedItemsScreen extends StatelessWidget {
  const LikedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'Liked',
    source: savedListingsProvider,
    emptyIcon: Icons.favorite_outline,
    emptyTitle: 'Nothing liked yet',
    emptyMessage: 'Items and gigs you like will show up here.',
    action: _removeSwipeAction('Remove', Icons.close),
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'History',
    source: passedListingsProvider,
    emptyIcon: Icons.history_outlined,
    emptyTitle: 'Nothing passed yet',
    emptyMessage:
        'Listings you swipe past appear here so you can bring them back.',
    action: _removeSwipeAction('Restore', Icons.undo),
  );
}

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionScaffold(
      title: 'Collections',
      body: ref
          .watch(savedListingsProvider)
          .when(
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'No collections yet',
                  message: 'Saved listings are grouped here by category.',
                );
              }
              final byCategory = <String, List<Listing>>{};
              for (final l in items) {
                byCategory.putIfAbsent(l.category, () => []).add(l);
              }
              final categories = byCategory.keys.toList()..sort();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final c in categories) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: SectionHeader(
                        label: '$c · ${byCategory[c]!.length}',
                      ),
                    ),
                    for (final l in byCategory[c]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ListingCard(
                          listing: l,
                          action: _removeSwipeAction('Remove', Icons.close),
                          onTap: () => openListingDetail(context, l),
                        ),
                      ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

// ----------------------------------------------------------------- Gigs

class BrowseGigsScreen extends StatelessWidget {
  const BrowseGigsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'Browse gigs',
    source: browseListingsProvider,
    where: (l) => l.type == ListingType.gig,
    emptyIcon: Icons.search_off_outlined,
    emptyTitle: 'No gigs available',
    emptyMessage: 'Check back soon, or post one yourself with the Post button.',
  );
}

class MyGigsScreen extends StatelessWidget {
  const MyGigsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'My gigs',
    source: myListingsProvider,
    where: (l) => l.type == ListingType.gig,
    showStatus: true,
    emptyIcon: Icons.list_alt_outlined,
    emptyTitle: 'You have not posted a gig',
    emptyMessage: 'Gigs you post will be tracked here.',
  );
}

// --------------------------------------------------------------- Market

class AllItemsScreen extends StatelessWidget {
  const AllItemsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'All items',
    source: browseListingsProvider,
    where: (l) => l.type == ListingType.item,
    emptyIcon: Icons.store_outlined,
    emptyTitle: 'No items for sale',
    emptyMessage: 'Be the first to list something with the Post button.',
  );
}

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'My listings',
    source: myListingsProvider,
    where: (l) => l.type == ListingType.item,
    showStatus: true,
    emptyIcon: Icons.sell_outlined,
    emptyTitle: 'You have no listings',
    emptyMessage: 'Items you put up for sale will be tracked here.',
  );
}

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListingsScreen(
    title: 'Deals',
    source: browseListingsProvider,
    where: (l) => l.type == ListingType.item,
    sort: (a, b) => a.price.compareTo(b.price),
    emptyIcon: Icons.discount_outlined,
    emptyTitle: 'No deals right now',
    emptyMessage: 'The lowest-priced items show up here, cheapest first.',
  );
}

// ---------------------------------------------------------------- Inbox

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionScaffold(
      title: 'Requests',
      body: ref
          .watch(activeConversationsProvider)
          .when(
            data: (all) {
              final unread = all.where((c) => c.unreadCount > 0).toList();
              if (unread.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No new requests',
                  message: 'Conversations with unread messages show up here.',
                );
              }
              return ListView.separated(
                itemCount: unread.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = unread[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c.participantName),
                    subtitle: Text(
                      c.listingTitle.isEmpty
                          ? c.lastMessage
                          : '${c.listingTitle}\n${c.lastMessage}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: c.listingTitle.isNotEmpty,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatTimestamp(c.timestamp)),
                        const SizedBox(height: 4),
                        Badge(label: Text('${c.unreadCount}')),
                      ],
                    ),
                    onTap: () => context.push('/inbox/${c.id}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

class ArchivedChatsScreen extends ConsumerWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionScaffold(
      title: 'Archived',
      body: ref
          .watch(archivedConversationsProvider)
          .when(
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.archive_outlined,
                  title: 'No archived chats',
                  message: 'Swipe a conversation in your inbox to archive it.',
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = items[i];
                  return ListTile(
                    leading: UserAvatar(
                      avatarUrl: c.participantAvatar,
                      radius: 20,
                    ),
                    title: Text(c.participantName),
                    subtitle: Text(
                      c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Unarchive',
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ref
                          .read(chatRepositoryProvider)
                          .setArchived(c.id, false)
                          .ignore(),
                    ),
                    onTap: () => context.push('/inbox/${c.id}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

// -------------------------------------------------------------- Profile

class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key, this.title = 'Ratings'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionScaffold(
    title: title,
    body: ReviewsTab(uid: ref.watch(currentUserIdProvider)),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authGatewayProvider).currentEmail;
    return SectionScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Account'),
            subtitle: Text(email ?? 'Signed in'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/settings/blocked'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & EULA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal'),
          ),
        ],
      ),
    );
  }
}

/// Settings → Blocked users: everyone the viewer blocked, with Unblock.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: ref
          .watch(blockedUsersProvider)
          .when(
            data: (users) {
              if (users.isEmpty) {
                return const EmptyState(
                  icon: Icons.block,
                  title: 'No blocked users',
                  message:
                      'People you block from a profile or chat show up here.',
                );
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final user = users[i];
                  return ListTile(
                    leading: UserAvatar(avatarUrl: user.avatarUrl, radius: 20),
                    title: Text(user.name),
                    trailing: TextButton(
                      onPressed: () => unblockUser(
                        context,
                        ref,
                        uid: user.id,
                        name: user.name,
                      ),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return SectionScaffold(
      title: 'Wallet',
      body: ref
          .watch(myListingsProvider)
          .when(
            data: (items) {
              final done = items
                  .where((l) => l.status == ListingStatus.completed)
                  .toList();
              final total = done.fold<double>(0, (sum, l) => sum + l.price);
              final active = items
                  .where((l) => l.status == ListingStatus.active)
                  .length;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TonalTile(
                    accent: tokens.gigs.base,
                    title: Text(
                      'Total earned',
                      style: theme.textTheme.labelLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceLabel(
                          price: total,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        Text(
                          'Based on your completed listings',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TonalTile(
                          accent: tokens.chats.base,
                          title: Text(
                            '$active',
                            style: theme.textTheme.headlineSmall,
                          ),
                          subtitle: const Text('Active'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TonalTile(
                          accent: tokens.saved.base,
                          title: Text(
                            '${done.length}',
                            style: theme.textTheme.headlineSmall,
                          ),
                          subtitle: const Text('Completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(label: 'Earnings'),
                  const SizedBox(height: 8),
                  if (done.isEmpty)
                    Text(
                      'Mark a listing as completed and it will count here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final l in done)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ListingCard(
                          listing: l,
                          onTap: () => openListingDetail(context, l),
                        ),
                      ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => asyncErrorWidget(e),
          ),
    );
  }
}

// -------------------------------------------------------------- Filters

class FilterSheetScreen extends ConsumerStatefulWidget {
  const FilterSheetScreen({super.key});

  @override
  ConsumerState<FilterSheetScreen> createState() => _FilterSheetScreenState();
}

class _FilterSheetScreenState extends ConsumerState<FilterSheetScreen> {
  static const _categories = ['General', 'Services', 'Electronics'];
  static const _maxPrice = 10000.0;

  late ListingType? _type;
  late String? _category;
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    final f = ref.read(homeFiltersProvider);
    _type = f.type;
    _category = f.category;
    _range = RangeValues(f.minPrice ?? 0, f.maxPrice ?? _maxPrice);
  }

  void _apply() {
    ref.read(homeFiltersProvider.notifier).state = HomeFilters(
      type: _type,
      category: _category,
      minPrice: _range.start > 0 ? _range.start : null,
      maxPrice: _range.end < _maxPrice ? _range.end : null,
    );
    context.go('/home/discover/feed');
  }

  void _reset() => setState(() {
    _type = null;
    _category = null;
    _range = const RangeValues(0, _maxPrice);
  });

  @override
  Widget build(BuildContext context) {
    final endLabel = _range.end >= _maxPrice
        ? '₱${_maxPrice.round()}+'
        : '₱${_range.end.round()}';
    return SectionScaffold(
      title: 'Filters',
      actions: [TextButton(onPressed: _reset, child: const Text('Reset'))],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(label: 'Type'),
                const SizedBox(height: 8),
                SegmentedButton<ListingType?>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(
                      value: ListingType.item,
                      label: Text('Items'),
                    ),
                    ButtonSegment(value: ListingType.gig, label: Text('Gigs')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 24),
                const SectionHeader(label: 'Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in _categories)
                      GiglChoiceChip(
                        label: c,
                        selected: _category == c,
                        onSelected: (on) =>
                            setState(() => _category = on ? c : null),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  label: 'Price: ₱${_range.start.round()} – $endLabel',
                ),
                RangeSlider(
                  values: _range,
                  max: _maxPrice,
                  divisions: 100,
                  labels: RangeLabels(
                    '₱${_range.start.round()}',
                    '₱${_range.end.round()}',
                  ),
                  onChanged: (v) => setState(() => _range = v),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Show results'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
