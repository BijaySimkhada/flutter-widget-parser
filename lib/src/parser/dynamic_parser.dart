import '../ast/ast.dart';
import '../errors/dynamic_parser_exception.dart';
import '../errors/source_span.dart';
import '../lexer/dynamic_lexer.dart';
import '../lexer/token.dart';
import 'parser_limits.dart';

/// Recursive-descent parser that turns a flat [Token] stream into an
/// immutable AST rooted at a [ValueNode] (almost always a [WidgetNode]).
///
/// The grammar recognized (informally):
/// ```text
/// value        := string | number | boolean | null | list | map
///               | identifierOrCall | expression
/// identifierOrCall := identifier ('.' identifier)* ('(' arguments ')')?
/// arguments    := (argument (',' argument)* ','?)?
/// argument     := (identifier ':')? value
/// list         := '[' (value (',' value)* ','?)? ']'
/// map          := '{' (value ':' value (',' value ':' value)* ','?)? '}'
/// expression   := ternary
/// ternary      := nullCoalesce ('?' expression ':' expression)?
/// nullCoalesce := or ('??' or)*
/// or           := and ('||' and)*
/// and          := equality ('&&' equality)*
/// equality     := relational (('==' | '!=') relational)*
/// relational   := additive (('>' | '<' | '>=' | '<=') additive)*
/// additive     := multiplicative (('+' | '-') multiplicative)*
/// multiplicative := unary (('*' | '/') unary)*
/// unary        := ('!' | '-') unary | primary
/// primary      := '$' identifier ('.' identifier)*
///               | '(' expression ')'
///               | string | number | boolean | null
/// ```
///
/// This is deliberately *not* a general Dart grammar — see the package
/// README's "Supported syntax" section for the exact supported subset.
class DynamicParser {
  DynamicParser(this.source, {this.limits = const DynamicParserLimits()});

  final String source;
  final DynamicParserLimits limits;

  List<Token> _tokens = const <Token>[];
  int _pos = 0;
  int _structuralDepth = 0;
  int _expressionDepthCounter = 0;
  int _nodeCount = 0;
  final Stopwatch _stopwatch = Stopwatch();

  /// Parses [source] into an AST. Throws [SyntaxException]/[LexerException]
  /// on malformed input, or [SyntaxException] if configured resource
  /// limits are exceeded.
  ValueNode parseToAst() {
    if (source.length > limits.maxSourceLength) {
      throw SyntaxException(
        'Source exceeds maximum allowed length of ${limits.maxSourceLength} characters.',
        expected: 'source length <= ${limits.maxSourceLength}',
        actual: '${source.length} characters',
      );
    }
    _loadTokens(source);
    _structuralDepth = 0;
    _expressionDepthCounter = 0;
    _nodeCount = 0;
    _stopwatch
      ..reset()
      ..start();
    final ValueNode result = _parseValue();
    _expectEof();
    return result;
  }

  void _loadTokens(String src) {
    _tokens =
        DynamicLexer(src, maxStringLength: limits.maxStringLength).tokenize();
    _pos = 0;
  }

  // ---------------------------------------------------------------------
  // Token stream helpers
  // ---------------------------------------------------------------------

  Token get _current => _tokens[_pos];

  Token _peekAt(int offset) {
    final int i = _pos + offset;
    return i < _tokens.length ? _tokens[i] : _tokens.last;
  }

  bool _check(TokenType type) => _current.type == type;

  Token _next() {
    final Token t = _current;
    if (_pos < _tokens.length - 1) _pos++;
    return t;
  }

  Token _expect(TokenType type, String expectedDescription) {
    if (!_check(type)) {
      throw _syntaxError(
        'Unexpected token.',
        expected: expectedDescription,
        actual: _describe(_current),
      );
    }
    return _next();
  }

  void _expectEof() {
    if (!_check(TokenType.eof)) {
      throw _syntaxError(
        'Unexpected trailing content after the top-level value.',
        expected: 'end of input',
        actual: _describe(_current),
      );
    }
  }

  String _describe(Token t) {
    switch (t.type) {
      case TokenType.eof:
        return 'end of input';
      case TokenType.identifier:
        return 'identifier "${t.lexeme}"';
      case TokenType.string:
        return 'string literal';
      default:
        return '"${t.lexeme}"';
    }
  }

  SyntaxException _syntaxError(String message,
      {SourceSpan? span, String? expected, String? actual}) {
    return SyntaxException(
      message,
      span: span ?? _current.span(source),
      expected: expected,
      actual: actual,
    );
  }

  SourceSpan _combine(SourceSpan a, SourceSpan b) =>
      SourceSpan(start: a.start, end: b.end, source: source);

  void _checkBudget() {
    if (_stopwatch.elapsed > limits.maxParseDuration) {
      throw _syntaxError(
        'Parsing exceeded the configured time budget of ${limits.maxParseDuration}.',
      );
    }
  }

  void _countNode() {
    _nodeCount++;
    if (_nodeCount > limits.maxWidgetCount) {
      throw _syntaxError(
          'Source exceeds maximum node count of ${limits.maxWidgetCount}.');
    }
  }

  /// Called once per operator application while parsing a binary
  /// expression chain (`$a + $a + $a + ...`). Precedence-climbing loops are
  /// O(1) in *depth* regardless of how many operators appear — depth
  /// tracking alone can't bound a very long flat chain — so length is
  /// bounded the same way overall AST size is: against `maxWidgetCount`.
  void _countExpressionOperator() {
    _checkBudget();
    _countNode();
  }

  T _withStructuralDepth<T>(T Function() body) {
    _structuralDepth++;
    if (_structuralDepth > limits.maxAstDepth) {
      throw _syntaxError(
          'Maximum nesting depth of ${limits.maxAstDepth} exceeded.');
    }
    try {
      return body();
    } finally {
      _structuralDepth--;
    }
  }

  T _withExpressionDepth<T>(T Function() body) {
    _expressionDepthCounter++;
    if (_expressionDepthCounter > limits.maxExpressionDepth) {
      throw _syntaxError(
          'Maximum expression nesting depth of ${limits.maxExpressionDepth} exceeded.');
    }
    try {
      return body();
    } finally {
      _expressionDepthCounter--;
    }
  }

  // ---------------------------------------------------------------------
  // Values
  // ---------------------------------------------------------------------

  ValueNode _parseValue() {
    _checkBudget();
    _countNode();
    final Token tok = _current;
    switch (tok.type) {
      case TokenType.string:
        return _parseStringValue(tok);
      case TokenType.numberInt:
        _next();
        return IntValueNode(tok.numValue as int, span: tok.span(source));
      case TokenType.numberDouble:
        _next();
        return DoubleValueNode(tok.numValue as double, span: tok.span(source));
      case TokenType.booleanLiteral:
        _next();
        return BoolValueNode(tok.lexeme == 'true', span: tok.span(source));
      case TokenType.nullLiteral:
        _next();
        return NullValueNode(span: tok.span(source));
      case TokenType.minus:
        // `-8` is a negative literal; `-$a` (or anything else after the
        // minus) is unary negation of a full expression.
        return (_peekAt(1).type == TokenType.numberInt ||
                _peekAt(1).type == TokenType.numberDouble)
            ? _parseNegativeNumberLiteral()
            : _parseExpression();
      case TokenType.lBracket:
        return _parseList();
      case TokenType.lBrace:
        return _parseMap();
      case TokenType.dollar:
      case TokenType.bang:
      case TokenType.lParen:
        // These three tokens are otherwise meaningless at the start of a
        // value, so they unambiguously mean "an expression starts here"
        // even without a leading `$` (which is still required to *name a
        // variable*, just not to open every expression).
        return _parseExpression();
      case TokenType.identifier:
        return _parseIdentifierOrCall();
      default:
        throw _syntaxError(
          'Unexpected token while parsing a value.',
          actual: _describe(tok),
          expected:
              'a value (identifier, string, number, boolean, null, list, map, or \$expression)',
        );
    }
  }

  ValueNode _parseNegativeNumberLiteral() {
    final Token minusTok = _next();
    final Token numTok = _current;
    if (numTok.type == TokenType.numberInt) {
      _next();
      return IntValueNode(-(numTok.numValue as int),
          span: _combine(minusTok.span(source), numTok.span(source)));
    }
    if (numTok.type == TokenType.numberDouble) {
      _next();
      return DoubleValueNode(
        -(numTok.numValue as double),
        span: _combine(minusTok.span(source), numTok.span(source)),
      );
    }
    throw _syntaxError(
      'Expected a number literal after unary "-".',
      span: numTok.span(source),
      expected: 'number',
      actual: _describe(numTok),
    );
  }

  ValueNode _parseStringValue(Token tok) {
    _next();
    final List<StringInterpolationPart>? parts = tok.interpolationParts;
    if (parts == null) {
      return StringValueNode(tok.stringValue ?? '', span: tok.span(source));
    }
    final List<Object> resolvedParts = <Object>[];
    for (final StringInterpolationPart part in parts) {
      if (!part.isExpression) {
        resolvedParts.add(part.text);
      } else if (part.isBraced) {
        resolvedParts.add(_parseEmbeddedExpression(part.text, tok));
      } else {
        resolvedParts.add(VariablePathExpressionNode(part.text.split('.'),
            span: tok.span(source)));
      }
    }
    return StringInterpolationValueNode(resolvedParts, span: tok.span(source));
  }

  ExpressionNode _parseEmbeddedExpression(String exprSource, Token hostToken) {
    final DynamicParser sub = DynamicParser(exprSource, limits: limits);
    try {
      sub._loadTokens(exprSource);
      sub._stopwatch
        ..reset()
        ..start();
      final ExpressionNode expr = sub._parseExpression();
      sub._expectEof();
      return expr;
    } on DynamicParserException catch (e) {
      throw ExpressionException(
        'Invalid expression in string interpolation "${exprSource.trim()}": ${e.message}',
        span: hostToken.span(source),
      );
    }
  }

  ValueNode _parseIdentifierOrCall() {
    final Token first = _expect(TokenType.identifier, 'identifier');
    final List<String> path = <String>[first.lexeme];
    Token last = first;
    while (_check(TokenType.dot)) {
      _next();
      final Token seg = _expect(TokenType.identifier, 'identifier after "."');
      path.add(seg.lexeme);
      last = seg;
    }
    if (_check(TokenType.lParen)) {
      final String name = path.length > 1
          ? path.sublist(0, path.length - 1).join('.')
          : path.first;
      final String? constructorName = path.length > 1 ? path.last : null;
      final _ArgumentList args = _parseArgumentList();
      return WidgetNode(
        name: name,
        constructorName: constructorName,
        positionalArguments: args.positional,
        properties: args.named,
        span: _combine(first.span(source), args.closingParen.span(source)),
      );
    }
    return IdentifierPathValueNode(path,
        span: _combine(first.span(source), last.span(source)));
  }

  _ArgumentList _parseArgumentList() {
    _expect(TokenType.lParen, "'('");
    return _withStructuralDepth(() {
      final List<ValueNode> positional = <ValueNode>[];
      final List<PropertyNode> named = <PropertyNode>[];
      final Set<String> seenNames = <String>{};
      while (!_check(TokenType.rParen)) {
        _checkBudget();
        if (positional.length + named.length >= limits.maxListLength) {
          throw _syntaxError(
              'Argument list exceeds maximum length of ${limits.maxListLength}.');
        }
        if (_check(TokenType.identifier) &&
            _peekAt(1).type == TokenType.colon) {
          final Token nameTok = _next();
          _next(); // colon
          final ValueNode value = _parseValue();
          if (!seenNames.add(nameTok.lexeme)) {
            throw _syntaxError(
              'Duplicate named argument "${nameTok.lexeme}".',
              span: nameTok.span(source),
            );
          }
          named.add(PropertyNode(
              name: nameTok.lexeme,
              value: value,
              span: _combine(nameTok.span(source), value.span)));
        } else {
          positional.add(_parseValue());
        }
        if (_check(TokenType.comma)) {
          _next();
        } else {
          break;
        }
      }
      final Token rparen = _expect(TokenType.rParen, "')'");
      return _ArgumentList(
          positional: positional, named: named, closingParen: rparen);
    });
  }

  ListValueNode _parseList() {
    final Token lbracket = _expect(TokenType.lBracket, "'['");
    return _withStructuralDepth(() {
      final List<ValueNode> items = <ValueNode>[];
      while (!_check(TokenType.rBracket)) {
        _checkBudget();
        if (items.length >= limits.maxListLength) {
          throw _syntaxError(
              'List exceeds maximum length of ${limits.maxListLength}.');
        }
        items.add(_parseValue());
        if (_check(TokenType.comma)) {
          _next();
        } else {
          break;
        }
      }
      final Token rbracket = _expect(TokenType.rBracket, "']'");
      return ListValueNode(items,
          span: _combine(lbracket.span(source), rbracket.span(source)));
    });
  }

  MapValueNode _parseMap() {
    final Token lbrace = _expect(TokenType.lBrace, "'{'");
    return _withStructuralDepth(() {
      final List<MapEntryNode> entries = <MapEntryNode>[];
      while (!_check(TokenType.rBrace)) {
        _checkBudget();
        if (entries.length >= limits.maxListLength) {
          throw _syntaxError(
              'Map exceeds maximum entry count of ${limits.maxListLength}.');
        }
        final ValueNode key = _parseValue();
        _expect(TokenType.colon, "':'");
        final ValueNode value = _parseValue();
        entries.add(MapEntryNode(
            key: key, value: value, span: _combine(key.span, value.span)));
        if (_check(TokenType.comma)) {
          _next();
        } else {
          break;
        }
      }
      final Token rbrace = _expect(TokenType.rBrace, "'}'");
      return MapValueNode(entries,
          span: _combine(lbrace.span(source), rbrace.span(source)));
    });
  }

  // ---------------------------------------------------------------------
  // Expressions
  // ---------------------------------------------------------------------

  ExpressionNode _parseExpression() {
    _checkBudget();
    return _withExpressionDepth(_parseTernary);
  }

  ExpressionNode _parseTernary() {
    final ExpressionNode cond = _parseNullCoalesce();
    if (_check(TokenType.question)) {
      _next();
      final ExpressionNode whenTrue = _parseExpression();
      _expect(TokenType.colon, "':'");
      final ExpressionNode whenFalse = _parseExpression();
      return ConditionalExpressionNode(
        condition: cond,
        whenTrue: whenTrue,
        whenFalse: whenFalse,
        span: _combine(cond.span, whenFalse.span),
      );
    }
    return cond;
  }

  ExpressionNode _parseNullCoalesce() {
    ExpressionNode left = _parseOr();
    while (_check(TokenType.questionQuestion)) {
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseOr();
      left = BinaryExpressionNode(
        operator: BinaryOperator.nullCoalesce,
        left: left,
        right: right,
        span: _combine(left.span, right.span),
      );
    }
    return left;
  }

  ExpressionNode _parseOr() {
    ExpressionNode left = _parseAnd();
    while (_check(TokenType.orOr)) {
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseAnd();
      left = BinaryExpressionNode(
          operator: BinaryOperator.or,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseAnd() {
    ExpressionNode left = _parseEquality();
    while (_check(TokenType.andAnd)) {
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseEquality();
      left = BinaryExpressionNode(
          operator: BinaryOperator.and,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseEquality() {
    ExpressionNode left = _parseRelational();
    while (_check(TokenType.equalEqual) || _check(TokenType.notEqual)) {
      final BinaryOperator op = _check(TokenType.equalEqual)
          ? BinaryOperator.equal
          : BinaryOperator.notEqual;
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseRelational();
      left = BinaryExpressionNode(
          operator: op,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseRelational() {
    ExpressionNode left = _parseAdditive();
    while (_check(TokenType.greater) ||
        _check(TokenType.less) ||
        _check(TokenType.greaterEqual) ||
        _check(TokenType.lessEqual)) {
      final BinaryOperator op = switch (_current.type) {
        TokenType.greater => BinaryOperator.greater,
        TokenType.less => BinaryOperator.less,
        TokenType.greaterEqual => BinaryOperator.greaterEqual,
        _ => BinaryOperator.lessEqual,
      };
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseAdditive();
      left = BinaryExpressionNode(
          operator: op,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseAdditive() {
    ExpressionNode left = _parseMultiplicative();
    while (_check(TokenType.plus) || _check(TokenType.minus)) {
      final BinaryOperator op =
          _check(TokenType.plus) ? BinaryOperator.add : BinaryOperator.subtract;
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseMultiplicative();
      left = BinaryExpressionNode(
          operator: op,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseMultiplicative() {
    ExpressionNode left = _parseUnary();
    while (_check(TokenType.star) || _check(TokenType.slash)) {
      final BinaryOperator op = _check(TokenType.star)
          ? BinaryOperator.multiply
          : BinaryOperator.divide;
      _next();
      _countExpressionOperator();
      final ExpressionNode right = _parseUnary();
      left = BinaryExpressionNode(
          operator: op,
          left: left,
          right: right,
          span: _combine(left.span, right.span));
    }
    return left;
  }

  ExpressionNode _parseUnary() {
    // Unlike the binary-operator loops above, `!!!!!...$a` recurses once
    // per `!`/`-`, which is real *parser call-stack* recursion — so this
    // needs depth tracking to prevent a stack overflow while parsing,
    // not just a check on the resulting AST's shape after the fact.
    if (_check(TokenType.bang)) {
      final Token op = _next();
      final ExpressionNode operand = _withExpressionDepth(_parseUnary);
      return UnaryExpressionNode(
          operator: UnaryOperator.not,
          operand: operand,
          span: _combine(op.span(source), operand.span));
    }
    if (_check(TokenType.minus)) {
      final Token op = _next();
      final ExpressionNode operand = _withExpressionDepth(_parseUnary);
      return UnaryExpressionNode(
        operator: UnaryOperator.negate,
        operand: operand,
        span: _combine(op.span(source), operand.span),
      );
    }
    return _parsePrimaryExpression();
  }

  ExpressionNode _parsePrimaryExpression() {
    final Token tok = _current;
    switch (tok.type) {
      case TokenType.dollar:
        return _parseVariablePath();
      case TokenType.lParen:
        _next();
        final ExpressionNode inner = _parseExpression();
        _expect(TokenType.rParen, "')'");
        return inner;
      case TokenType.string:
        _next();
        final String text = tok.stringValue ??
            (tok.interpolationParts ?? const <StringInterpolationPart>[])
                .where((StringInterpolationPart p) => !p.isExpression)
                .map((StringInterpolationPart p) => p.text)
                .join();
        return LiteralExpressionNode(
            StringValueNode(text, span: tok.span(source)),
            span: tok.span(source));
      case TokenType.numberInt:
        _next();
        return LiteralExpressionNode(
            IntValueNode(tok.numValue as int, span: tok.span(source)),
            span: tok.span(source));
      case TokenType.numberDouble:
        _next();
        return LiteralExpressionNode(
            DoubleValueNode(tok.numValue as double, span: tok.span(source)),
            span: tok.span(source));
      case TokenType.booleanLiteral:
        _next();
        return LiteralExpressionNode(
            BoolValueNode(tok.lexeme == 'true', span: tok.span(source)),
            span: tok.span(source));
      case TokenType.nullLiteral:
        _next();
        return LiteralExpressionNode(NullValueNode(span: tok.span(source)),
            span: tok.span(source));
      default:
        throw _syntaxError(
          'Unexpected token in expression.',
          actual: _describe(tok),
          expected: 'a \$variable, literal, or parenthesized expression',
        );
    }
  }

  VariablePathExpressionNode _parseVariablePath() {
    final Token dollarTok = _expect(TokenType.dollar, "'\$'");
    final Token first = _expect(TokenType.identifier, 'identifier after "\$"');
    final List<String> path = <String>[first.lexeme];
    Token last = first;
    while (_check(TokenType.dot)) {
      _next();
      // Both `$user.name` (identifier segment) and `$items.0` (integer
      // segment, for list indexing) are valid path components.
      final Token seg = _check(TokenType.numberInt)
          ? _next()
          : _expect(TokenType.identifier, 'identifier or list index after "."');
      path.add(seg.lexeme);
      last = seg;
    }
    return VariablePathExpressionNode(path,
        span: _combine(dollarTok.span(source), last.span(source)));
  }
}

class _ArgumentList {
  const _ArgumentList(
      {required this.positional,
      required this.named,
      required this.closingParen});

  final List<ValueNode> positional;
  final List<PropertyNode> named;
  final Token closingParen;
}
