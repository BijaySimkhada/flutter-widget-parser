import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LruCache', () {
    test('evicts least-recently-used entry once over capacity', () {
      final LruCache<String, int> cache = LruCache<String, int>(maxEntries: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3); // evicts 'a'
      expect(cache.containsKey('a'), isFalse);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('accessing an entry marks it most-recently-used', () {
      final LruCache<String, int> cache = LruCache<String, int>(maxEntries: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.get('a'); // 'a' is now more recent than 'b'
      cache.put('c', 3); // evicts 'b', not 'a'
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });
  });

  group('DynamicParserCache / parseToAst caching', () {
    test('identical source text returns the identical cached AST instance', () {
      final DynamicParserCache cache = DynamicParserCache(maxEntries: 10);
      const String source = 'Container(child: Text("hi"))';
      final AstNode first =
          DynamicWidgetParser.parseToAst(source, cache: cache);
      final AstNode second =
          DynamicWidgetParser.parseToAst(source, cache: cache);
      expect(identical(first, second), isTrue);
    });

    test('different source text produces distinct ASTs', () {
      final DynamicParserCache cache = DynamicParserCache(maxEntries: 10);
      final AstNode a =
          DynamicWidgetParser.parseToAst('Text("a")', cache: cache);
      final AstNode b =
          DynamicWidgetParser.parseToAst('Text("b")', cache: cache);
      expect(identical(a, b), isFalse);
    });

    test('disabling the cache always reparses', () {
      const String source = 'Text("x")';
      final AstNode first = DynamicWidgetParser.parseToAst(
        source,
        config: const DynamicParserConfig(enableAstCache: false),
      );
      final AstNode second = DynamicWidgetParser.parseToAst(
        source,
        config: const DynamicParserConfig(enableAstCache: false),
      );
      expect(identical(first, second), isFalse);
    });

    test('LRU eviction respects maxEntries', () {
      final DynamicParserCache cache = DynamicParserCache(maxEntries: 2);
      DynamicWidgetParser.parseToAst('Text("1")', cache: cache);
      DynamicWidgetParser.parseToAst('Text("2")', cache: cache);
      DynamicWidgetParser.parseToAst('Text("3")', cache: cache);
      expect(cache.length, 2);
    });
  });

  group('parsing performance stays bounded', () {
    test('a moderately large, realistic widget tree parses quickly', () {
      final StringBuffer children = StringBuffer();
      for (int i = 0; i < 200; i++) {
        children.write(
            'ListTile(title: Text("Item $i"), subtitle: Text("Subtitle $i")),');
      }
      final String source = 'ListView(children: [$children])';
      final Stopwatch stopwatch = Stopwatch()..start();
      DynamicWidgetParser.parseToAst(source,
          config: const DynamicParserConfig(enableAstCache: false));
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('re-parsing a cached large tree is effectively free', () {
      final StringBuffer children = StringBuffer();
      for (int i = 0; i < 200; i++) {
        children.write('Text("Item $i"),');
      }
      final String source = 'Column(children: [$children])';
      final DynamicParserCache cache = DynamicParserCache();
      DynamicWidgetParser.parseToAst(source, cache: cache); // warm the cache

      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        DynamicWidgetParser.parseToAst(source, cache: cache);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
