import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/theme/widgets/gigl_logo.dart';

/// Floating dock replacing the flat bottom bar / FAB.
///
/// Inset 16dp from screen edges and 12dp above the safe-area bottom, pill
/// shape, OPAQUE ink fill (light: charcoal `dockSurface` + onInk text;
/// dark: `surfaceRaised` + 1px outline + light text — glass would leave
/// white-on-pale-glass text unreadable), eDock shadow. Contents are exactly
/// what the shell shows today: logo + title (onInk 600) + subtitle (onInk
/// @ 72%) on the left, and the "Post" action on the right as a SOLID brand
/// primary pill with brandOnPrimary icon+label and a primary-tinted glow.
/// Same tap targets and callbacks.
///
/// Place as [Scaffold.floatingActionButton] with
/// [FloatingActionButtonLocation.centerDocked]-style bottom offset, or as a
/// [Stack] overlay; scrollables must add bottom padding of
/// [FloatingDock.bottomPadding] so content never hides behind it.
class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.onPost,
    this.title = 'Gigl',
    this.subtitle,
    this.postLabel = 'Post',
  });

  final VoidCallback onPost;
  final String title;
  final String? subtitle;
  final String postLabel;

  /// Minimum bottom clearance scrollables must reserve (dock + margins).
  static const double bottomPadding = 96;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    // Opaque ink surface: charcoal in light, raised surface + outline in
    // dark (see token docs). Contrast pairs for both live in
    // tool/check_contrast.dart (dock title/subtitle).
    final dark = tokens.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.dockSurface,
            borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
            border: dark ? Border.all(color: tokens.outline, width: 1) : null,
            boxShadow: tokens.shadowEDock,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const GiglLogo(size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          color: tokens.onInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.onInk.withValues(alpha: 0.72),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
                    boxShadow: tokens.shadowE2,
                  ),
                  child: FilledButton.icon(
                    onPressed: onPost,
                    style: FilledButton.styleFrom(
                      // Fixed brand accents: the OS dynamic-color palette must
                      // never mute the Post pill into slate-blue.
                      backgroundColor: tokens.brandPrimary,
                      foregroundColor: tokens.brandOnPrimary,
                      // Inside a Row the theme's full-width minimumSize
                      // (Size.fromHeight) would force an infinite min width;
                      // pin a finite 44dp-tall target instead.
                      minimumSize: const Size(64, 44),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(postLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
