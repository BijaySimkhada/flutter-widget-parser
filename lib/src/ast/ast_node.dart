import '../errors/source_span.dart';

/// A single line in a debug tree, used by [AstNode.prettyPrint]. Kept
/// separate from the AST classes themselves so pretty-printing logic lives
/// in one place ([_renderTree]) instead of being reimplemented per node.
class DebugTreeNode {
  const DebugTreeNode(this.label, [this.children = const <DebugTreeNode>[]]);

  final String label;
  final List<DebugTreeNode> children;
}

/// Base class for every node produced by [DynamicParser].
///
/// AST nodes are immutable and carry a [span] pointing back into the
/// original source, so later phases (validation, resolution, widget
/// building) can report precise errors.
abstract class AstNode {
  const AstNode({required this.span});

  final SourceSpan span;

  /// Total number of nodes in this subtree, including this node. Used to
  /// enforce `maxWidgetCount`/complexity limits without a separate walk.
  int get nodeCount;

  /// Structural depth of this subtree (1 for a leaf). Used to enforce
  /// `maxAstDepth`.
  int get depth;

  DebugTreeNode toDebugTree();

  /// Renders this subtree as an indented ASCII tree, e.g.:
  /// ```
  /// Column
  ///  ├── mainAxisAlignment: center
  ///  └── Text
  ///       └── text: "Hello"
  /// ```
  String prettyPrint() => _renderTree(toDebugTree(), '', true);

  static String _renderTree(DebugTreeNode node, String prefix, bool isRoot) {
    final StringBuffer buffer = StringBuffer();
    if (isRoot) {
      buffer.writeln(node.label);
    }
    for (int i = 0; i < node.children.length; i++) {
      final bool isLast = i == node.children.length - 1;
      final DebugTreeNode child = node.children[i];
      buffer.writeln('$prefix ${isLast ? '└──' : '├──'} ${child.label}');
      final String childPrefix = '$prefix ${isLast ? '   ' : '│  '}';
      for (int j = 0; j < child.children.length; j++) {
        final bool childIsLast = j == child.children.length - 1;
        final DebugTreeNode grandchild = child.children[j];
        buffer.write(_renderNested(grandchild, childPrefix, childIsLast));
      }
    }
    return buffer.toString().trimRight();
  }

  static String _renderNested(DebugTreeNode node, String prefix, bool isLast) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('$prefix ${isLast ? '└──' : '├──'} ${node.label}');
    final String childPrefix = '$prefix ${isLast ? '   ' : '│  '}';
    for (int i = 0; i < node.children.length; i++) {
      buffer.write(_renderNested(
          node.children[i], childPrefix, i == node.children.length - 1));
    }
    return buffer.toString();
  }
}
