/// The app's display languages: the one place that lists them.
///
/// Pure (no Flutter), so domain code can take it; widgets get the current
/// one with `appLangOf(context)` (app_lang_context.dart). The supported
/// locales, the language menu and Settings are all built from [values], so
/// a new language starts here — see docs/ADDING_A_LANGUAGE.md.
enum AppLang {
  ar('ar', 'العربية', rtl: true),
  en('en', 'English'),
  fr('fr', 'Français'),
  id('id', 'Bahasa Indonesia'),
  es('es', 'Español');

  const AppLang(this.code, this.nativeName, {this.rtl = false});

  /// The locale code (ISO 639-1), as used by the ARB files.
  final String code;

  /// The language's name in that language, for the language menus.
  final String nativeName;

  /// Written right to left (Arabic; later Urdu or Persian).
  final bool rtl;

  /// The language for a locale code, or null if the app doesn't have it.
  static AppLang? tryCode(String? code) {
    for (final AppLang l in values) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// The language for a locale code; anything unknown reads as English.
  static AppLang fromCode(String code) => tryCode(code) ?? AppLang.en;

  bool get isAr => this == AppLang.ar;

  /// The text for this language. A language without its own version falls
  /// back to English (names of currencies, markets…), so a new language can
  /// ship before every long text is translated.
  T pick<T>(T ar, T en, {T? fr, T? id, T? es}) => switch (this) {
        AppLang.ar => ar,
        AppLang.en => en,
        AppLang.fr => fr ?? en,
        AppLang.id => id ?? en,
        AppLang.es => es ?? en,
      };
}
