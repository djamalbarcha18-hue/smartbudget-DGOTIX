import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';

/// What identifies an error without saying anything about the person: the
/// kind of error and the place in the app's own code where it happened. The
/// error's MESSAGE is never used (it can quote what the user typed), nor the
/// stack's arguments.
abstract final class ErrorSignature {
  static final RegExp _appFrame =
      RegExp(r'package:smartbudget/([\w/\.]+\.dart):(\d+)');
  // A released web build has no Dart frames, only the script's (the build id
  // pins which build the line belongs to).
  static final RegExp _scriptFrame = RegExp(r'([\w\.\-]+\.js):(\d+):(\d+)');

  static String of(Object error, StackTrace? stack) {
    final String type =
        error.runtimeType.toString().replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    final String text = stack?.toString() ?? '';
    final RegExpMatch? app = _appFrame.firstMatch(text);
    final RegExpMatch? js = app == null ? _scriptFrame.firstMatch(text) : null;
    final String where = app != null
        ? '@${app.group(1)}:${app.group(2)}'
        : js != null
            ? '@${js.group(1)}:${js.group(2)}:${js.group(3)}'
            : '';
    final String s = '${type.isEmpty ? 'Error' : type}$where';
    return s.length > 120 ? s.substring(0, 120) : s;
  }
}

/// Sends an error's signature to the server (which adds one to that day's
/// count of it).
typedef ErrorSender = Future<void> Function(String signature);

/// Notes every uncaught error and, when reports are on, sends its signature:
/// each signature once per session, and at most [perSessionCap] of them, so a
/// loop of failures can never flood the server or the user's data plan.
class ErrorReporter {
  ErrorReporter({this.send, this.perSessionCap = 10});

  final ErrorSender? send;
  final int perSessionCap;
  final Set<String> _sent = <String>{};

  /// The last signatures seen in this session (newest last), for support.
  final List<String> recent = <String>[];

  void record(Object error, StackTrace? stack) {
    try {
      final String sig = ErrorSignature.of(error, stack);
      recent.add(sig);
      if (recent.length > 20) recent.removeAt(0);
      final ErrorSender? s = send;
      if (s == null || _sent.length >= perSessionCap || !_sent.add(sig)) return;
      s(sig).catchError((Object _) {});
    } catch (_) {
      // Reporting an error must never be an error.
    }
  }
}

/// Hooks Flutter's and the platform's last-resort error handlers to
/// [reporter]. Errors still reach the console in debug builds; in release a
/// stray async error no longer ends silently without a trace.
void installErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    reporter.record(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
    reporter.record(error, stack);
    return true;
  };
}

/// Whether the user lets the app send anonymous error reports (on unless
/// turned off in Settings > Privacy).
final errorReportsOnProvider = NotifierProvider<ErrorReportsOnController, bool>(
    ErrorReportsOnController.new);

class ErrorReportsOnController extends Notifier<bool> {
  static const String key = 'sb_error_reports';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final bool? v = (await SharedPreferences.getInstance()).getBool(key);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(key, on);
    } catch (_) {}
  }
}

/// The real sender, or null (nothing leaves the device) while reports are off
/// ([AppEnv.errorReports]), without a backend, or in debug builds.
ErrorSender? defaultErrorSender() {
  if (!AppEnv.errorReports || !AppEnv.hasSupabase || kDebugMode) return null;
  return (String signature) async {
    final bool? on = (await SharedPreferences.getInstance())
        .getBool(ErrorReportsOnController.key);
    if (on == false) return;
    await Supabase.instance.client
        .rpc<void>('report_error', params: <String, dynamic>{
      'sig': signature,
      'app_version': AppConfig.version,
      'app_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    });
  };
}
