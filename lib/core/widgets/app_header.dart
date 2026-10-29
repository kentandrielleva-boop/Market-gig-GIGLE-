import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';

/// Transparent header replacing ad-hoc app bars: wordmark "Gigl" (700,
/// primary) on the left; existing screen actions become 44dp circular icon
/// buttons on the right. Same actions as today, no new ones.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title = 'Gigl',
    this.subtitle,
    this.onTitleTap,
    this.onBack,
    this.actions = const [],
    this.trailing,
    this.leading,
  });

  final String title;

  /// Optional second line (bodySmall, inkMuted) — e.g. a typing indicator.
  final String? subtitle;

  final VoidCallback? onTitleTap;

  /// Renders a 44dp circular back chevron first (no history assumptions).
  final VoidCallback? onBack;
  final List<AppHeaderAction> actions;

  /// Raw trailing widgets (e.g. a Reset text button) — unchanged actions.
  final List<Widget>? trailing;

  /// Optional mark before the wordmark (e.g. the Gigl logo).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            // Fixed brand accent: never muted by the dynamic-color override.
            color: tokens.brandPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    final titleWidget = Expanded(
      child: onTitleTap != null
          ? InkWell(
              onTap: onTitleTap,
              borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: titleColumn,
              ),
            )
          : titleColumn,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (onBack != null) ...[
            CircularIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
          ],
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          titleWidget,
          for (final action in actions) ...[
            const SizedBox(width: 8),
            CircularIconButton(
              icon: action.icon,
              tooltip: action.tooltip,
              onPressed: action.onPressed,
              emphasis: action.emphasis,
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), ...trailing!],
        ],
      ),
    );
  }
}

/// One header action: same icon/callback the screen already had.
@immutable
class AppHeaderAction {
  const AppHeaderAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.emphasis = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// True renders the ink-filled variant (use sparingly: one per header max).
  final bool emphasis;
}
