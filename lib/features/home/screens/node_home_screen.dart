import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/motion/ambient_clock.dart';
import 'package:marketplace_gig/core/theme/app_tokens.dart';
import 'package:marketplace_gig/core/theme/widgets/gigl_logo.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/app_header.dart';
import 'package:marketplace_gig/core/widgets/floating_dock.dart';
import 'package:marketplace_gig/features/home/data/node_data.dart';
import 'package:marketplace_gig/features/home/providers/node_home_provider.dart';
import 'package:marketplace_gig/features/home/widgets/hub_rings_painter.dart';
import 'package:marketplace_gig/features/home/widgets/node_painter.dart';
import 'package:marketplace_gig/features/home/widgets/radial_layout.dart';

class NodeHomeScreen extends ConsumerStatefulWidget {
  const NodeHomeScreen({super.key});

  @override
  ConsumerState<NodeHomeScreen> createState() => _NodeHomeScreenState();
}

class _NodeHomeScreenState extends ConsumerState<NodeHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _curve = Curves.easeOutCubic;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  )..addStatusListener(_onAnimationStatus);

  // Invariant: all four maps share the same key set.
  Map<String, Offset> _fromPos = {};
  Map<String, Offset> _toPos = {};
  Map<String, double> _fromAlpha = {};
  Map<String, double> _toAlpha = {};
  Rect _fromBounds = Rect.zero;
  Rect _toBounds = Rect.zero;

  Size _canvasSize = Size.zero;
  String? _pressedId;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(nodeHomeProvider);
    _toPos = computeRadialLayout(initial);
    _toAlpha = {for (final id in _toPos.keys) id: nodeEmphasis(id, initial)};
    _toBounds = layoutBounds(_toPos);
    _fromPos = Map.of(_toPos);
    _fromAlpha = Map.of(_toAlpha);
    _fromBounds = _toBounds;

    ref.listenManual<NodeHomeState>(
      nodeHomeProvider,
      (_, next) => _retarget(next),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  RadialFrame _currentFrame() {
    final t = _curve.transform(_controller.value);
    return RadialFrame(
      positions: {
        for (final id in _toPos.keys)
          id: Offset.lerp(_fromPos[id], _toPos[id], t)!,
      },
      opacity: {
        for (final id in _toAlpha.keys)
          id: _fromAlpha[id]! + (_toAlpha[id]! - _fromAlpha[id]!) * t,
      },
      bounds: Rect.lerp(_fromBounds, _toBounds, t)!,
      interactiveIds: {
        for (final e in _toAlpha.entries)
          if (e.value > 0) e.key,
      },
    );
  }

  /// Animates from whatever is on screen right now to [next]'s layout, so
  /// rapid taps retarget smoothly instead of jumping.
  void _retarget(NodeHomeState next) {
    final current = _currentFrame();
    final target = computeRadialLayout(next);

    // Entering nodes grow out of their parent; leaving ones shrink into it.
    Offset anchor(String id, Map<String, Offset> primary) {
      for (String? p = parentById[id]; p != null; p = parentById[p]) {
        final pos = primary[p] ?? target[p] ?? current.positions[p];
        if (pos != null) return pos;
      }
      return Offset.zero;
    }

    final ids = {
      ...target.keys,
      for (final id in current.positions.keys)
        if (current.opacity[id]! > 0.01) id,
    };

    setState(() {
      _fromPos = {
        for (final id in ids)
          id: current.positions[id] ?? anchor(id, current.positions),
      };
      _toPos = {for (final id in ids) id: target[id] ?? anchor(id, target)};
      _fromAlpha = {for (final id in ids) id: current.opacity[id] ?? 0};
      _toAlpha = {
        for (final id in ids)
          id: target.containsKey(id) ? nodeEmphasis(id, next) : 0,
      };
      _fromBounds = current.bounds;
      _toBounds = layoutBounds(target);
    });
    _controller.forward(from: 0);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final gone = [
      for (final e in _toAlpha.entries)
        if (e.value == 0) e.key,
    ];
    if (gone.isEmpty) return;
    setState(() {
      for (final id in gone) {
        _fromPos.remove(id);
        _toPos.remove(id);
        _fromAlpha.remove(id);
        _toAlpha.remove(id);
      }
    });
  }

  String? _hitTest(Offset local) {
    final frame = _currentFrame();
    final world = RadialCamera.fit(frame.bounds, _canvasSize).toWorld(local);
    String? hit;
    var best = double.infinity;
    for (final id in frame.interactiveIds) {
      final pos = frame.positions[id]!;
      final dist = (pos - world).distance;
      if (nodeHitTest(id, pos, world) && dist < best) {
        best = dist;
        hit = id;
      }
    }
    return hit;
  }

  void _activate(String id) {
    HapticFeedback.selectionClick();
    final route = ref.read(nodeHomeProvider.notifier).toggleNode(id);
    if (route != null && mounted) context.go(route);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _pressedId = null);
    final hit = _hitTest(details.localPosition);
    if (hit != null) {
      _activate(hit);
    } else {
      ref.read(nodeHomeProvider.notifier).back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeHomeProvider);
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    // Stable MotionRead: route/motion changes rebuild this widget, clock
    // ticks only repaint the ring painter (no rebuilds).
    final motion = AmbientClock.motionOf(context);

    return PopScope(
      canPop: state.breadcrumb.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(nodeHomeProvider.notifier).back();
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        // The focused-node readout lives in the floating dock (ONE dock
        // only); the canvas reserves dock clearance so the cluster centers
        // in the visible region between header and dock.
        body: AppBackdrop(
          variant: AppBackdropVariant.hub,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                // Hub glow centered on the cluster, fading to transparent so
                // the wash shows through at the edges.
                center: const Alignment(0.0, 0.1),
                radius: 0.9,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.6),
                  scheme.primaryContainer.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    leading: const GiglLogo(size: 28),
                    actions: [
                      AppHeaderAction(
                        icon: Icons.refresh,
                        tooltip: 'Reset',
                        onPressed: () =>
                            ref.read(nodeHomeProvider.notifier).reset(),
                      ),
                    ],
                  ),
                  _BreadcrumbBar(
                    breadcrumb: state.breadcrumb,
                    onCrumbTap: (id) =>
                        ref.read(nodeHomeProvider.notifier).collapseTo(id),
                  ),
                  Expanded(
                    // Dock clearance: cluster centers between header and dock.
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: FloatingDock.bottomPadding,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _canvasSize = constraints.biggest;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) => setState(
                              () => _pressedId = _hitTest(d.localPosition),
                            ),
                            onTapUp: _onTapUp,
                            onTapCancel: () =>
                                setState(() => _pressedId = null),
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final frame = _currentFrame();
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Ambient orbit rings behind the nodes:
                                    // decorative (IgnorePointer, no semantics),
                                    // own RepaintBoundary — the clock repaints
                                    // this layer without rebuilding the node
                                    // layer or any gesture.
                                    RepaintBoundary(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          size: _canvasSize,
                                          painter: HubRingsPainter(
                                            frame: frame,
                                            state: state,
                                            tokens: tokens,
                                            scheme: scheme,
                                            motion: motion,
                                          ),
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      size: _canvasSize,
                                      painter: NodePainter(
                                        frame: frame,
                                        state: state,
                                        labelColor: scheme.onSurface,
                                        pressedId: _pressedId,
                                        onNodeTap: _activate,
                                        tokens: tokens,
                                        scheme: scheme,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.breadcrumb, required this.onCrumbTap});

  final List<String> breadcrumb;
  final ValueChanged<String> onCrumbTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: breadcrumb.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 16, color: tokens.inkMuted),
        ),
        itemBuilder: (context, index) {
          final id = breadcrumb[index];
          final node = nodeById[id];
          final label = node?.label ?? id;
          final isLast = index == breadcrumb.length - 1;
          // The stray root "Gigl" chip under the wordmark is now a small
          // overline label (no container); tap still collapses to root.
          if (id == 'root') {
            return InkWell(
              onTap: () => onCrumbTap(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.inkMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            );
          }
          // Chip spec: selected = inverted-pill fill + label; unselected =
          // surface + 1px outline + inkMuted text.
          final highlighted = isLast;
          return InkWell(
            onTap: () => onCrumbTap(id),
            borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: highlighted
                    ? tokens.pillFill
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(GiglTokens.radiusPill),
                border: Border.all(
                  color: highlighted ? Colors.transparent : tokens.outline,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                  color: highlighted ? tokens.onPillFill : tokens.inkMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
