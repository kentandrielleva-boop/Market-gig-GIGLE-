import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.showMenu = true,
    this.onTap,
  });

  final Listing listing;
  final bool showMenu;

  /// Opens the detail screen. Null on the background peek card so only the
  /// top card reacts; taps still lose to the deck's drag gesture when the
  /// pointer moves.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ListingImage(url: listing.primaryImageUrl),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.05),
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(top: 16, left: 16, child: TypeBadge(type: listing.type)),
            if (showMenu)
              Positioned(
                top: 4,
                right: 4,
                child: ListingMenuButton(
                  listing: listing,
                  color: AppColors.lightOnPrimary,
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.lightOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PriceLabel(
                    price: listing.price,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.lightOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (listing.ratingCount > 0) ...[
                    const SizedBox(height: 4),
                    ListingRating(
                      listing: listing,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightOnPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
