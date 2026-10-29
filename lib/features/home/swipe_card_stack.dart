import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/performance_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/home/home_screen.dart';
import 'package:marketplace_gig/features/home/listing_card.dart';
import 'package:marketplace_gig/features/post/post_sheet.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

class SwipeCardStack extends ConsumerStatefulWidget {
  const SwipeCardStack({super.key, required this.listings});

  final List<Listing> listings;

  @override
  ConsumerState<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends ConsumerState<SwipeCardStack> {
  Offset _drag = Offset.zero;
  int _index = 0;
  final Set<String> _swipedIds = {};
  bool _swiping = false;

  @override
  void didUpdateWidget(SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.listings, widget.listings)) {
      _syncIndex();
    }
  }

  void _syncIndex() {
    var index = 0;
    while (index < widget.listings.length &&
        _swipedIds.contains(widget.listings[index].id)) {
      index++;
    }
    _index = index;
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.listings.length) {
      return const SizedBox.shrink();
    }

    final tier = ref.watch(deviceTierProvider).value ?? DeviceTier.low;
    final showPeek = tier == DeviceTier.high;
    final current = widget.listings[_index];
    final next = _index + 1 < widget.listings.length
        ? widget.listings[_index + 1]
        : null;

    final rotation = _drag.dx / 1000;
    final passOpacity = (_drag.dx < 0 ? (-_drag.dx / 120) : 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final saveOpacity = (_drag.dx > 0 ? (_drag.dx / 120) : 0)
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (showPeek && next != null)
                  Transform.scale(
                    scale: 0.95,
                    child: Opacity(
                      opacity: 0.7,
                      child: ListingCard(listing: next, showMenu: false),
                    ),
                  ),
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() => _drag += details.delta);
                  },
                  onPanEnd: (details) async {
                    final velocity = details.velocity.pixelsPerSecond.dx;
                    if (_drag.dx < -80 || velocity < -500) {
                      await _completeSwipe(SwipeActionType.passed);
                    } else if (_drag.dx > 80 || velocity > 500) {
                      await _completeSwipe(SwipeActionType.saved);
                    } else {
                      setState(() => _drag = Offset.zero);
                    }
                  },
                  child: Transform.translate(
                    offset: _drag,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Stack(
                        children: [
                          ListingCard(
                            listing: current,
                            onTap: () => _openDetail(current),
                          ),
                          _SwipeOverlay(
                            opacity: passOpacity,
                            color: AppColors.passRed,
                            icon: Icons.close,
                            alignLeft: true,
                            gradient: tier == DeviceTier.high,
                          ),
                          _SwipeOverlay(
                            opacity: saveOpacity,
                            color: AppColors.saveGreen,
                            icon: Icons.favorite,
                            alignLeft: false,
                            gradient: tier == DeviceTier.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            math.min(5, widget.listings.length - _index),
            (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _DeckButton(
                icon: Icons.close,
                label: 'Pass',
                onPressed: () => _completeSwipe(SwipeActionType.passed),
              ),
              const SizedBox(width: 8),
              _DeckButton(
                icon: Icons.info_outline,
                label: 'Info',
                onPressed: () => _openDetail(current),
              ),
              const SizedBox(width: 8),
              _DeckButton(
                icon: Icons.add,
                label: 'Post',
                filled: true,
                onPressed: () => showPostSheet(context),
              ),
              const SizedBox(width: 8),
              _DeckButton(
                icon: Icons.favorite_border,
                label: 'Save',
                onPressed: () => _completeSwipe(SwipeActionType.saved),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Full-screen description + seller profile for the tapped card.
  void _openDetail(Listing listing) {
    openListingDetail(context, listing);
  }

  Future<void> _completeSwipe(SwipeActionType action) async {
    if (_swiping || _index >= widget.listings.length) return;
    _swiping = true;
    try {
      final listing = widget.listings[_index];
      _swipedIds.add(listing.id);
      await handleSwipeAction(ref, listing, action);
      if (!mounted) return;
      setState(() {
        _index++;
        _drag = Offset.zero;
        _syncIndex();
      });
    } finally {
      _swiping = false;
    }
  }
}

/// One of the equal-width buttons under the card deck. The label scales down
/// instead of overflowing on narrow screens or large font settings.
class _DeckButton extends StatelessWidget {
  const _DeckButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = FittedBox(fit: BoxFit.scaleDown, child: Text(label));
    const padding = EdgeInsets.symmetric(horizontal: 6);
    return Expanded(
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: text,
              style: FilledButton.styleFrom(padding: padding),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: text,
              style: OutlinedButton.styleFrom(padding: padding),
            ),
    );
  }
}

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.opacity,
    required this.color,
    required this.icon,
    required this.alignLeft,
    required this.gradient,
  });

  final double opacity;
  final Color color;
  final IconData icon;
  final bool alignLeft;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GiglTokens.radiusLg),
              gradient: gradient
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.65),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: alignLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      end: alignLeft
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                    )
                  : null,
              color: gradient ? null : color.withValues(alpha: 0.4),
            ),
            child: Align(
              alignment: alignLeft ? Alignment.topLeft : Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Icon(icon, size: 48, color: AppColors.lightOnPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
