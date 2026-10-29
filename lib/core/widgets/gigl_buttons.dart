import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';

/// The single most important CTA on a content screen: charcoal ink pill
/// ([GiglTokens.pillFill] — inverted to near-white fill + near-black label
/// in dark mode), pill shape. At most ONE per screen.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final style = FilledButton.styleFrom(
      backgroundColor: tokens.pillFill,
      foregroundColor: tokens.onPillFill,
      textStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
      ),
      minimumSize: const Size.fromHeight(48),
      elevation: 0,
      side: tokens.brightness == Brightness.dark
          ? BorderSide(color: tokens.outline, width: 1)
          : BorderSide.none,
      // Defined states: pressed gets an onPill veil, disabled falls back to
      // tonal outline/muted (the FilledButton defaults would assume primary).
      overlayColor: tokens.onPillFill.withValues(alpha: 0.12),
      disabledBackgroundColor: tokens.outline.withValues(alpha: 0.4),
      disabledForegroundColor: tokens.inkMuted,
    );
    final child = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: tokens.onPillFill,
            ),
          )
        : (icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                )
              : Text(label));
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

/// Filter chip: UNSELECTED = surface + 1px outline + ink 600 text; SELECTED
/// = inverted-pill fill + label. Optional count badge circle.
class GiglChoiceChip extends StatelessWidget {
  const GiglChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? tokens.pillFill : scheme.surface;
    final fg = selected ? tokens.onPillFill : tokens.ink;
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
          border: selected && tokens.brightness == Brightness.light
              ? null
              : Border.all(color: tokens.outline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: fg),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg.withValues(alpha: 0.2),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 44dp circular icon button (tap target >= 44dp).
/// Emphasis: ink fill + onInk icon. Neutral: surface fill + 1px outline + e1.
class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.emphasis = false,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool emphasis;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final fill = emphasis ? tokens.dockSurface : scheme.surface;
    final iconColor = emphasis ? tokens.onInk : scheme.onSurfaceVariant;
    final button = SizedBox(
      width: GiglTokens.iconButtonSize,
      height: GiglTokens.iconButtonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: emphasis && tokens.brightness == Brightness.light
              ? null
              : Border.all(color: scheme.outline, width: 1),
          boxShadow: emphasis ? null : tokens.shadowE1,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
