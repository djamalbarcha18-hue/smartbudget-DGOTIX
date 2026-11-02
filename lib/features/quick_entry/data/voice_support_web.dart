import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether this browser has the Web Speech API at all (Chrome and Edge do;
/// Firefox does not). Asked before the microphone is offered, so a browser
/// that can't hear is never given a button that would fail.
bool browserHearsSpeech() =>
    globalContext.has('SpeechRecognition') ||
    globalContext.has('webkitSpeechRecognition');
