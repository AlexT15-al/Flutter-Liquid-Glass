/// Matching what was typed against food names, forgivingly.
///
/// - Any word of the name, in any order: "zorbas" finds "Sandwich Zorbas".
/// - The start of a word is enough: "zorb", "souvl".
/// - Greek or Greeklish, with or without accents: "ζορμπάς", "zorbas" and
///   "zormpas" are the same word; so are "σουβλάκι" and "souvlaki".
/// - One letter wrong in a longer word: "zorbaz", "souvlaky".
abstract final class FoodSearch {
  /// The query's words, folded; empty when there is nothing to look for.
  static List<String> words(String query) =>
      fold(query).split(' ').where((w) => w.isNotEmpty).toList(growable: false);

  /// How well [name] matches [words]: lower is better, null for no match.
  ///
  /// Every word typed has to match some word of the name. The score adds up
  /// how each matched (whole word, start of a word, inside a word, one
  /// letter off), and a name that starts with the first word typed, or is
  /// short, comes before one that is long.
  static int? score(String name, List<String> words) {
    if (words.isEmpty) return null;
    final folded = fold(name);
    final parts = folded.split(' ').where((w) => w.isNotEmpty).toList();
    var total = 0;
    for (final w in words) {
      int? best;
      for (final p in parts) {
        final s = _wordScore(p, w);
        if (s != null && (best == null || s < best)) best = s;
      }
      // Not word by word: inside the whole name, as "freddoespresso".
      if (best == null && folded.replaceAll(' ', '').contains(w)) best = 30;
      if (best == null) return null;
      total += best;
    }
    if (parts.isNotEmpty && parts.first.startsWith(words.first)) total -= 5;
    return total * 100 + folded.length;
  }

  static int? _wordScore(String part, String word) {
    if (part == word) return 0;
    if (part.startsWith(word)) return 10;
    if (word.length >= 3 && part.contains(word)) return 20;
    // One letter wrong, missing or extra: only for words long enough that
    // it is still the same word.
    if (word.length >= 4) {
      if (_withinOne(part, word)) return 40;
      // Or the start of a longer word, one letter off.
      if (part.length > word.length &&
          _withinOne(part.substring(0, word.length), word)) {
        return 50;
      }
    }
    return null;
  }

  /// Whether [a] and [b] differ by at most one edit.
  static bool _withinOne(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  /// Lower case, Latin letters, no accents, the spellings Greeklish varies
  /// on made one: what both the name and the query are compared as.
  static String fold(String text) {
    var s = text.toLowerCase();
    // Greek pairs first: μπ is b, ντ d, γκ and γγ g, ου u.
    for (final (from, to) in _greekPairs) {
      s = s.replaceAll(from, to);
    }
    final out = StringBuffer();
    for (final rune in s.runes) {
      final c = String.fromCharCode(rune);
      final mapped = _letters[c];
      if (mapped != null) {
        out.write(mapped);
      } else if (RegExp(r'[a-z0-9]').hasMatch(c)) {
        out.write(c);
      } else {
        out.write(' ');
      }
    }
    var latin = out.toString();
    // Greeklish written different ways comes out the same.
    for (final (from, to) in _latinPairs) {
      latin = latin.replaceAll(from, to);
    }
    // A doubled letter is one: "moussaka" and "musaka", "gemista" and
    // "yemmista" spelled either way.
    // Only pairs: three of a letter is not a spelling, it is "zzz".
    latin = latin.replaceAllMapped(
      RegExp(r'([a-z])\1+'),
      (m) => m[0]!.length == 2 ? m[1]! : m[0]!,
    );
    return latin.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const _greekPairs = [
    ('μπ', 'b'),
    ('ντ', 'd'),
    ('γκ', 'g'),
    ('γγ', 'g'),
    ('ού', 'u'),
    ('ου', 'u'),
    ('αί', 'e'),
    ('αι', 'e'),
    ('εί', 'i'),
    ('ει', 'i'),
    ('οί', 'i'),
    ('οι', 'i'),
  ];

  static const _letters = {
    'α': 'a', 'ά': 'a', 'β': 'v', 'γ': 'g', 'δ': 'd', 'ε': 'e', 'έ': 'e', //
    'ζ': 'z', 'η': 'i', 'ή': 'i', 'θ': 'th', 'ι': 'i', 'ί': 'i', 'ϊ': 'i',
    'ΐ': 'i', 'κ': 'k', 'λ': 'l', 'μ': 'm', 'ν': 'n', 'ξ': 'x', 'ο': 'o',
    'ό': 'o', 'π': 'p', 'ρ': 'r', 'σ': 's', 'ς': 's', 'τ': 't', 'υ': 'i',
    'ύ': 'i', 'ϋ': 'i', 'ΰ': 'i', 'φ': 'f', 'χ': 'h', 'ψ': 'ps', 'ω': 'o',
    'ώ': 'o',
    // Latin accents.
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
    'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  };

  /// Applied after the Greek is Latin: the spellings that vary in
  /// Greeklish, each to one. Order matters ("ou" before "o"…).
  static const _latinPairs = [
    ('mp', 'b'),
    ('nt', 'd'),
    ('ou', 'u'),
    ('ch', 'h'),
    ('ks', 'x'),
    ('th', 't'),
    ('ph', 'f'),
    ('ai', 'e'),
    ('ei', 'i'),
    ('oi', 'i'),
    ('y', 'i'),
    ('w', 'o'),
    ('ee', 'i'),
    ('oo', 'u'),
  ];
}
