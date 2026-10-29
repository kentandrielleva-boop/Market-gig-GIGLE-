import 'package:flutter/material.dart';

/// Immutable data model for a radial node.
/// Mirrors the @freezed spec without requiring code generation.
@immutable
class NodeItem {
  const NodeItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
    required this.textColor,
    this.childIds = const [],
    this.isLeaf = false,
    this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;
  final Color color;
  final Color textColor;
  final List<String> childIds;
  final bool isLeaf;
  final String? route;

  NodeItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    String? description,
    Color? color,
    Color? textColor,
    List<String>? childIds,
    bool? isLeaf,
    String? route,
  }) {
    return NodeItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      childIds: childIds ?? this.childIds,
      isLeaf: isLeaf ?? this.isLeaf,
      route: route ?? this.route,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          icon == other.icon &&
          description == other.description &&
          color == other.color &&
          textColor == other.textColor &&
          isLeaf == other.isLeaf &&
          route == other.route;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    icon,
    description,
    color,
    textColor,
    isLeaf,
    route,
  );
}
