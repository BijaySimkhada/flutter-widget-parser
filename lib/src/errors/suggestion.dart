/// Finds the closest match to [input] among [candidates] using Levenshtein
/// distance, for "did you mean X?" style error messages. Returns null when
/// nothing is close enough to be a useful suggestion.
String? findClosestMatch(String input, Iterable<String> candidates) {
  String? best;
  int bestDistance = 1 << 30;
  final int threshold = (input.length / 2).ceil().clamp(2, 6);
  for (final String candidate in candidates) {
    final int distance =
        _levenshtein(input.toLowerCase(), candidate.toLowerCase());
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }
  if (best == null || bestDistance > threshold) return null;
  return best;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  List<int> previousRow = List<int>.generate(b.length + 1, (int i) => i);
  List<int> currentRow = List<int>.filled(b.length + 1, 0);

  for (int i = 0; i < a.length; i++) {
    currentRow[0] = i + 1;
    for (int j = 0; j < b.length; j++) {
      final int deletionCost = previousRow[j + 1] + 1;
      final int insertionCost = currentRow[j] + 1;
      final int substitutionCost = previousRow[j] + (a[i] == b[j] ? 0 : 1);
      currentRow[j + 1] = <int>[deletionCost, insertionCost, substitutionCost]
          .reduce((int x, int y) => x < y ? x : y);
    }
    final List<int> temp = previousRow;
    previousRow = currentRow;
    currentRow = temp;
  }
  return previousRow[b.length];
}
