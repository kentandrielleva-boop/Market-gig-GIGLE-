import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/theme/app_theme.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/listing_card.dart';
import 'package:marketplace_gig/features/inbox/inbox_screen.dart';
import 'package:marketplace_gig/features/post/post_sheet.dart';
import 'package:marketplace_gig/features/profile/profile_screen.dart';

/// Preview harness for the 6 design frames at 360x800.
class DesignPreviewFrame extends StatelessWidget {
  const DesignPreviewFrame({
    super.key,
    required this.title,
    required this.child,
    this.tier = DeviceTier.high,
  });

  final String title;
  final Widget child;
  final DeviceTier tier;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [deviceTierProvider.overrideWith((ref) => Future.value(tier))],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(tier: tier),
        home: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SizedBox(
            width: 360,
            height: 800,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(360, 800)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class HomePreview extends StatelessWidget {
  const HomePreview({super.key, this.tier = DeviceTier.high});

  final DeviceTier tier;

  @override
  Widget build(BuildContext context) {
    // Sample listings removed — previews now use minimal inline fakes so no
    // sample dataset ships in production.
    final previewListings = [
      const Listing(
        id: 'preview-1',
        type: ListingType.item,
        title: 'Preview Item',
        price: 1200,
        description: 'Sample preview listing — not seeded in production.',
        imageUrls: [],
        category: 'General',
        location: kDefaultListingLocation,
      ),
      const Listing(
        id: 'preview-2',
        type: ListingType.gig,
        title: 'Preview Gig',
        price: 800,
        description: 'Sample gig preview.',
        imageUrls: [],
        category: 'Services',
        location: 'Makati',
        duration: '3 days',
        remoteOnly: true,
      ),
    ];
    return DesignPreviewFrame(
      title: 'Home - ${tier.name.toUpperCase()}',
      tier: tier,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Chip(label: Text(kDefaultListingLocation)),
                Spacer(),
                Icon(Icons.tune),
                SizedBox(width: 8),
                Icon(Icons.history),
              ],
            ),
          ),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Category'),
                  selected: true,
                  onSelected: null,
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Price Range'),
                  selected: false,
                  onSelected: null,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  if (tier == DeviceTier.high)
                    Transform.scale(
                      scale: 0.95,
                      child: Opacity(
                        opacity: 0.7,
                        child: ListingCard(listing: previewListings[1]),
                      ),
                    ),
                  ListingCard(listing: previewListings.first),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostItemPreview extends StatelessWidget {
  const PostItemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesignPreviewFrame(
      title: 'Post - Sell an Item',
      child: PostSheet(),
    );
  }
}

class PostGigPreview extends StatelessWidget {
  const PostGigPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignPreviewFrame(
      title: 'Post - Post a Gig',
      child: ProviderScope(
        overrides: [
          deviceTierProvider.overrideWith(
            (ref) => Future.value(DeviceTier.high),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(tier: DeviceTier.high),
          home: const Scaffold(body: PostSheet()),
        ),
      ),
    );
  }
}

class InboxPreview extends StatelessWidget {
  const InboxPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesignPreviewFrame(title: 'Inbox', child: InboxScreen());
  }
}

class ChatPreview extends StatelessWidget {
  const ChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesignPreviewFrame(
      title: 'Chat Thread',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No messages — inbox starts empty'),
        ),
      ),
    );
  }
}

class ProfilePreview extends StatelessWidget {
  const ProfilePreview({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DesignPreviewFrame(
      title: 'Profile - Tab $initialTab',
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: const ProfileScreen(),
      ),
    );
  }
}
