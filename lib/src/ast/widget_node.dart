import 'ast_node.dart';
import 'property_node.dart';
import 'value_node.dart';

/// A generic "call" node: `Name(...)` or `Name.constructorName(...)`.
///
/// This single node type represents *both* widget construction
/// (`Container(...)`) and value-constructor construction
/// (`EdgeInsets.all(16)`, `Color(0xFF...)`, `action("login")`). The parser
/// has no notion of "this identifier is a widget" — that's a semantic
/// question answered later by [DynamicWidgetRegistry] during resolution,
/// which keeps the grammar layer completely decoupled from Flutter.
class WidgetNode extends ValueNode {
  const WidgetNode({
    required this.name,
    this.constructorName,
    this.positionalArguments = const <ValueNode>[],
    this.properties = const <PropertyNode>[],
    required super.span,
  });

  /// The base identifier, e.g. `Container`, `EdgeInsets`, `action`.
  final String name;

  /// The named-constructor suffix, e.g. `all` in `EdgeInsets.all(...)`, or
  /// `network` in `Image.network(...)`. Null for the default constructor.
  final String? constructorName;

  final List<ValueNode> positionalArguments;
  final List<PropertyNode> properties;

  /// `Container` or `EdgeInsets.all` — the full registry lookup key.
  String get fullName =>
      constructorName == null ? name : '$name.$constructorName';

  PropertyNode? property(String propertyName) {
    for (final PropertyNode p in properties) {
      if (p.name == propertyName) return p;
    }
    return null;
  }

  @override
  int get nodeCount =>
      1 +
      positionalArguments.fold<int>(
          0, (int sum, ValueNode n) => sum + n.nodeCount) +
      properties.fold<int>(0, (int sum, PropertyNode n) => sum + n.nodeCount);

  @override
  int get depth {
    int maxChild = 0;
    for (final ValueNode n in positionalArguments) {
      if (n.depth > maxChild) maxChild = n.depth;
    }
    for (final PropertyNode n in properties) {
      if (n.depth > maxChild) maxChild = n.depth;
    }
    return 1 + maxChild;
  }

  @override
  DebugTreeNode toDebugTree() {
    final List<DebugTreeNode> children = <DebugTreeNode>[];
    for (int i = 0; i < positionalArguments.length; i++) {
      final DebugTreeNode argTree = positionalArguments[i].toDebugTree();
      children.add(
        argTree.children.isEmpty
            ? DebugTreeNode('#$i: ${argTree.label}')
            : DebugTreeNode('#$i', argTree.children),
      );
    }
    for (final PropertyNode p in properties) {
      if (p.name == 'child' && p.value is WidgetNode) {
        children.add(p.value.toDebugTree());
      } else if (p.name == 'children' && p.value is ListValueNode) {
        for (final ValueNode item in (p.value as ListValueNode).items) {
          children.add(item.toDebugTree());
        }
      } else {
        children.add(p.toDebugTree());
      }
    }
    return DebugTreeNode(fullName, children);
  }
}
