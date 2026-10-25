import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's own strings (date pickers, the back button's tooltip, text
/// selection…) for a language Flutter doesn't translate, such as Hausa: they
/// fall back to English, so the app still opens in that language. Languages
/// Flutter does translate keep its own delegates.
const List<LocalizationsDelegate<Object>> fallbackLocalizationsDelegates =
    <LocalizationsDelegate<Object>>[
  _FallbackMaterialDelegate(),
  _FallbackCupertinoDelegate(),
  _FallbackWidgetsDelegate(),
];

const Locale _english = Locale('en');

class _FallbackMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackMaterialDelegate old) => false;
}

class _FallbackCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackCupertinoDelegate old) => false;
}

class _FallbackWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FallbackWidgetsDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalWidgetsLocalizations.delegate.isSupported(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackWidgetsDelegate old) => false;
}
