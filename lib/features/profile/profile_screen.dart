import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/reviews/review_widgets.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final myListings = ref.watch(myListingsProvider);
    final saved = ref.watch(savedListingsProvider);

    Future<void> confirmSignOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will be signed out and local inbox/cache will be cleared for privacy.',
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
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        final dbAsync = ref.read(appDatabaseProvider);
        final db = dbAsync.value;
        if (db != null) {
          await (db.delete(db.messagesTable)).go();
          await (db.delete(db.conversationsTable)).go();
          await (db.delete(db.swipeStatesTable)).go();
        }
        await ref.read(authGatewayProvider).signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not sign out: $e')));
        }
      }
    }

    return AppBackdrop(
      variant: AppBackdropVariant.detail,
      child: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                profileAsync: profileAsync,
                onSignOut: confirmSignOut,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'My Listings'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Reviews'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _MyListingsTab(listingsAsync: myListings),
              _SavedTab(listingsAsync: saved),
              ReviewsTab(uid: ref.watch(currentUserIdProvider)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profileAsync, required this.onSignOut});

  final AsyncValue<UserProfile?> profileAsync;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return profileAsync.when(
      data: (profile) {
        final scheme = Theme.of(context).colorScheme;
        final onHeader = scheme.onPrimary;
        final onHeaderMuted = onHeader.withValues(alpha: 0.7);
        if (profile == null) {
          return Container(
            width: double.infinity,
            color: scheme.primary,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 40,
              24,
              24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 48, color: onHeaderMuted),
                const SizedBox(height: 12),
                Text(
                  'Set up your profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onHeader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your name, bio and avatar so others can find you.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onHeaderMuted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Set up profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.primary,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          width: double.infinity,
          color: scheme.primary,
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 4,
            16,
            24,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircularIconButton(
                    icon: Icons.edit,
                    tooltip: 'Edit profile',
                    onPressed: () => context.go('/profile/edit'),
                  ),
                  const Spacer(),
                  CircularIconButton(
                    icon: Icons.logout,
                    tooltip: 'Sign out',
                    onPressed: onSignOut,
                  ),
                ],
              ),
              _ProfileAvatar(avatarUrl: profile.avatarUrl),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onHeader,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    profile.bio,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: onHeaderMuted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (i) {
                    final filled = i < profile.rating.round();
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: AppColors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${profile.rating} (${profile.reviewCount} reviews)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: onHeaderMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: 'Listings',
                    value: '${profile.listingsCount}',
                  ),
                  _StatItem(label: 'Sold', value: '${profile.soldCount}'),
                  _StatItem(
                    label: 'Member since',
                    value: DateFormat.y().format(profile.memberSince),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.go('/legal'),
                icon: Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: onHeaderMuted,
                ),
                label: Text(
                  'Terms & EULA',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: onHeaderMuted),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(height: 220, child: asyncErrorWidget(e)),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onHeader = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: onHeader,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: onHeader.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _MyListingsTab extends StatelessWidget {
  const _MyListingsTab({required this.listingsAsync});

  final AsyncValue<List<Listing>> listingsAsync;

  @override
  Widget build(BuildContext context) {
    return listingsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No listings yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            FloatingDock.bottomPadding,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final listing = items[index];
            return Card(
              child: ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: ListingImage(
                    url: listing.primaryImageUrl,
                    borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
                  ),
                ),
                title: Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => openListingDetail(context, listing),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TypeBadge(type: listing.type),
                      StatusChip(status: listing.status),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceLabel(price: listing.price),
                    ListingMenuButton(listing: listing),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => asyncErrorWidget(e),
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({required this.listingsAsync});

  final AsyncValue<List<Listing>> listingsAsync;

  @override
  Widget build(BuildContext context) {
    return listingsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No saved listings'));
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            FloatingDock.bottomPadding,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final listing = items[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openListingDetail(context, listing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ListingImage(url: listing.primaryImageUrl)),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TypeBadge(type: listing.type),
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          PriceLabel(price: listing.price),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => asyncErrorWidget(e),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(deviceTierProvider).value ?? DeviceTier.low;
    final cacheSize = tier == DeviceTier.high ? 192 : 128;
    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 48,
        child: Icon(Icons.person, size: 48),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        placeholder: (_, _) => Container(
          width: 96,
          height: 96,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, _, _) =>
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
      ),
    );
  }
}
