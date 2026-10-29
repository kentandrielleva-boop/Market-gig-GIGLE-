import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/domain/models/models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.animate = true,
    this.statusLabel,
  });

  final Message message;
  final bool animate;

  /// Small caption under the bubble (e.g. "Seen" on the latest outgoing one).
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alignment = message.isOutgoing
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isOutgoing ? scheme.primaryContainer : scheme.surface;
    final textColor = message.isOutgoing
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(GiglTokens.radiusMd),
          topRight: const Radius.circular(GiglTokens.radiusMd),
          bottomLeft: Radius.circular(
            message.isOutgoing ? GiglTokens.radiusMd : 4,
          ),
          bottomRight: Radius.circular(
            message.isOutgoing ? 4 : GiglTokens.radiusMd,
          ),
        ),
        border: message.isOutgoing
            ? null
            : Border.all(color: scheme.outlineVariant),
      ),
      child: Text(message.text, style: TextStyle(color: textColor)),
    );

    Widget child = Align(alignment: alignment, child: bubble);
    if (statusLabel != null) {
      child = Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          child,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              statusLabel!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    if (animate) {
      child = AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 200),
        child: child,
      );
    }

    return child;
  }
}
