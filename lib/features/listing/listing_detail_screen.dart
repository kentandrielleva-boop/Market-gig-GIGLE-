import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/home_screen.dart';
import 'package:marketplace_gig/features/reviews/review_widgets.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';
import 'package:marketplace_gig/features/shared/user_safety_actions.dart';
import 'package:marketplace_gig/features/profile/user_profile_screen.dart';

/// Full-screen detail for one gig or item: photo gallery, the complete
/// description, product reviews, and the listing owner's public profile.
/// Opened by tapping a
/// card anywhere in the app (`/listing/:id`).
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.initialListing,
  });

  final String listingId;

  /// Passed by the card that pushed this route so the first frame has
  /// content; the stream below keeps it fresh and flags deletions.
  final Listing? initialListing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingByIdProvider(listingId));
    final gone = async.hasValue && async.value == null;
    final listing = gone ? null : (async.value ?? initialListing);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: gone
            ? const _GoneState()
            : Center(
                child: async.hasError
                    ? asyncErrorWidget(async.error!)
                    : const CircularProgressIndicator(),
              ),
      );
    }

    final isOwn = listing.ownerId == ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(listing.isGig ? 'Gig details' : 'Item details'),
        actions: [ListingMenuButton(listing: listing)],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cap the strip so title/description land above the fold on wide
          // screens too (a raw 4:3 at tablet width would be 600+ px tall).
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: (constraints.maxWidth * 3 / 4).clamp(200.0, 360.0),
              child: _ImageGallery(urls: listing.imageUrls),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TypeBadge(type: listing.type),
                    if (isOwn) StatusChip(status: listing.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                PriceLabel(
                  price: listing.price,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: listing.category,
                    ),
                    _MetaChip(
                      icon: Icons.place_outlined,
                      label: listing.location,
                    ),
                    if (listing.duration != null)
                      _MetaChip(
                        icon: Icons.schedule_outlined,
                        label: listing.duration!,
                      ),
                    if (listing.remoteOnly)
                      const _MetaChip(
                        icon: Icons.wifi_outlined,
                        label: 'Remote only',
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description.trim().isEmpty
                      ? 'No description provided.'
                      : listing.description.trim(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 24),
                ReviewsSection(
                  target: (kind: ReviewKind.listing, id: listing.id),
                  listing: listing,
                  embedded: true,
                ),
                const SizedBox(height: 24),
                Text('Seller', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _SellerCard(ownerId: listing.ownerId),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (!isOwn)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MessageButton(listing: listing),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _swipe(
                              context,
                              ref,
                              listing,
                              SwipeActionType.passed,
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('Pass'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _swipe(
                              context,
                              ref,
                              listing,
                              SwipeActionType.saved,
                            ),
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _swipe(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
    SwipeActionType action,
  ) async {
    await handleSwipeAction(ref, listing, action);
    if (!context.mounted) return;
    if (action == SwipeActionType.passed) {
      // Leaving the feed: go back to it rather than sit on a listing the
      // user just passed.
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to your likes')));
    }
  }
}

/// Opens (creating on first tap) the buyer's thread with the listing owner.
class _MessageButton extends ConsumerStatefulWidget {
  const _MessageButton({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<_MessageButton> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .startConversation(widget.listing);
      if (!mounted) return;
      context.push('/inbox/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatErrorText(e))));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _opening ? null : _open,
      icon: _opening
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline),
      label: Text(widget.listing.isGig ? 'Message poster' : 'Message seller'),
    );
  }
}

class _GoneState extends StatelessWidget {
  const _GoneState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'This listing is no longer available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Swipeable photo strip with page dots. Falls back to the shared placeholder
/// image when the listing has none.
class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.urls});

  final List<String> urls;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _page = 0;

  List<String> get _images =>
      widget.urls.isEmpty ? const [Listing.fallbackImageUrl] : widget.urls;

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (_, i) => ListingImage(url: images[i]),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Owner row → public profile. Shows a neutral placeholder while the profile
/// loads or when the seller has not set one up yet.
class _SellerCard extends ConsumerWidget {
  const _SellerCard({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileByIdProvider(ownerId));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/user/$ownerId'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              profileAsync.when(
                data: (profile) =>
                    UserAvatar(avatarUrl: profile?.avatarUrl, radius: 24),
                loading: () => const UserAvatar(radius: 24),
                error: (_, _) => const UserAvatar(radius: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: profileAsync.when(
                  data: (profile) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? 'Seller',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${profile.rating} (${profile.reviewCount} reviews)',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  loading: () =>
                      Text('Loading…', style: theme.textTheme.bodySmall),
                  error: (_, _) =>
                      Text('Seller', style: theme.textTheme.bodySmall),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
