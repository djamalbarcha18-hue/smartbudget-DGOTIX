import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/errors/error_reporter.dart';

void main() {
  group('signature: the kind and the place, never the message', () {
    test('the app\'s own frame gives file and line', () {
      final StackTrace st =
          StackTrace.fromString('#0 _throw (dart:core/x.dart:1)\n'
              '#1 save (package:smartbudget/features/budget/save.dart:42:7)\n'
              '#2 main (package:flutter/src/x.dart:9)');
      expect(ErrorSignature.of(const FormatException('secret 1234'), st),
          'FormatException@features/budget/save.dart:42');
    });

    test('the message and its data never appear', () {
      final String sig = ErrorSignature.of(
          StateError('user typed: my salary is 5000'), StackTrace.empty);
      expect(sig, 'StateError');
      expect(sig.contains('salary'), isFalse);
    });

    test('a released web build falls back to the script position', () {
      final StackTrace st =
          StackTrace.fromString('at Object.a (main.dart.js:1234:56)');
      expect(
          ErrorSignature.of(ArgumentError('x'), st)
              .endsWith('@main.dart.js:1234:56'),
          isTrue);
    });

    test('long or odd type names stay clean and capped', () {
      final String sig = ErrorSignature.of(_Weird<int>(), null);
      expect(RegExp(r'^[A-Za-z0-9_.:@/ -]{1,120}$').hasMatch(sig), isTrue);
    });
  });

  group('reporter', () {
    test('each signature is sent once per session', () async {
      final List<String> sent = <String>[];
      final ErrorReporter r =
          ErrorReporter(send: (String s) async => sent.add(s));
      for (int i = 0; i < 5; i++) {
        r.record(StateError('a'), StackTrace.empty);
      }
      r.record(ArgumentError('b'), StackTrace.empty);
      await Future<void>.delayed(Duration.zero);
      expect(sent, <String>['StateError', 'ArgumentError']);
    });

    test('a flood is capped per session', () async {
      final List<String> sent = <String>[];
      final ErrorReporter r = ErrorReporter(
          send: (String s) async => sent.add(s), perSessionCap: 3);
      for (int i = 0; i < 10; i++) {
        r.record(
            _Err('E'),
            StackTrace.fromString(
                '#0 f (package:smartbudget/features/x/y.dart:$i:1)'));
      }
      await Future<void>.delayed(Duration.zero);
      expect(sent.length, 3);
    });

    test('without a sender nothing leaves, but the last errors are kept', () {
      final ErrorReporter r = ErrorReporter();
      for (int i = 0; i < 25; i++) {
        r.record(_Err('E$i'), StackTrace.empty);
      }
      expect(r.recent.length, 20);
      expect(r.recent.last, '_Err');
    });

    test('a sender that fails is never an error', () async {
      final ErrorReporter r =
          ErrorReporter(send: (String s) async => throw StateError('offline'));
      r.record(StateError('x'), StackTrace.empty);
      await Future<void>.delayed(Duration.zero);
    });

    test('off in every build until the owner turns it on', () {
      // The default build flag is false, so no sender exists.
      expect(defaultErrorSender(), isNull);
    });
  });
}

class _Weird<T> implements Exception {}

class _Err implements Exception {
  _Err(this.id);
  final String id;
}
