import 'ast_node.dart';

/// Base class for every node that can appear in "value position" — i.e.
/// anywhere a property value, list item, map key/value, or positional
/// argument can appear. This includes literals, collections, identifier
/// paths (`Colors.blue`), and widget/constructor call nodes.
///
/// [ExpressionNode] (see `expression_node.dart`) also extends this, so a
/// `$user.name` expression is valid anywhere a plain value is.
abstract class ValueNode extends AstNode {
  const ValueNode({required super.span});
}

class NullValueNode extends ValueNode {
  const NullValueNode({required super.span});

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => const DebugTreeNode('null');
}

class BoolValueNode extends ValueNode {
  const BoolValueNode(this.value, {required super.span});

  final bool value;

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode('$value');
}

class IntValueNode extends ValueNode {
  const IntValueNode(this.value, {required super.span});

  final int value;

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode('$value');
}

class DoubleValueNode extends ValueNode {
  const DoubleValueNode(this.value, {required super.span});

  final double value;

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode('$value');
}

/// A plain string literal with no interpolation.
class StringValueNode extends ValueNode {
  const StringValueNode(this.value, {required super.span});

  final String value;

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode('"$value"');
}

/// A string literal containing `$name` / `${expr}` interpolation holes.
/// Each part is either a [String] (literal text) or a [ValueNode]
/// (typically an `ExpressionNode`, produced by re-parsing the interpolated
/// source as an expression).
class StringInterpolationValueNode extends ValueNode {
  const StringInterpolationValueNode(this.parts, {required super.span});

  final List<Object /* String | ValueNode */ > parts;

  @override
  int get nodeCount =>
      1 +
      parts
          .whereType<ValueNode>()
          .fold<int>(0, (int sum, ValueNode n) => sum + n.nodeCount);

  @override
  int get depth =>
      1 +
      parts.whereType<ValueNode>().fold<int>(
          0, (int max, ValueNode n) => n.depth > max ? n.depth : max);

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(
        '"${parts.map((Object p) => p is String ? p : '\${${(p as ValueNode).toDebugTree().label}}').join()}"',
      );
}

class ListValueNode extends ValueNode {
  const ListValueNode(this.items, {required super.span});

  final List<ValueNode> items;

  @override
  int get nodeCount =>
      1 + items.fold<int>(0, (int sum, ValueNode n) => sum + n.nodeCount);

  @override
  int get depth =>
      1 +
      items.fold<int>(
          0, (int max, ValueNode n) => n.depth > max ? n.depth : max);

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(
      '[list, ${items.length} item(s)]',
      items.map((ValueNode n) => n.toDebugTree()).toList());
}

class MapEntryNode extends AstNode {
  const MapEntryNode(
      {required this.key, required this.value, required super.span});

  final ValueNode key;
  final ValueNode value;

  @override
  int get nodeCount => 1 + key.nodeCount + value.nodeCount;

  @override
  int get depth => 1 + (key.depth > value.depth ? key.depth : value.depth);

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(
      '${key.toDebugTree().label}: ${value.toDebugTree().label}',
      value.toDebugTree().children);
}

class MapValueNode extends ValueNode {
  const MapValueNode(this.entries, {required super.span});

  final List<MapEntryNode> entries;

  @override
  int get nodeCount =>
      1 + entries.fold<int>(0, (int sum, MapEntryNode e) => sum + e.nodeCount);

  @override
  int get depth =>
      1 +
      entries.fold<int>(
          0, (int max, MapEntryNode e) => e.depth > max ? e.depth : max);

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(
      '{map, ${entries.length} entrie(s)}',
      entries.map((MapEntryNode e) => e.toDebugTree()).toList());
}

/// A dotted identifier path with no call, e.g. `Colors.blue`,
/// `MainAxisAlignment.center`, or a bare registered constant like
/// `AppColors.primary`. Resolved later against the enum/color/value
/// registries — the parser itself does not know what these names mean.
class IdentifierPathValueNode extends ValueNode {
  const IdentifierPathValueNode(this.path, {required super.span});

  final List<String> path;

  String get joined => path.join('.');

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(joined);
}
