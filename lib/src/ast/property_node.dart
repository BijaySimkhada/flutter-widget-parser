import 'ast_node.dart';
import 'value_node.dart';

/// A single named argument, e.g. `padding: EdgeInsets.all(16)`.
class PropertyNode extends AstNode {
  const PropertyNode(
      {required this.name, required this.value, required super.span});

  final String name;
  final ValueNode value;

  @override
  int get nodeCount => 1 + value.nodeCount;

  @override
  int get depth => 1 + value.depth;

  @override
  DebugTreeNode toDebugTree() {
    final DebugTreeNode valueTree = value.toDebugTree();
    if (valueTree.children.isEmpty) {
      // Leaf value: show inline, e.g. `mainAxisAlignment: center`.
      return DebugTreeNode('$name: ${valueTree.label}');
    }
    // Structured value (constructor call, list, map): show the property
    // name as the node and nest the value's own structure underneath,
    // e.g. `style` -> `fontSize: 20` / `fontWeight: bold`.
    return DebugTreeNode(name, valueTree.children);
  }
}
