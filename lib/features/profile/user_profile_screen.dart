import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/reviews/review_widgets.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';
import 'package:marketplace_gig/features/shared/user_safety_actions.dart';
import 'package:marketplace_gig/features/home/screens/section_screens.dart';

/// Round profile photo with a neutral placeholder while [avatarUrl] is empty
/// or still loading. Shared by the listing detail seller card and the public
/// profile screen.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.avatarUrl, this.radius = 24});

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallback = CircleAvatar(
      radius: radius,
      child: Icon(Icons.person, size: radius * 1.1),
    );
    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: 128,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// Someone else's profile (`/user/:uid`): header with rating and stats plus
/// their reviews. The viewer can leave a review unless [uid] is themselves.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileByIdProvider(uid));
    final isSelf = ref.watch(currentUserIdProvider) == uid;

    final profile = profileAsync.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.name ?? 'Profile'),
        actions: [
          if (!isSelf)
            UserSafetyMenu(
              uid: uid,
              name: profile?.name ?? 'User',
              avatarUrl: profile?.avatarUrl ?? '',
            ),
        ],
      ),
      // A FAB rather than a header button keeps the pinned header short, so
      // the reviews list still has room on small screens.
      floatingActionButton: isSelf || profile == null
          ? null
          : _MessageUserButton(profile: profile),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const EmptyState(
              icon: Icons.person_outline,
              title: 'No profile yet',
              message: 'This user has not set up a profile.',
            );
          }
          // Header stays pinned; only the reviews list scrolls, so the
          // ReviewsTab's own ListView never nests inside another one.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(profile: profile),
              Expanded(child: ReviewsTab(uid: uid)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => asyncErrorWidget(e),
      ),
    );
  }
}

/// "Message" on someone else's profile: opens (or reuses) a direct thread.
/// Swaps to "Unblock" while the viewer has them blocked.
class _MessageUserButton extends ConsumerStatefulWidget {
  const _MessageUserButton({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_MessageUserButton> createState() => _MessageUserButtonState();
}

class _MessageUserButtonState extends ConsumerState<_MessageUserButton> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final chat = ref.read(chatRepositoryProvider);
      // Offer the user's active items/gigs so the thread can be about one;
      // a failed or empty lookup falls back to a plain direct thread.
      var listings = const <Listing>[];
      try {
        listings = await ref
            .read(listingRepositoryProvider)
            .watchListingsByOwner(widget.profile.id)
            .first
            .timeout(const Duration(seconds: 5));
      } on Object {
        listings = const [];
      }
      Listing? about;
      if (listings.isNotEmpty) {
        if (!mounted) return;
        final choice = await showModalBottomSheet<_MessageChoice>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ListingPickerSheet(
            name: widget.profile.name,
            listings: listings,
          ),
        );
        if (choice == null) return; // dismissed
        about = choice.listing;
      }
      final id = about == null
          ? await chat.startDirectConversation(widget.profile.id)
          : await chat.startConversation(about);
      // Not awaited: the push future only completes when the thread pops.
      if (mounted) context.push('/inbox/$id').ignore();
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(chatErrorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isBlocked = ref.watch(blockedUserIdsProvider).contains(profile.id);
    if (isBlocked) {
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () =>
            unblockUser(context, ref, uid: profile.id, name: profile.name),
        icon: const Icon(Icons.lock_open_outlined),
        label: const Text('Unblock'),
      );
    }
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: _busy ? null : _open,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline),
      label: const Text('Message'),
    );
  }
}

/// Result of [_ListingPickerSheet]: a listing to discuss, or null listing for
/// a general direct message.
class _MessageChoice {
  const _MessageChoice(this.listing);

  final Listing? listing;
}

/// Bottom sheet listing the user's active items and gigs; picking one opens
/// the thread about it, "General message" opens the plain direct thread.
class _ListingPickerSheet extends StatelessWidget {
  const _ListingPickerSheet({required this.name, required this.listings});

  final String name;
  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "What's your message about?",
                style: theme.textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text('General message to $name'),
              onTap: () => Navigator.pop(context, const _MessageChoice(null)),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: listings.length,
                itemBuilder: (context, i) {
                  final l = listings[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: l.primaryImageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        memCacheWidth: 128,
                        errorWidget: (_, _, _) => Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    title: Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${l.isGig ? 'Gig' : 'Item'} · '
                      '₱${l.price.toStringAsFixed(0)}',
                    ),
                    onTap: () => Navigator.pop(context, _MessageChoice(l)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onHeader = theme.colorScheme.onPrimary;
    final onHeaderMuted = onHeader.withValues(alpha: 0.7);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          UserAvatar(avatarUrl: profile.avatarUrl, radius: 40),
          const SizedBox(height: 12),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onHeader,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: onHeaderMuted),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < profile.rating.round() ? Icons.star : Icons.star_border,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${profile.rating} (${profile.reviewCount} reviews)',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onHeaderMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Listings', value: '${profile.listingsCount}'),
              _Stat(label: 'Sold', value: '${profile.soldCount}'),
              _Stat(
                label: 'Member since',
                value: DateFormat.y().format(profile.memberSince),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onHeader = Theme.of(context).colorScheme.onPrimary;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: onHeader,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
