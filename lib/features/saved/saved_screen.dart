import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/core/widgets/section_header.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedListingsProvider);

    return AppBackdrop(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Saved',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SectionHeader(label: 'Saved items'),
            ),
            Expanded(
              child: saved.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No saved listings yet'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      FloatingDock.bottomPadding,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                              Expanded(
                                child: ListingImage(
                                  url: listing.primaryImageUrl,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TypeBadge(type: listing.type),
                                    const SizedBox(height: 4),
                                    Text(
                                      listing.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
