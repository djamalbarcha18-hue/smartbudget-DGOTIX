/// Picking the speech locale to listen in.
///
/// The device decides which languages it can hear; the app only says which one
/// to use. Pure (no plugin, no Flutter) so the choice can be tested on its own.
library;

abstract final class VoiceLocale {
  /// The language part of a locale id, lowercased: `ar_DZ`, `ar-DZ`, `ar` → `ar`.
  static String languageOf(String id) =>
      id.split(RegExp('[_-]')).first.trim().toLowerCase();

  /// The region part, uppercased, or null: `ar_DZ` → `DZ`, `ar` → null.
  static String? regionOf(String id) {
    final List<String> parts = id.split(RegExp('[_-]'));
    if (parts.length < 2) return null;
    final String r = parts[1].trim().toUpperCase();
    return r.isEmpty ? null : r;
  }

  /// The id to listen in for [language], out of the device's [available] ones.
  ///
  /// Picks, in order: the variant of that language spoken where the device is
  /// set ([systemLocale], so an Arabic speaker is heard in their own dialect),
  /// then the plain language with no region, then the first variant offered.
  /// Null when the device can't hear that language at all — the caller then
  /// leaves the choice to the device instead of forcing a wrong one.
  static String? pick(
    String language,
    List<String> available, {
    String? systemLocale,
  }) {
    final String want = languageOf(language);
    if (want.isEmpty) return null;
    final List<String> sameLanguage =
        available.where((String id) => languageOf(id) == want).toList();
    if (sameLanguage.isEmpty) return null;

    final String? here = systemLocale == null ? null : regionOf(systemLocale);
    if (here != null) {
      for (final String id in sameLanguage) {
        if (regionOf(id) == here) return id;
      }
    }
    for (final String id in sameLanguage) {
      if (regionOf(id) == null) return id;
    }
    return sameLanguage.first;
  }
}
