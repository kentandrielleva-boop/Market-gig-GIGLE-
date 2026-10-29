import 'dart:io';

import 'package:flutter/material.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: paths.length + 1,
      itemBuilder: (context, index) {
        if (index == paths.length) {
          return InkWell(
            onTap: paths.length >= 5 ? null : onAdd,
            borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(GiglTokens.radiusSm),
              child: Image.file(
                File(paths[index]),
                fit: BoxFit.cover,
                cacheWidth: 480,
                cacheHeight: 480,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.54),
                child: InkWell(
                  onTap: () => onRemove(index),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.lightOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
