import 'dart:convert';

import 'package:smartbudget/core/l10n/app_lang.dart';

/// A suggested place (assets/data/destinations.json).
class Destination {
  const Destination({
    required this.id,
    required this.names,
    required this.country,
    required this.icon,
    required this.order,
    this.aliases = const <String>[],
    this.image,
  });

  final String id;

  /// Language code -> name.
  final Map<String, String> names;

  /// Other common spellings ("Mecca"), searched but never shown.
  final List<String> aliases;

  /// ISO 3166-1 alpha-2.
  final String country;

  /// An icon name (see `destinationIcon`), shown when there is no image.
  final String icon;
  final int order;

  /// A bundled picture, or null when none has been added.
  final String? image;

  String nameFor(AppLang lang) => names[lang.code] ?? names['en'] ?? id;

  Iterable<String> get searchNames => <String>[...names.values, ...aliases];

  factory Destination.fromJson(Map<String, dynamic> j) => Destination(
        id: j['id'] as String,
        names: (j['names'] as Map<String, dynamic>)
            .map((String k, dynamic v) => MapEntry<String, String>(k, '$v')),
        aliases: ((j['aliases'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => '$e')
            .toList(),
        country: (j['country'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? '',
        order: (j['order'] as num?)?.toInt() ?? 999,
        image: j['image'] as String?,
      );

  Destination withoutImage() => Destination(
      id: id,
      names: names,
      aliases: aliases,
      country: country,
      icon: icon,
      order: order);
}

/// The suggested places, in their set order, and searching them.
class DestinationCatalog {
  DestinationCatalog(List<Destination> items)
      : all = List<Destination>.unmodifiable(List<Destination>.of(items)
          ..sort((Destination a, Destination b) => a.order.compareTo(b.order)));

  /// Reads the JSON list. With [bundled] (the app's asset list), an image
  /// that isn't actually in the app is dropped, so the icon shows instead.
  factory DestinationCatalog.fromJson(String raw, {Set<String>? bundled}) {
    final List<Destination> items = <Destination>[
      for (final Object? e in jsonDecode(raw) as List<dynamic>)
        if (e is Map<String, dynamic>) Destination.fromJson(e),
    ];
    return DestinationCatalog(<Destination>[
      for (final Destination d in items)
        if (d.image != null && bundled != null && !bundled.contains(d.image))
          d.withoutImage()
        else
          d,
    ]);
  }

  static final DestinationCatalog empty =
      DestinationCatalog(const <Destination>[]);

  final List<Destination> all;

  /// The first [n] in the set order.
  List<Destination> popular([int n = 6]) => all.take(n).toList();

  /// The place [text] names, in any language (accents, vowel marks and
  /// hamza forms aside).
  Destination? byText(String text) {
    final String q = PlaceText.normalize(text);
    if (q.isEmpty) return null;
    for (final Destination d in all) {
      if (d.searchNames.any((String n) => PlaceText.normalize(n) == q)) {
        return d;
      }
    }
    return null;
  }

  /// Places whose name, in any language, matches [query]: whole name, then
  /// a word starting with it, then containing it; set order within each.
  List<Destination> search(String query) {
    final String q = PlaceText.normalize(query);
    if (q.isEmpty) return const <Destination>[];
    final List<(int, Destination)> hits = <(int, Destination)>[];
    for (final Destination d in all) {
      int? best;
      for (final String n in d.searchNames) {
        final int? s = PlaceText.matchRank(PlaceText.normalize(n), q);
        if (s != null && (best == null || s < best)) best = s;
      }
      if (best != null) hits.add((best, d));
    }
    hits.sort(((int, Destination) a, (int, Destination) b) =>
        a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.order.compareTo(b.$2.order));
    return <Destination>[for (final (int, Destination) h in hits) h.$2];
  }

  /// How [text] reads in [lang]: a catalog place in that language, anything
  /// else as typed.
  String display(String text, AppLang lang) =>
      byText(text)?.nameFor(lang) ?? text;
}

/// Comparing and tidying place names.
abstract final class PlaceText {
  static final RegExp _arabicMarks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static final RegExp _combining = RegExp('[̀-ͯ]');
  static final RegExp _separators = RegExp(r"[\s\-_'’.,·/()]+");

  static const Map<String, String> _letters = <String, String>{
    // Arabic hamza forms and letter variants; Urdu letters.
    'آ': 'ا', 'أ': 'ا', 'إ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي', 'ء': '',
    'ى': 'ي', 'ی': 'ي', 'ے': 'ي', 'ة': 'ه', 'ۃ': 'ه', 'ہ': 'ه', 'ھ': 'ه',
    'ک': 'ك',
    // Latin letters with accents.
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
    'ï': 'i', 'ı': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
    'ö': 'o', 'ø': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ş': 's',
    'ğ': 'g', 'ý': 'y', 'ÿ': 'y',
  };

  /// A form for comparing: lower case, without accents, Arabic vowel marks
  /// or tatweel, one hamza-less form per letter, single spaces.
  static String normalize(String s) {
    final String lower = s
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .toLowerCase()
        .replaceAll(_combining, '')
        .replaceAll(_arabicMarks, '');
    final StringBuffer b = StringBuffer();
    for (final int rune in lower.runes) {
      final String ch = String.fromCharCode(rune);
      b.write(_letters[ch] ?? ch);
    }
    return b.toString().replaceAll(_separators, ' ').trim();
  }

  /// 0: [name] is [q]; 1: a word of it starts with [q]; 2: it contains [q];
  /// null: no match. Both already normalized.
  static int? matchRank(String name, String q) {
    if (name == q) return 0;
    if (name.startsWith(q) || name.contains(' $q')) return 1;
    if (name.contains(q)) return 2;
    return null;
  }

  /// A typed place tidied for keeping: single spaces, and Latin words in
  /// one case ("new york" and "NEW YORK" become "New York"; "McAllen" and
  /// short abbreviations like "NYC" in mixed text stay).
  static String clean(String s) {
    final String text = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    // All in capitals with a long word ("NEW YORK"): typed with caps lock.
    final bool shouted = text == text.toUpperCase() &&
        text.split(' ').any((String w) => _latin.hasMatch(w) && w.length > 3);
    return text
        .split(' ')
        .map((String w) => _word(w, keepShort: !shouted))
        .join(' ');
  }

  static final RegExp _latin = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ]+$');

  static String _word(String w, {required bool keepShort}) {
    if (!_latin.hasMatch(w)) return w;
    final bool lower = w == w.toLowerCase();
    final bool upper = w == w.toUpperCase();
    if (!lower && !upper) return w;
    if (upper && keepShort && w.length <= 3) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }
}
