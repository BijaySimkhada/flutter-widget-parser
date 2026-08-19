import 'ast_node.dart';
import 'value_node.dart';

/// Binary operators supported by the safe expression language. Deliberately
/// closed — there is no way to add operators from within a source string.
enum BinaryOperator {
  equal('=='),
  notEqual('!='),
  greater('>'),
  less('<'),
  greaterEqual('>='),
  lessEqual('<='),
  and('&&'),
  or('||'),
  nullCoalesce('??'),
  add('+'),
  subtract('-'),
  multiply('*'),
  divide('/');

  const BinaryOperator(this.symbol);
  final String symbol;
}

enum UnaryOperator {
  not('!'),
  negate('-');

  const UnaryOperator(this.symbol);
  final String symbol;
}

/// Base class for the safe, sandboxed expression language used for
/// `$variable.path`, comparisons, boolean logic, arithmetic, and ternary
/// conditionals. Expressions are values, so an [ExpressionNode] can appear
/// anywhere a [ValueNode] can — as a property value, list item, etc.
///
/// This is *not* a general-purpose interpreter: there is no way to call
/// arbitrary functions, instantiate objects, or reach anything the host
/// application did not explicitly expose via `DynamicDataContext`.
abstract class ExpressionNode extends ValueNode {
  const ExpressionNode({required super.span});

  /// Short human-readable rendering, e.g. `$user.name`, `(a && b)`.
  String describe();

  @override
  DebugTreeNode toDebugTree() => DebugTreeNode(describe());
}

/// `$user.profile.name` -> path = ['user', 'profile', 'name'].
class VariablePathExpressionNode extends ExpressionNode {
  const VariablePathExpressionNode(this.path, {required super.span});

  final List<String> path;

  @override
  int get nodeCount => 1;

  @override
  int get depth => 1;

  @override
  String describe() => '\$${path.join('.')}';
}

/// Wraps a plain literal (number/string/bool/null) so it can participate in
/// expression grammar, e.g. the `18` in `$user.age >= 18`.
class LiteralExpressionNode extends ExpressionNode {
  const LiteralExpressionNode(this.literal, {required super.span});

  final ValueNode literal;

  @override
  int get nodeCount => 1 + literal.nodeCount;

  @override
  int get depth => 1 + literal.depth;

  @override
  String describe() => literal.toDebugTree().label;
}

class UnaryExpressionNode extends ExpressionNode {
  const UnaryExpressionNode(
      {required this.operator, required this.operand, required super.span});

  final UnaryOperator operator;
  final ExpressionNode operand;

  @override
  int get nodeCount => 1 + operand.nodeCount;

  @override
  int get depth => 1 + operand.depth;

  @override
  String describe() => '${operator.symbol}${operand.describe()}';
}

class BinaryExpressionNode extends ExpressionNode {
  const BinaryExpressionNode({
    required this.operator,
    required this.left,
    required this.right,
    required super.span,
  });

  final BinaryOperator operator;
  final ExpressionNode left;
  final ExpressionNode right;

  @override
  int get nodeCount => 1 + left.nodeCount + right.nodeCount;

  @override
  int get depth {
    final int l = left.depth, r = right.depth;
    return 1 + (l > r ? l : r);
  }

  @override
  String describe() =>
      '(${left.describe()} ${operator.symbol} ${right.describe()})';
}

class ConditionalExpressionNode extends ExpressionNode {
  const ConditionalExpressionNode({
    required this.condition,
    required this.whenTrue,
    required this.whenFalse,
    required super.span,
  });

  final ExpressionNode condition;
  final ExpressionNode whenTrue;
  final ExpressionNode whenFalse;

  @override
  int get nodeCount =>
      1 + condition.nodeCount + whenTrue.nodeCount + whenFalse.nodeCount;

  @override
  int get depth {
    final int max = <int>[condition.depth, whenTrue.depth, whenFalse.depth]
        .reduce((int a, int b) => a > b ? a : b);
    return 1 + max;
  }

  @override
  String describe() =>
      '(${condition.describe()} ? ${whenTrue.describe()} : ${whenFalse.describe()})';
}
