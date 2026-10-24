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
  es('es', 'Español'),
  tr('tr', 'Türkçe'),
  ms('ms', 'Bahasa Melayu'),
  ur('ur', 'اردو', rtl: true),

  /// Ready but not offered yet (see [hidden]).
  de('de', 'Deutsch', hidden: true),
  pt('pt', 'Português', hidden: true),
  it('it', 'Italiano', hidden: true),
  nl('nl', 'Nederlands', hidden: true),
  bs('bs', 'Bosanski', hidden: true);

  const AppLang(this.code, this.nativeName,
      {this.rtl = false, this.hidden = false});

  /// The locale code (ISO 639-1), as used by the ARB files.
  final String code;

  /// The language's name in that language, for the language menus.
  final String nativeName;

  /// Written right to left (Arabic, Urdu).
  final bool rtl;

  /// Translated but kept for a later update: not in the menus, Settings or
  /// the supported locales (a phone in that language gets the app's default)
  /// unless the build has `--dart-define=NEW_LANGS=true`.
  final bool hidden;

  static const bool showHidden =
      bool.fromEnvironment('NEW_LANGS', defaultValue: false);

  /// The languages the app offers, in order.
  static List<AppLang> get offered => <AppLang>[
        for (final AppLang l in values)
          if (!l.hidden || showHidden) l,
      ];

  /// The language for a locale code, or null if the app doesn't offer it.
  static AppLang? tryCode(String? code) {
    for (final AppLang l in offered) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// The language for a locale code; anything unknown reads as English.
  static AppLang fromCode(String code) => tryCode(code) ?? AppLang.en;

  bool get isAr => this == AppLang.ar;

  /// Upper case with this language's rules: Turkish i becomes İ, not I.
  String upper(String s) =>
      (this == AppLang.tr ? s.replaceAll('i', 'İ') : s).toUpperCase();

  /// The text for this language. A language without its own version falls
  /// back to English (names of currencies, markets…), so a new language can
  /// ship before every long text is translated.
  T pick<T>(T ar, T en,
          {T? fr, T? id, T? es, T? tr, T? ms, T? ur, T? de, T? pt, T? it, T? nl, T? bs}) =>
      switch (this) {
        AppLang.ar => ar,
        AppLang.en => en,
        AppLang.fr => fr ?? en,
        AppLang.id => id ?? en,
        AppLang.es => es ?? en,
        AppLang.tr => tr ?? en,
        AppLang.ms => ms ?? en,
        AppLang.ur => ur ?? en,
        AppLang.de => de ?? en,
        AppLang.pt => pt ?? en,
        AppLang.it => it ?? en,
        AppLang.nl => nl ?? en,
        AppLang.bs => bs ?? en,
      };
}
