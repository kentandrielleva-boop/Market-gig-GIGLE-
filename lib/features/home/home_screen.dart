import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/discovery/models/feed_filter.dart';
import 'package:marketplace_gig/features/home/passed_history_sheet.dart';
import 'package:marketplace_gig/features/home/swipe_card_stack.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/core/widgets/section_header.dart';
import 'package:marketplace_gig/features/post/post_sheet.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.filter = FeedFilter.forYou});

  final FeedFilter filter;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _filtersOpen = false;

  void _openPassedSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const PassedHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedListingsProvider);
    final passed = ref.watch(passedListingsProvider);
    final passedCount = passed.maybeWhen(
      data: (v) => v.length,
      orElse: () => 0,
    );

    return AppBackdrop(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text(kDefaultListingLocation),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  CircularIconButton(
                    icon: Icons.tune,
                    tooltip: 'Filters',
                    onPressed: () =>
                        setState(() => _filtersOpen = !_filtersOpen),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: passedCount > 0,
                    label: Text('$passedCount'),
                    child: CircularIconButton(
                      icon: Icons.history,
                      tooltip: 'Passed items',
                      onPressed: _openPassedSheet,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: const _FilterChipRow(),
              crossFadeState: _filtersOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            Expanded(
              child: feed.when(
                data: (listings) {
                  final sorted = _sortByFilter(listings, widget.filter);
                  if (sorted.isEmpty) {
                    return _EmptyFeed(
                      hasPassed: passedCount > 0,
                      onViewPassed: _openPassedSheet,
                    );
                  }
                  return SwipeCardStack(listings: sorted);
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

class _FilterChipRow extends ConsumerWidget {
  const _FilterChipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(homeFiltersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SectionHeader(label: 'Filters'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GiglChoiceChip(
                label: 'Category',
                selected: filters.category != null,
                onSelected: (_) {
                  ref
                      .read(homeFiltersProvider.notifier)
                      .state = filters.copyWith(
                    category: filters.category == null ? 'Electronics' : null,
                    clearCategory: filters.category != null,
                  );
                },
              ),
              const SizedBox(width: 8),
              GiglChoiceChip(
                label: 'Price Range',
                selected: filters.minPrice != null,
                onSelected: (_) {
                  ref.read(homeFiltersProvider.notifier).state = filters
                      .copyWith(
                        minPrice: filters.minPrice == null ? 500 : null,
                        maxPrice: filters.maxPrice == null ? 5000 : null,
                      );
                },
              ),
              const SizedBox(width: 8),
              GiglChoiceChip(
                label: 'Distance',
                selected: filters.maxDistanceKm != null,
                onSelected: (_) {
                  ref
                      .read(homeFiltersProvider.notifier)
                      .state = filters.copyWith(
                    maxDistanceKm: filters.maxDistanceKm == null ? 10 : null,
                  );
                },
              ),
              const SizedBox(width: 8),
              GiglChoiceChip(
                label: 'Items',
                selected: filters.type == ListingType.item,
                onSelected: (_) {
                  ref.read(homeFiltersProvider.notifier).state = filters
                      .copyWith(
                        type: filters.type == ListingType.item
                            ? null
                            : ListingType.item,
                        clearType: filters.type == ListingType.item,
                      );
                },
              ),
              const SizedBox(width: 8),
              GiglChoiceChip(
                label: 'Gigs',
                selected: filters.type == ListingType.gig,
                onSelected: (_) {
                  ref.read(homeFiltersProvider.notifier).state = filters
                      .copyWith(
                        type: filters.type == ListingType.gig
                            ? null
                            : ListingType.gig,
                        clearType: filters.type == ListingType.gig,
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.hasPassed, required this.onViewPassed});

  final bool hasPassed;
  final VoidCallback onViewPassed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No more items found. Come again next time…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showPostSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Post an item or gig'),
            ),
            if (hasPassed) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onViewPassed,
                child: const Text('View passed items'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<Listing> _sortByFilter(List<Listing> listings, FeedFilter filter) {
  final sorted = List<Listing>.from(listings);
  switch (filter) {
    case FeedFilter.nearby:
      sorted.sort((a, b) => a.location.compareTo(b.location));
      break;
    case FeedFilter.trending:
      sorted.sort((a, b) => b.price.compareTo(a.price));
      break;
    case FeedFilter.forYou:
      break;
  }
  return sorted;
}

Future<void> handleSwipeAction(
  WidgetRef ref,
  Listing listing,
  SwipeActionType action,
) async {
  HapticFeedback.mediumImpact();
  final repo = ref.read(listingRepositoryProvider);
  if (action == SwipeActionType.passed) {
    await repo.pass(listing.id);
  } else {
    await repo.save(listing.id);
  }
}
