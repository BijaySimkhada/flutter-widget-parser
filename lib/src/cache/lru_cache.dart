import 'dart:collection';

/// A minimal least-recently-used cache backed by [LinkedHashMap], whose
/// iteration order tracks insertion order — reinserting a key on access
/// moves it to the "most recently used" end without needing a separate
/// doubly-linked-list implementation.
class LruCache<K, V> {
  LruCache({required this.maxEntries})
      : assert(maxEntries > 0, 'maxEntries must be positive');

  final int maxEntries;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  V? get(K key) {
    final V? value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value; // reinsert => most-recently-used
    return value;
  }

  bool containsKey(K key) => _entries.containsKey(key);

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();

  int get length => _entries.length;
}
