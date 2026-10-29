import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class PassedHistorySheet extends ConsumerWidget {
  const PassedHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passed = ref.watch(passedListingsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Passed Items', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            passed.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Nothing passed yet')),
                  );
                }
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final listing = items[index];
                      return InkWell(
                        onTap: () => openListingDetail(context, listing),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ListingImage(
                                      url: listing.primaryImageUrl,
                                      borderRadius: BorderRadius.circular(
                                        GiglTokens.radiusSm,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(
                                          GiglTokens.radiusSm,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: AppColors.lightOnPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Row(
                                      children: [
                                        TypeBadge(type: listing.type),
                                        const SizedBox(width: 8),
                                        PriceLabel(price: listing.price),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(listingRepositoryProvider)
                                      .restorePassed(listing.id);
                                },
                                child: const Text('Restore'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => asyncErrorWidget(e),
            ),
          ],
        ),
      ),
    );
  }
}
