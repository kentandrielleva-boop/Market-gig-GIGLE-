import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_typography.dart';

/// Section header: overline label left, optional "See all" text button right.
/// Purely presentational.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
  });

  final String label;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.overline(scheme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(seeAllLabel),
          ),
      ],
    );
  }
}
