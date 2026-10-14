/// The app's display languages. Pure (no Flutter), so domain code can take
/// it; widgets get the current one with `AppLang.of(context)`
/// (app_lang_context.dart).
enum AppLang {
  ar,
  en,
  fr,
  id;

  /// The language for a locale code; anything unknown reads as English.
  static AppLang fromCode(String code) => switch (code) {
        'ar' => AppLang.ar,
        'fr' => AppLang.fr,
        'id' => AppLang.id,
        _ => AppLang.en,
      };

  bool get isAr => this == AppLang.ar;

  /// The text for this language. A language without its own version falls
  /// back to English (names of currencies, markets…).
  T pick<T>(T ar, T en, {T? fr, T? id}) => switch (this) {
        AppLang.ar => ar,
        AppLang.en => en,
        AppLang.fr => fr ?? en,
        AppLang.id => id ?? en,
      };
}
