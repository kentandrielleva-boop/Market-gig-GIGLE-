import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/features/home/data/node_data.dart';
import 'package:marketplace_gig/features/home/models/node_item.dart';
import 'package:marketplace_gig/features/home/providers/node_home_provider.dart';
import 'package:marketplace_gig/features/home/widgets/radial_layout.dart';

class NodePainter extends CustomPainter {
  NodePainter({
    required this.frame,
    required this.state,
    required this.labelColor,
    required this.onNodeTap,
    required this.tokens,
    required this.scheme,
    this.pressedId,
  });

  final RadialFrame frame;
  final NodeHomeState state;
  final Color labelColor;
  final ValueChanged<String> onNodeTap;
  final GiglTokens tokens;
  final ColorScheme scheme;
  final String? pressedId;

  static final Map<String, _Glyphs> _glyphCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final camera = RadialCamera.fit(frame.bounds, size);
    canvas
      ..save()
      ..translate(camera.offset.dx, camera.offset.dy)
      ..scale(camera.scale);

    // NOTE: the orbit rings (dashed + outer) are painted by the dedicated
    // [HubRingsPainter] layer BEHIND this one — ambient motion lives there,
    // while nodes/connectors/labels stay static and interactive.
    _paintConnectors(canvas);
    // allNodes is ordered root → mains → leaves, so deeper nodes draw on top.
    for (final node in allNodes) {
      final pos = frame.positions[node.id];
      final opacity = frame.opacity[node.id] ?? 0;
      if (pos == null || opacity <= 0.01) continue;
      _paintNode(canvas, node, pos, opacity);
    }

    canvas.restore();
  }

  void _paintConnectors(Canvas canvas) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final MapEntry(key: id, value: pos) in frame.positions.entries) {
      final parentPos = frame.positions[parentById[id]];
      if (parentPos == null) continue;
      final opacity = math.min(
        frame.opacity[id] ?? 0,
        frame.opacity[parentById[id]] ?? 0,
      );
      if (opacity <= 0.01) continue;
      final hue = tokens.categoryFor(id).base;
      paint.color = hue.withValues(alpha: 0.45 * opacity);
      canvas.drawLine(parentPos, pos, paint);
    }
  }

  void _paintNode(Canvas canvas, NodeItem node, Offset pos, double opacity) {
    final radius = nodeRadius(node.id) * (pressedId == node.id ? 0.9 : 1);
    final faded = opacity < 0.99;
    if (faded) {
      canvas.saveLayer(
        Rect.fromCircle(
          center: pos,
          radius: radius + kLeafLabelMaxWidth / 2 + 8,
        ),
        Paint()..color = scheme.scrim.withValues(alpha: opacity),
      );
    }

    if (node.id == 'root') {
      _paintHub(canvas, node, pos, radius);
    } else {
      _paintCategoryNode(canvas, node, pos, radius);
    }

    final glyphs = _glyphsFor(node);
    if (node.isLeaf) {
      glyphs.icon.paint(
        canvas,
        pos - Offset(glyphs.icon.width / 2, glyphs.icon.height / 2),
      );
      glyphs.label.paint(
        canvas,
        Offset(pos.dx - glyphs.label.width / 2, pos.dy + radius + 3),
      );
    } else {
      const gap = 1.0;
      final top = pos.dy - (glyphs.icon.height + gap + glyphs.label.height) / 2;
      glyphs.icon.paint(canvas, Offset(pos.dx - glyphs.icon.width / 2, top));
      glyphs.label.paint(
        canvas,
        Offset(pos.dx - glyphs.label.width / 2, top + glyphs.icon.height + gap),
      );
    }

    if (faded) canvas.restore();
  }

  /// Center hub 96dp: category-independent brand gradient, 3dp surface ring
  /// for separation, and a soft primary glow so it anchors the cluster.
  void _paintHub(Canvas canvas, NodeItem node, Offset pos, double radius) {
    // Soft glow.
    canvas.drawCircle(
      pos,
      radius + 10,
      Paint()
        ..color = tokens.hubGradientStart.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Tinted drop shadow (never pure black).
    canvas.drawCircle(
      pos + const Offset(0, 3),
      radius,
      Paint()
        ..color = tokens.hubGradientEnd.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Gradient fill.
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..shader = tokens.hubGradient.createShader(
          Rect.fromCircle(center: pos, radius: radius),
        ),
    );
    // 3dp light ring.
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = scheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  /// Category nodes: gradient fill at equal tonal weight, 3dp surface ring,
  /// halo (category @ 16%, 10dp spread), and a tinted e1 shadow.
  void _paintCategoryNode(
    Canvas canvas,
    NodeItem node,
    Offset pos,
    double radius,
  ) {
    final cat = tokens.categoryFor(node.id);
    // Halo: category color @ 16% alpha, 10dp spread.
    canvas.drawCircle(
      pos,
      radius + 10,
      Paint()..color = cat.base.withValues(alpha: 0.16),
    );
    // Tinted shadow.
    canvas.drawCircle(
      pos + const Offset(0, 2),
      radius,
      Paint()
        ..color = cat.base.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Gradient fill.
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..shader = cat.gradient.createShader(
          Rect.fromCircle(center: pos, radius: radius),
        ),
    );
    // 3dp surface ring.
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = scheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (!node.isLeaf &&
        node.id != 'root' &&
        state.expandedIds.contains(node.id)) {
      _drawDashedCircle(
        canvas,
        pos,
        radius + 7,
        Paint()
          ..color = cat.base
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  _Glyphs _glyphsFor(NodeItem node) {
    // Inside-node glyphs use onPrimary so dark-mode light hues keep >= 4.5:1
    // (white on #9B7BFF etc. fails; #12082E on them passes).
    final inside = scheme.onPrimary;
    final key =
        '${node.id}|${labelColor.toARGB32()}|${inside.toARGB32()}|${tokens.brightness.name}';
    return _glyphCache[key] ??= _Glyphs.build(
      node,
      leafLabelColor: labelColor,
      insideColor: inside,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dash = 4.0;
    const gap = 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    final sweep = dash / radius;
    final step = 2 * math.pi / count;
    final path = Path();
    for (var i = 0; i < count; i++) {
      path.addArc(rect, i * step, sweep);
    }
    canvas.drawPath(path, paint);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final camera = RadialCamera.fit(frame.bounds, size);
    return [
      for (final node in allNodes)
        if (frame.interactiveIds.contains(node.id))
          CustomPainterSemantics(
            key: ValueKey<String>(node.id),
            rect: Rect.fromCircle(
              center: camera.toScreen(frame.positions[node.id]!),
              radius: nodeRadius(node.id) * camera.scale,
            ),
            properties: SemanticsProperties(
              label: node.label,
              hint: node.description,
              button: true,
              expanded: node.isLeaf
                  ? null
                  : state.expandedIds.contains(node.id),
              textDirection: TextDirection.ltr,
              onTap: () => onNodeTap(node.id),
            ),
          ),
    ];
  };

  @override
  bool shouldRebuildSemantics(covariant NodePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.frame.bounds != frame.bounds;

  @override
  bool shouldRepaint(covariant NodePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.state != state ||
      oldDelegate.pressedId != pressedId ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.tokens != tokens ||
      oldDelegate.scheme != scheme;
}

class _Glyphs {
  _Glyphs(this.icon, this.label);

  factory _Glyphs.build(
    NodeItem node, {
    required Color leafLabelColor,
    required Color insideColor,
  }) {
    final isRoot = node.id == 'root';
    // Labels inside the filled nodes: white 600 / 12sp per spec.
    const fontSize = 12.0;
    final iconSize = isRoot ? 26.0 : 22.0;
    final labelWidth = node.isLeaf
        ? kLeafLabelMaxWidth
        : nodeRadius(node.id) * 2 - 6;

    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(node.icon.codePoint),
        style: TextStyle(
          fontFamily: node.icon.fontFamily,
          package: node.icon.fontPackage,
          fontSize: iconSize,
          color: insideColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final label = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: node.isLeaf ? leafLabelColor : insideColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: labelWidth);

    return _Glyphs(icon, label);
  }

  final TextPainter icon;
  final TextPainter label;
}
