import '../ast/expression_node.dart';
import '../ast/value_node.dart';
import '../errors/dynamic_parser_exception.dart';
import '../errors/source_span.dart';
import 'dynamic_data_context.dart';

/// Evaluates a parsed [ExpressionNode] against a [DynamicDataContext].
///
/// This is a small, total, deterministic tree-walking interpreter over a
/// *closed* set of node types produced only by [DynamicParser] — there is
/// no code path that runs anything other than the operators enumerated in
/// [BinaryOperator]/[UnaryOperator]. It never calls into `dart:mirrors`,
/// never performs I/O, and never touches anything not explicitly present
/// in the supplied [DynamicDataContext].
///
/// Missing variables resolve to `null` rather than throwing, so
/// `$user.nickname ?? "Guest"` behaves predictably even for partial data —
/// but type mismatches (e.g. comparing a string with `>`) throw
/// [ExpressionException] with full source context, since those indicate a
/// malformed payload rather than expected runtime variability.
class ExpressionEvaluator {
  const ExpressionEvaluator(this.data);

  final DynamicDataContext data;

  Object? evaluate(ExpressionNode node) {
    if (node is VariablePathExpressionNode) {
      return data.resolve(node.path).value;
    }
    if (node is LiteralExpressionNode) {
      return _literalValue(node.literal);
    }
    if (node is UnaryExpressionNode) {
      return _evaluateUnary(node);
    }
    if (node is BinaryExpressionNode) {
      return _evaluateBinary(node);
    }
    if (node is ConditionalExpressionNode) {
      final Object? condition = evaluate(node.condition);
      if (condition is! bool) {
        throw ExpressionException(
          'Ternary condition must evaluate to a boolean.',
          span: node.condition.span,
          expected: 'bool',
          actual: _describeType(condition),
        );
      }
      return condition ? evaluate(node.whenTrue) : evaluate(node.whenFalse);
    }
    throw ExpressionException(
        'Unsupported expression node: ${node.runtimeType}.',
        span: node.span);
  }

  Object? _evaluateUnary(UnaryExpressionNode node) {
    switch (node.operator) {
      case UnaryOperator.not:
        final Object? value = evaluate(node.operand);
        if (value is! bool) {
          throw ExpressionException(
            'The "!" operator requires a boolean operand.',
            span: node.operand.span,
            expected: 'bool',
            actual: _describeType(value),
          );
        }
        return !value;
      case UnaryOperator.negate:
        final Object? value = evaluate(node.operand);
        if (value is! num) {
          throw ExpressionException(
            'Unary "-" requires a numeric operand.',
            span: node.operand.span,
            expected: 'num',
            actual: _describeType(value),
          );
        }
        return -value;
    }
  }

  Object? _evaluateBinary(BinaryExpressionNode node) {
    switch (node.operator) {
      case BinaryOperator.and:
        final Object? left = evaluate(node.left);
        _requireBool(left, node.left.span);
        if (left == false) return false;
        final Object? right = evaluate(node.right);
        _requireBool(right, node.right.span);
        return right;
      case BinaryOperator.or:
        final Object? left = evaluate(node.left);
        _requireBool(left, node.left.span);
        if (left == true) return true;
        final Object? right = evaluate(node.right);
        _requireBool(right, node.right.span);
        return right;
      case BinaryOperator.nullCoalesce:
        final Object? left = evaluate(node.left);
        return left ?? evaluate(node.right);
      case BinaryOperator.equal:
        return evaluate(node.left) == evaluate(node.right);
      case BinaryOperator.notEqual:
        return evaluate(node.left) != evaluate(node.right);
      case BinaryOperator.greater:
        return _numLeft(node) > _numRight(node);
      case BinaryOperator.less:
        return _numLeft(node) < _numRight(node);
      case BinaryOperator.greaterEqual:
        return _numLeft(node) >= _numRight(node);
      case BinaryOperator.lessEqual:
        return _numLeft(node) <= _numRight(node);
      case BinaryOperator.add:
        return _evaluateAdd(node);
      case BinaryOperator.subtract:
        return _numLeft(node) - _numRight(node);
      case BinaryOperator.multiply:
        return _numLeft(node) * _numRight(node);
      case BinaryOperator.divide:
        return _numLeft(node) / _numRight(node);
    }
  }

  Object _evaluateAdd(BinaryExpressionNode node) {
    final Object? left = evaluate(node.left);
    final Object? right = evaluate(node.right);
    if (left is num && right is num) return left + right;
    if (left is String && right is String) return left + right;
    throw ExpressionException(
      'The "+" operator requires two numbers or two strings.',
      span: node.span,
      expected: 'num + num, or String + String',
      actual: '${_describeType(left)} + ${_describeType(right)}',
    );
  }

  num _numLeft(BinaryExpressionNode node) {
    final Object? value = evaluate(node.left);
    if (value is! num) {
      throw ExpressionException(
        'Operator "${node.operator.symbol}" requires numeric operands.',
        span: node.left.span,
        expected: 'num',
        actual: _describeType(value),
      );
    }
    return value;
  }

  num _numRight(BinaryExpressionNode node) {
    final Object? value = evaluate(node.right);
    if (value is! num) {
      throw ExpressionException(
        'Operator "${node.operator.symbol}" requires numeric operands.',
        span: node.right.span,
        expected: 'num',
        actual: _describeType(value),
      );
    }
    return value;
  }

  void _requireBool(Object? value, SourceSpan span) {
    if (value is! bool) {
      throw ExpressionException(
        'Operator requires boolean operands.',
        span: span,
        expected: 'bool',
        actual: _describeType(value),
      );
    }
  }

  Object? _literalValue(ValueNode node) {
    if (node is IntValueNode) return node.value;
    if (node is DoubleValueNode) return node.value;
    if (node is BoolValueNode) return node.value;
    if (node is StringValueNode) return node.value;
    if (node is NullValueNode) return null;
    throw ExpressionException('Unsupported literal in expression.',
        span: node.span);
  }

  String _describeType(Object? value) =>
      value == null ? 'null' : value.runtimeType.toString();
}
