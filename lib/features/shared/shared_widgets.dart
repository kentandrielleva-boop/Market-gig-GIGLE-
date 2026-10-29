import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/auth/auth_gateway.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/domain/models/models.dart';

class ListingImage extends ConsumerWidget {
  const ListingImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(deviceTierProvider).value ?? DeviceTier.low;
    // Tune memory cache per tier to avoid OOM/GC jank on low-end 1GB RAM devices.
    // Low: 320x320 ~2x smaller decode, High: 480x480 full fidelity.
    final cacheSize = tier == DeviceTier.high ? 480 : 320;
    final scheme = Theme.of(context).colorScheme;
    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      placeholder: (_, _) => Container(color: scheme.outlineVariant),
      errorWidget: (_, _, _) => Container(
        color: scheme.outlineVariant,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    // Reduce overdraw on low-end by avoiding extra clip when not needed;
    // RepaintBoundary isolates image decoding raster work.
    return RepaintBoundary(child: image);
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final ListingType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final isGig = type == ListingType.gig;
    // One accent per badge: gigs use the gig hue, items use primary.
    final base = isGig ? tokens.gigs.base : scheme.primary;
    final soft = isGig ? tokens.gigs.soft : scheme.primaryContainer;
    return Chip(
      label: Text(isGig ? 'Gig' : 'Item'),
      backgroundColor: soft,
      labelStyle: TextStyle(color: base, fontWeight: FontWeight.w600),
      side: BorderSide(color: scheme.outline),
      visualDensity: VisualDensity.compact,
    );
  }
}

class PriceLabel extends StatelessWidget {
  const PriceLabel({super.key, required this.price, this.style});

  final double price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatted = price.toStringAsFixed(
      price.truncateToDouble() == price ? 0 : 2,
    );
    return Text(
      '₱$formatted',
      style:
          style ??
          Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ListingStatus.active => 'Active',
      ListingStatus.paused => 'Paused',
      ListingStatus.completed => 'Completed',
    };
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

/// Tapping a card anywhere in the app opens its full detail screen (photo
/// gallery, description, seller profile). The listing is passed along so the
/// first frame renders instantly; the route re-fetches it by id after that.
void openListingDetail(BuildContext context, Listing listing) {
  context.push('/listing/${listing.id}', extra: listing);
}

String formatTimestamp(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${time.month}/${time.day}/${time.year}';
}

String roleLabel(ParticipantRole role) {
  return switch (role) {
    ParticipantRole.buyer => 'Buyer',
    ParticipantRole.seller => 'Seller',
    ParticipantRole.gigClient => 'Gig Client',
    ParticipantRole.gigWorker => 'Gig Worker',
    ParticipantRole.direct => 'Direct',
  };
}

/// Shown when a listing stream fails only because there is no signed-in user.
/// Auth model stays login-required; this replaces the raw `Bad state` text.
class SignedOutPrompt extends StatelessWidget {
  const SignedOutPrompt({super.key, this.message = 'Sign in to see listings.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns [SignedOutPrompt] for signed-out failures, else a plain error text.
Widget asyncErrorWidget(Object error) {
  if (isSignedOutError(error)) return const SignedOutPrompt();
  return Center(child: Text('Error: $error'));
}

/// "★ 4.3 (12)" product rating for listing cards; nothing until the
/// listing has a review.
class ListingRating extends StatelessWidget {
  const ListingRating({super.key, required this.listing, this.style});

  final Listing listing;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (listing.ratingCount <= 0) return const SizedBox.shrink();
    final count = listing.ratingCount;
    return Semantics(
      label:
          'Rated ${listing.rating.toStringAsFixed(1)} out of 5 from '
          '$count ${count == 1 ? 'review' : 'reviews'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.amber),
          const SizedBox(width: 2),
          Text(
            '${listing.rating.toStringAsFixed(1)} ($count)',
            style: style ?? Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
