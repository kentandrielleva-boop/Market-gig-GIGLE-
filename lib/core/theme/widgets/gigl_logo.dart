import 'package:flutter/material.dart';

/// Gigl brand mark backed by the externally designed `assets/logo/gigl.png`.
///
/// Falls back to the radial-hub glyph when the asset is missing so splash,
/// top bar, and info bar never render empty.
class GiglLogo extends StatelessWidget {
  const GiglLogo({super.key, this.size = 32, this.semanticLabel = 'Gigl logo'});

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/gigl.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      errorBuilder: (context, _, _) => Icon(
        Icons.hub_outlined,
        size: size,
        color: Theme.of(context).colorScheme.primary,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
