import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<TokenType> _types(String source) =>
    DynamicLexer(source).tokenize().map((Token t) => t.type).toList();

void main() {
  group('literals', () {
    test('double-quoted string', () {
      final List<Token> tokens = DynamicLexer('"hello"').tokenize();
      expect(tokens[0].type, TokenType.string);
      expect(tokens[0].stringValue, 'hello');
    });

    test('single-quoted string', () {
      final List<Token> tokens = DynamicLexer("'hello'").tokenize();
      expect(tokens[0].stringValue, 'hello');
    });

    test('escaped characters', () {
      final List<Token> tokens = DynamicLexer(r'"Hello \"World\""').tokenize();
      expect(tokens[0].stringValue, 'Hello "World"');
    });

    test('escaped backslash', () {
      // DSL source text is: "a\\b"  (a, backslash-backslash escape, b)
      final List<Token> tokens = DynamicLexer(r'"a\\b"').tokenize();
      expect(tokens[0].stringValue, r'a\b');
    });

    test('escaped single quote inside single-quoted string', () {
      final List<Token> tokens = DynamicLexer(r"'It\'s working'").tokenize();
      expect(tokens[0].stringValue, "It's working");
    });

    test(r'newline and tab escapes', () {
      final List<Token> tokens = DynamicLexer(r'"a\nb\tc"').tokenize();
      expect(tokens[0].stringValue, 'a\nb\tc');
    });

    test('bare variable-path interpolation', () {
      final List<Token> tokens =
          DynamicLexer(r'"Hello $user.name!"').tokenize();
      final List<StringInterpolationPart> parts = tokens[0].interpolationParts!;
      expect(parts[0].text, 'Hello ');
      expect(parts[1].isBraced, isFalse);
      expect(parts[1].text, 'user.name');
      expect(parts[2].text, '!');
    });

    test('braced expression interpolation', () {
      final List<Token> tokens =
          DynamicLexer(r'"Total: ${$a + $b}"').tokenize();
      final List<StringInterpolationPart> parts = tokens[0].interpolationParts!;
      expect(parts[1].isBraced, isTrue);
      expect(parts[1].text, r'$a + $b');
    });

    test('unterminated string throws LexerException', () {
      expect(() => DynamicLexer('"unterminated').tokenize(),
          throwsA(isA<LexerException>()));
    });

    test('invalid escape sequence throws LexerException', () {
      expect(() => DynamicLexer(r'"\q"').tokenize(),
          throwsA(isA<LexerException>()));
    });

    test('integer', () {
      final Token t = DynamicLexer('42').tokenize().first;
      expect(t.type, TokenType.numberInt);
      expect(t.numValue, 42);
    });

    test('double', () {
      final Token t = DynamicLexer('3.14').tokenize().first;
      expect(t.type, TokenType.numberDouble);
      expect(t.numValue, 3.14);
    });

    test('exponent double', () {
      final Token t = DynamicLexer('1e3').tokenize().first;
      expect(t.type, TokenType.numberDouble);
      expect(t.numValue, 1000.0);
    });

    test('hex integer', () {
      final Token t = DynamicLexer('0xFF2196F3').tokenize().first;
      expect(t.type, TokenType.numberInt);
      expect(t.numValue, 0xFF2196F3);
    });

    test('booleans', () {
      expect(_types('true false'), <TokenType>[
        TokenType.booleanLiteral,
        TokenType.booleanLiteral,
        TokenType.eof
      ]);
    });

    test('null', () {
      expect(_types('null'), <TokenType>[TokenType.nullLiteral, TokenType.eof]);
    });

    test('identifier', () {
      final Token t = DynamicLexer('Container').tokenize().first;
      expect(t.type, TokenType.identifier);
      expect(t.lexeme, 'Container');
    });
  });

  group('punctuation and operators', () {
    test('all punctuation tokens', () {
      expect(
        _types(', : . ( ) [ ] { } ?'),
        <TokenType>[
          TokenType.comma,
          TokenType.colon,
          TokenType.dot,
          TokenType.lParen,
          TokenType.rParen,
          TokenType.lBracket,
          TokenType.rBracket,
          TokenType.lBrace,
          TokenType.rBrace,
          TokenType.question,
          TokenType.eof,
        ],
      );
    });

    test('operators', () {
      expect(
        _types('== != > < >= <= && || ! ?? + - * /'),
        <TokenType>[
          TokenType.equalEqual,
          TokenType.notEqual,
          TokenType.greater,
          TokenType.less,
          TokenType.greaterEqual,
          TokenType.lessEqual,
          TokenType.andAnd,
          TokenType.orOr,
          TokenType.bang,
          TokenType.questionQuestion,
          TokenType.plus,
          TokenType.minus,
          TokenType.star,
          TokenType.slash,
          TokenType.eof,
        ],
      );
    });

    test('dollar', () {
      expect(_types(r'$foo'),
          <TokenType>[TokenType.dollar, TokenType.identifier, TokenType.eof]);
    });

    test('lone "=" is invalid', () {
      expect(() => DynamicLexer('a = b').tokenize(),
          throwsA(isA<LexerException>()));
    });
  });

  group('comments and whitespace', () {
    test('line comment is skipped', () {
      expect(_types('Container // a comment\n()'), <TokenType>[
        TokenType.identifier,
        TokenType.lParen,
        TokenType.rParen,
        TokenType.eof
      ]);
    });

    test('block comment is skipped', () {
      expect(_types('Container(/* multi\nline */)'), <TokenType>[
        TokenType.identifier,
        TokenType.lParen,
        TokenType.rParen,
        TokenType.eof
      ]);
    });

    test('nested block comments are balanced', () {
      expect(_types('/* outer /* inner */ still-comment */Container'),
          <TokenType>[TokenType.identifier, TokenType.eof]);
    });

    test('unterminated block comment throws', () {
      expect(() => DynamicLexer('/* never closed').tokenize(),
          throwsA(isA<LexerException>()));
    });

    test('mixed whitespace is skipped', () {
      expect(_types('  \t\n Container \n\t '),
          <TokenType>[TokenType.identifier, TokenType.eof]);
    });
  });

  group('error context', () {
    test('LexerException reports line/column', () {
      try {
        DynamicLexer('Text(\n  "unterminated\n)').tokenize();
        fail('expected LexerException');
      } on LexerException catch (e) {
        expect(e.span, isNotNull);
        expect(e.span!.start.line, 2);
      }
    });

    test('unexpected character reports the offending character', () {
      try {
        DynamicLexer('Container(%)').tokenize();
        fail('expected LexerException');
      } on LexerException catch (e) {
        expect(e.actual, '%');
      }
    });
  });
}
