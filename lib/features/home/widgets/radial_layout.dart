import 'dart:math' as math;
import 'dart:ui';

import 'package:marketplace_gig/features/home/data/node_data.dart';
import 'package:marketplace_gig/features/home/providers/node_home_provider.dart';

const double kRootNodeRadius = 48;
const double kMainNodeRadius = 36;
const double kLeafNodeRadius = 26;

/// Reserved room around a leaf for the label drawn beneath it.
const double kLeafLabelHeight = 18;
const double kLeafLabelMaxWidth = 72;

// Orbits scaled ~1.15x so the cluster fills the canvas and empty space
// reads as intentional. Sizing stays relative (LayoutBuilder/MediaQuery via
// RadialCamera.fit) — no fixed pixel layouts.
const double _mainOrbit = 138;
const double _leafOrbit = 115;
const double _leafFan = math.pi * 2 / 3;
const double _dimmedOpacity = 0.4;

double nodeRadius(String id) {
  if (id == 'root') return kRootNodeRadius;
  return (nodeById[id]?.isLeaf ?? false) ? kLeafNodeRadius : kMainNodeRadius;
}

/// World-space positions of every visible node, with the root at the origin.
/// Leaves fan outward, away from the root.
Map<String, Offset> computeRadialLayout(NodeHomeState state) {
  final positions = <String, Offset>{'root': Offset.zero};
  if (!state.expandedIds.contains('root')) return positions;

  final mains = nodeById['root']!.childIds;
  for (var i = 0; i < mains.length; i++) {
    final angle = -math.pi / 2 + 2 * math.pi * i / mains.length;
    final mainPos = Offset.fromDirection(angle, _mainOrbit);
    positions[mains[i]] = mainPos;
    if (!state.expandedIds.contains(mains[i])) continue;

    final leaves = nodeById[mains[i]]!.childIds;
    for (var j = 0; j < leaves.length; j++) {
      final leafAngle = leaves.length == 1
          ? angle
          : angle - _leafFan / 2 + _leafFan * j / (leaves.length - 1);
      positions[leaves[j]] =
          mainPos + Offset.fromDirection(leafAngle, _leafOrbit);
    }
  }
  return positions;
}

/// Tap target: the circle with some slack, plus the label beneath a leaf.
bool nodeHitTest(String id, Offset pos, Offset point) {
  final r = nodeRadius(id);
  if ((point - pos).distance <= r + 8) return true;
  if (!(nodeById[id]?.isLeaf ?? false)) return false;
  return Rect.fromLTWH(
    pos.dx - kLeafLabelMaxWidth / 2,
    pos.dy,
    kLeafLabelMaxWidth,
    r + kLeafLabelHeight + 4,
  ).contains(point);
}

/// Target opacity for a visible node: siblings of the expanded branch are dimmed.
double nodeEmphasis(String id, NodeHomeState state) {
  final parent = parentById[id];
  if (parent == null || !state.expandedIds.contains(parent)) return 1;
  final expandedSibling = nodeById[parent]!.childIds.any(
    (sib) => sib != id && state.expandedIds.contains(sib),
  );
  return expandedSibling ? _dimmedOpacity : 1;
}

Rect layoutBounds(Map<String, Offset> positions) {
  Rect? bounds;
  for (final MapEntry(key: id, value: p) in positions.entries) {
    final r = nodeRadius(id);
    final isLeaf = nodeById[id]?.isLeaf ?? false;
    final halfWidth = isLeaf ? math.max(r, kLeafLabelMaxWidth / 2) : r;
    final rect = Rect.fromLTRB(
      p.dx - halfWidth,
      p.dy - r,
      p.dx + halfWidth,
      p.dy + r + (isLeaf ? kLeafLabelHeight : 0),
    );
    bounds = bounds?.expandToInclude(rect) ?? rect;
  }
  return bounds ?? Rect.zero;
}

/// Maps world space to canvas space so the given bounds fit (never zooming in).
class RadialCamera {
  const RadialCamera(this.scale, this.offset);

  factory RadialCamera.fit(Rect bounds, Size size, {double padding = 16}) {
    final availW = size.width - padding * 2;
    final availH = size.height - padding * 2;
    final scale = (bounds.isEmpty || availW <= 0 || availH <= 0)
        ? 1.0
        : math.min(
            1.0,
            math.min(availW / bounds.width, availH / bounds.height),
          );
    return RadialCamera(
      scale,
      size.center(Offset.zero) - bounds.center * scale,
    );
  }

  final double scale;
  final Offset offset;

  Offset toScreen(Offset world) => world * scale + offset;
  Offset toWorld(Offset screen) => (screen - offset) / scale;
}

/// A snapshot of what's on screen: where each node is and how opaque it is.
class RadialFrame {
  const RadialFrame({
    required this.positions,
    required this.opacity,
    required this.bounds,
    required this.interactiveIds,
  });

  final Map<String, Offset> positions;
  final Map<String, double> opacity;
  final Rect bounds;

  /// Nodes that belong to the current state (excludes ones animating out).
  final Set<String> interactiveIds;
}
