import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_gig/features/home/data/node_data.dart';

/// Immutable state for the node home screen.
/// Mirrors the @freezed spec without code generation.
class NodeHomeState {
  const NodeHomeState({
    required this.expandedIds,
    required this.focusedId,
    required this.breadcrumb,
  });

  final Set<String> expandedIds;
  final String focusedId;
  final List<String> breadcrumb;

  NodeHomeState copyWith({
    Set<String>? expandedIds,
    String? focusedId,
    List<String>? breadcrumb,
  }) {
    return NodeHomeState(
      expandedIds: expandedIds ?? this.expandedIds,
      focusedId: focusedId ?? this.focusedId,
      breadcrumb: breadcrumb ?? this.breadcrumb,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeHomeState &&
          runtimeType == other.runtimeType &&
          focusedId == other.focusedId &&
          expandedIds.length == other.expandedIds.length &&
          expandedIds.containsAll(other.expandedIds) &&
          breadcrumb.length == other.breadcrumb.length &&
          _listEquals(breadcrumb, other.breadcrumb);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(expandedIds),
    focusedId,
    Object.hashAll(breadcrumb),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class NodeHomeNotifier extends StateNotifier<NodeHomeState> {
  NodeHomeNotifier()
    : super(
        const NodeHomeState(
          expandedIds: {'root'},
          focusedId: 'root',
          breadcrumb: ['root'],
        ),
      );

  /// Toggles the node with [id].
  /// Returns the route to navigate to if the node is a leaf, otherwise null.
  String? toggleNode(String id) {
    final node = nodeById[id];
    if (node == null) return null;

    if (node.isLeaf) {
      if (node.route != null) {
        state = state.copyWith(focusedId: id);
      }
      return node.route;
    }

    if (state.expandedIds.contains(id)) {
      collapse(id);
    } else {
      // Expand: collapse all siblings first
      final siblings = _siblingsOf(id);
      final newExpanded = Set<String>.from(state.expandedIds);
      for (final sib in siblings) {
        if (sib != id) {
          _collapseRecursive(sib, newExpanded);
        }
      }
      newExpanded.add(id);
      final newBreadcrumb = _buildBreadcrumb(newExpanded, id);
      state = NodeHomeState(
        expandedIds: newExpanded,
        focusedId: id,
        breadcrumb: newBreadcrumb,
      );
    }
    return null;
  }

  void collapse(String id) {
    final newExpanded = Set<String>.from(state.expandedIds);
    _collapseRecursive(id, newExpanded);
    // Don't collapse root entirely – keep at least root
    if (id == 'root') {
      newExpanded.add('root');
      state = const NodeHomeState(
        expandedIds: {'root'},
        focusedId: 'root',
        breadcrumb: ['root'],
      );
      return;
    }
    // Focus should go to parent or root
    final parentId = _parentOf(id);
    final newFocused = parentId ?? 'root';
    final newBreadcrumb = _buildBreadcrumb(newExpanded, newFocused);
    state = NodeHomeState(
      expandedIds: newExpanded,
      focusedId: newFocused,
      breadcrumb: newBreadcrumb,
    );
  }

  void reset() {
    state = const NodeHomeState(
      expandedIds: {'root'},
      focusedId: 'root',
      breadcrumb: ['root'],
    );
  }

  /// Collapse to a specific breadcrumb id – collapses everything deeper.
  void collapseTo(String id) {
    if (id == 'root') {
      reset();
      return;
    }
    final newExpanded = <String>{'root', id};
    // Keep the chain to id
    final chain = _chainToRoot(id);
    newExpanded.addAll(chain);
    state = NodeHomeState(
      expandedIds: newExpanded,
      focusedId: id,
      breadcrumb: chain,
    );
  }

  /// Steps up one level. Returns false when already at the root.
  bool back() {
    if (state.breadcrumb.length <= 1) return false;
    collapse(state.breadcrumb.last);
    return true;
  }

  void _collapseRecursive(String id, Set<String> set) {
    set.remove(id);
    final node = nodeById[id];
    if (node == null) return;
    for (final childId in node.childIds) {
      if (set.contains(childId)) {
        _collapseRecursive(childId, set);
      }
    }
  }

  List<String> _siblingsOf(String id) {
    final parent = parentById[id];
    return parent == null ? const [] : nodeById[parent]!.childIds;
  }

  String? _parentOf(String id) => parentById[id];

  List<String> _chainToRoot(String id) {
    final chain = <String>[];
    String? current = id;
    while (current != null) {
      chain.insert(0, current);
      current = _parentOf(current);
    }
    if (chain.isEmpty || chain.first != 'root') {
      if (!chain.contains('root')) chain.insert(0, 'root');
    }
    return chain;
  }

  List<String> _buildBreadcrumb(Set<String> expanded, String focused) {
    if (focused == 'root') return ['root'];
    final chain = _chainToRoot(focused);
    // Ensure all ancestors are in expanded; if not, fallback to root-only
    return chain;
  }
}

final nodeHomeProvider = StateNotifierProvider<NodeHomeNotifier, NodeHomeState>(
  (ref) {
    return NodeHomeNotifier();
  },
);
