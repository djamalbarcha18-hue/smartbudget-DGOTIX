import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/features/quick_entry/data/speech_engine.dart';
import 'package:smartbudget/features/quick_entry/domain/voice_locale.dart';
import 'package:smartbudget/features/quick_entry/presentation/voice_input_button.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A microphone the test drives by hand.
class _FakeEngine implements SpeechEngine {
  _FakeEngine({this.supported = true, this.failWith, this.opening});

  @override
  final bool supported;

  /// When set, [start] refuses with it instead of listening.
  final VoiceFailure? failWith;

  /// When set, [start] waits for it, standing in for an engine that takes a
  /// moment to wake up.
  final Completer<void>? opening;

  @override
  bool listening = false;

  /// The language [start] was asked for.
  String? askedFor;
  int stops = 0;
  int cancels = 0;
  void Function(VoiceHeard)? _onHeard;

  @override
  Future<VoiceFailure?> start({
    required String language,
    required void Function(VoiceHeard heard) onHeard,
    required void Function(VoiceFailure failure) onFailure,
  }) async {
    askedFor = language;
    if (opening != null) await opening!.future;
    if (failWith != null) return failWith;
    _onHeard = onHeard;
    listening = true;
    return null;
  }

  /// The engine reporting words, as it would while someone speaks.
  void say(String text, {bool done = false}) {
    _onHeard?.call(VoiceHeard(text, done: done));
    if (done) listening = false;
  }

  @override
  Future<void> stop() async {
    stops++;
    listening = false;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    listening = false;
  }
}

/// The button alone, with the text it hears collected for the test.
Widget _host(_FakeEngine engine, List<String> heard,
        {Locale locale = const Locale('en'), bool reduceMotion = true}) =>
    ProviderScope(
      overrides: <Override>[
        speechEngineProvider.overrideWithValue(engine),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            // The listening pulse never ends, so most tests turn motion off
            // and let the widget settle.
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: VoiceInputButton(
                onText: (String t, {required bool done}) =>
                    heard.add('$t${done ? ' (done)' : ''}'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('which language the device is asked to hear', () {
    const List<String> onPhone = <String>[
      'en_US',
      'en_GB',
      'ar_SA',
      'ar_DZ',
      'fr_FR',
    ];

    test('the variant spoken where the device is set comes first', () {
      expect(VoiceLocale.pick('ar', onPhone, systemLocale: 'fr_DZ'), 'ar_DZ');
      expect(VoiceLocale.pick('en', onPhone, systemLocale: 'en_GB'), 'en_GB');
    });

    test('with no match for the region, the first variant offered', () {
      expect(VoiceLocale.pick('ar', onPhone, systemLocale: 'en_US'), 'ar_SA');
      expect(VoiceLocale.pick('ar', onPhone), 'ar_SA');
    });

    test('a plain language with no region wins over a variant', () {
      expect(VoiceLocale.pick('ar', <String>['ar_SA', 'ar']), 'ar');
    });

    test('a language the device cannot hear leaves the choice to it', () {
      expect(VoiceLocale.pick('ja', onPhone), isNull);
      expect(VoiceLocale.pick('', onPhone), isNull);
    });

    test('dashes and case read the same as underscores', () {
      expect(VoiceLocale.pick('AR', <String>['ar-dz'], systemLocale: 'fr-DZ'),
          'ar-dz');
    });
  });

  group('the microphone button', () {
    testWidgets('a browser that cannot hear is given no button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(_FakeEngine(supported: false), <String>[]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    });

    testWidgets('the first tap explains itself before anything is heard',
        (WidgetTester tester) async {
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.voiceNoticeTitle), findsOneWidget);
      // Nothing listens until it is accepted.
      expect(engine.askedFor, isNull);

      await tester.tap(find.text(l.voiceNoticeOk));
      await tester.pumpAndSettle();
      expect(engine.askedFor, 'en');
    });

    testWidgets('turning the notice down listens to nothing',
        (WidgetTester tester) async {
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(engine.askedFor, isNull);
    });

    testWidgets('the notice is shown once, not on every entry',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.voiceNoticeTitle), findsNothing);
      expect(engine.askedFor, 'en');
    });

    testWidgets('words arrive as they are heard, and the final one is marked',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      final List<String> heard = <String>[];
      await tester.pumpWidget(_host(engine, heard));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      engine.say('coffee');
      engine.say('coffee 200', done: true);
      await tester.pumpAndSettle();
      expect(heard, <String>['coffee', 'coffee 200 (done)']);
      // Done: the button offers to listen again, not to stop.
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('the tap is answered before the microphone has opened',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final Completer<void> opening = Completer<void>();
      final _FakeEngine engine = _FakeEngine(opening: opening);
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.pumpAndSettle();
      expect(tester.widget<Icon>(find.byType(Icon)).color,
          DsColors.light.textMuted);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      // Starting up: the button has changed colour, so the tap did not go
      // unanswered, and a second tap cannot stop what has not started.
      expect(
          tester.widget<Icon>(find.byType(Icon)).color, DsColors.light.brand);
      expect(
          tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);

      opening.complete();
      await tester.pumpAndSettle();
      expect(engine.listening, isTrue);
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    });

    testWidgets('while listening the button stops instead of starting again',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pumpAndSettle();
      expect(engine.stops, 1);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('closing the sheet mid-sentence stops the microphone',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(engine.cancels, 1);
    });

    testWidgets('no permission: it says so and stops offering the microphone',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      await tester.pumpWidget(
          _host(_FakeEngine(failWith: VoiceFailure.denied), <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.voiceFailedDenied), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    });

    testWidgets('hearing nothing says so but keeps the microphone',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      await tester.pumpWidget(
          _host(_FakeEngine(failWith: VoiceFailure.noSpeech), <String>[]));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.voiceFailedNoSpeech), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('it pulses while listening, and holds still when asked to',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      await tester.pumpWidget(_host(engine, <String>[], reduceMotion: false));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The microphone fades in and out while it hears.
      expect(
          find.descendant(
              of: find.byType(VoiceInputButton),
              matching: find.byType(FadeTransition)),
          findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);

      // Stopping ends it, so nothing keeps pulsing off screen.
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
          find.descendant(
              of: find.byType(VoiceInputButton),
              matching: find.byType(FadeTransition)),
          findsNothing);
    });

    testWidgets('the app language is what the device is asked to hear',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{VoiceInputButton.prefKey: true});
      final _FakeEngine engine = _FakeEngine();
      await tester
          .pumpWidget(_host(engine, <String>[], locale: const Locale('ar')));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      expect(engine.askedFor, 'ar');
    });
  });

  test('every language tells the user what happens to the sound', () {
    final List<LegalSection> en =
        LegalContent.sections(LegalDoc.privacy, lang: AppLang.en);
    final int at =
        en.indexWhere((LegalSection s) => s.heading == 'Voice entry');
    expect(at, greaterThan(0), reason: 'no voice section in English');

    for (final AppLang lang in AppLang.values) {
      final List<LegalSection> privacy =
          LegalContent.sections(LegalDoc.privacy, lang: lang);
      expect(privacy.length, en.length, reason: 'section count ${lang.code}');
      final LegalSection voice = privacy[at];
      expect(voice.heading.trim(), isNotEmpty, reason: lang.code);
      expect(voice.body, contains('SmartBudget'), reason: lang.code);
      // It must say what becomes of the sound, not just that it is handy.
      expect(voice.body.length, greaterThan(120), reason: lang.code);
    }
  });
}
