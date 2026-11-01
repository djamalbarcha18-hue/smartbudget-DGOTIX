import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:smartbudget/features/quick_entry/data/voice_support_stub.dart'
    if (dart.library.js_interop) 'package:smartbudget/features/quick_entry/data/voice_support_web.dart'
    as support;
import 'package:smartbudget/features/quick_entry/domain/voice_locale.dart';

/// Why the microphone gave nothing back.
enum VoiceFailure {
  /// No speech engine on this device or browser.
  unavailable,

  /// The microphone permission was refused.
  denied,

  /// It listened but heard no words.
  noSpeech,

  /// Anything else (the engine stopped, no network for an online engine).
  failed,
}

/// Words heard so far. [done] marks the engine's final answer; everything
/// before it is a guess that can still change.
@immutable
class VoiceHeard {
  const VoiceHeard(this.text, {required this.done});
  final String text;
  final bool done;
}

/// The microphone, as the quick entry sheet needs it. An interface so the
/// sheet can be tested without a device engine.
abstract class SpeechEngine {
  /// Whether this build can offer a microphone at all. False in a browser
  /// without the Web Speech API, so no button is shown that would fail.
  bool get supported;

  bool get listening;

  /// Starts listening in [language] (an app language code such as 'ar'), or
  /// in the device's own language when it can't hear that one. Asks for the
  /// microphone permission the first time, so only call it on a deliberate
  /// tap. Returns the failure when it couldn't start, null when listening.
  Future<VoiceFailure?> start({
    required String language,
    required void Function(VoiceHeard heard) onHeard,
    required void Function(VoiceFailure failure) onFailure,
  });

  /// Stops listening and keeps what was heard.
  Future<void> stop();

  /// Stops listening and throws away what was heard.
  Future<void> cancel();
}

/// The real microphone: the engine built into Android, or the browser's.
///
/// The audio is handled by that engine, not by SmartBudget: the app receives
/// text, never a recording, and keeps neither. Most engines send the audio to
/// their maker's servers to turn it into words, exactly as the phone keyboard's
/// own microphone key does — the Privacy Policy says so, and the sheet says so
/// before the first use.
class DeviceSpeechEngine implements SpeechEngine {
  DeviceSpeechEngine({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _ready = false;

  /// How long a silence ends the listening, and the longest one turn can run.
  /// Short: a quick entry is a few words ("قهوة مئتين"), not a paragraph.
  static const Duration _pauseFor = Duration(seconds: 3);
  static const Duration _listenFor = Duration(seconds: 30);

  @override
  bool get supported => support.browserHearsSpeech();

  @override
  bool get listening => _speech.isListening;

  @override
  Future<VoiceFailure?> start({
    required String language,
    required void Function(VoiceHeard heard) onHeard,
    required void Function(VoiceFailure failure) onFailure,
  }) async {
    if (!supported) return VoiceFailure.unavailable;
    try {
      if (!_ready) {
        _ready = await _speech.initialize(
          onError: (SpeechRecognitionError e) =>
              onFailure(_failureOf(e.errorMsg)),
          // A permanent error ends the turn; the error listener above reports
          // it, so nothing is left listening in the background.
          onStatus: (_) {},
        );
      }
      if (!_ready) return VoiceFailure.denied;

      await _speech.listen(
        onResult: (SpeechRecognitionResult r) =>
            onHeard(VoiceHeard(r.recognizedWords, done: r.finalResult)),
        listenOptions: stt.SpeechListenOptions(
          localeId: await _localeFor(language),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          // Engines that can punctuate put a comma where the speaker pauses,
          // which is exactly where the parser separates one entry from the
          // next ("قهوة 200، خبز 150"). Ignored where unsupported.
          autoPunctuation: true,
          pauseFor: _pauseFor,
          listenFor: _listenFor,
        ),
      );
      return null;
    } catch (_) {
      // A device with no engine behind the plugin: treated as no microphone
      // rather than crashing the sheet.
      return VoiceFailure.unavailable;
    }
  }

  /// The device locale to listen in, or null to leave the choice to it.
  Future<String?> _localeFor(String language) async {
    try {
      final List<stt.LocaleName> have = await _speech.locales();
      return VoiceLocale.pick(
        language,
        have.map((stt.LocaleName l) => l.localeId).toList(),
        systemLocale: (await _speech.systemLocale())?.localeId,
      );
    } catch (_) {
      return null;
    }
  }

  static VoiceFailure _failureOf(String code) => switch (code) {
        'error_permission' ||
        'error_audio' ||
        'error_audio_error' =>
          VoiceFailure.denied,
        'error_no_match' || 'error_speech_timeout' => VoiceFailure.noSpeech,
        _ => VoiceFailure.failed,
      };

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Already stopped.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Already stopped.
    }
  }
}

/// The microphone the quick entry sheet uses; tests override it with a fake.
final speechEngineProvider =
    Provider<SpeechEngine>((Ref ref) => DeviceSpeechEngine());
