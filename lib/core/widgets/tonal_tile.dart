import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';

/// Pastel tonal tile: category [accent] @ 14% tint fill, ink text, radius
/// lg, no border. Used for summaries, list rows and stats. Purely
/// presentational — callers pass data the screen already has.
class TonalTile extends StatelessWidget {
  const TonalTile({
    super.key,
    required this.accent,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// Category base hue (e.g. `tokens.gigs.base`); fill derives @ 14% alpha.
  final Color accent;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle.merge(
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: tokens.ink),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GiglTokens.radiusLg),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(GiglTokens.radiusLg),
              child: content,
            )
          : content,
    );
  }
}
