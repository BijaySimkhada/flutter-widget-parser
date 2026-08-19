import '../ast/value_node.dart';
import 'lru_cache.dart';

/// Caches parsed ASTs keyed by exact source text, so re-parsing the same
/// remote-UI payload (extremely common — a server often sends the same
/// screen definition repeatedly, or a list re-renders many identical
/// item templates) skips lexing and parsing entirely.
///
/// AST nodes are immutable, so a cached tree can be safely reused (and
/// even shared) across multiple `buildFromAst` calls with different
/// `DynamicDataContext`s — only the *build* step, not the parse, depends
/// on runtime data.
class DynamicParserCache {
  DynamicParserCache({this.maxEntries = 100})
      : _cache = LruCache<String, ValueNode>(maxEntries: maxEntries);

  final int maxEntries;
  final LruCache<String, ValueNode> _cache;

  ValueNode? get(String source) => _cache.get(source);

  void put(String source, ValueNode ast) => _cache.put(source, ast);

  void clear() => _cache.clear();

  int get length => _cache.length;
}
