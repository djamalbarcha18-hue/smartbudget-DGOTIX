import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// The build this app was compiled as (the web deploy passes the commit);
/// empty in other builds, which don't check for updates.
const String kBuildId = String.fromEnvironment('BUILD_ID');

/// Reads the build the site serves now from `build.json`, written next to
/// the app by the web deploy.
class AppUpdateChecker {
  AppUpdateChecker({http.Client? client, Uri? origin})
      : _client = client ?? http.Client(),
        _origin = origin ?? Uri.base;

  final http.Client _client;
  final Uri _origin;

  /// The deployed build id, or null when it can't be read.
  Future<String?> deployedBuild() async {
    if (_origin.scheme != 'http' && _origin.scheme != 'https') return null;
    final Uri target = _origin.resolve('build.json').replace(
        queryParameters: <String, String>{
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        });
    try {
      final http.Response r = await _client.get(target, headers:
          const <String, String>{'cache-control': 'no-cache'}).timeout(
          const Duration(seconds: 5));
      if (r.statusCode != 200) return null;
      final Object? json = jsonDecode(r.body);
      final Object? build = json is Map ? json['build'] : null;
      return build is String && build.isNotEmpty ? build : null;
    } catch (_) {
      return null;
    }
  }
}

final appUpdateCheckerProvider =
    Provider<AppUpdateChecker>((_) => AppUpdateChecker());

/// The running build's id; empty turns the check off (not the web app).
final runningBuildIdProvider =
    Provider<String>((_) => kIsWeb ? kBuildId : '');

/// True once the site serves a newer build than the one running. Checked
/// shortly after start, whenever the app comes back to the foreground (an
/// installed web app is often resumed, not reloaded), and every 30 minutes.
final appUpdateAvailableProvider =
    NotifierProvider<AppUpdateController, bool>(AppUpdateController.new);

class AppUpdateController extends Notifier<bool> {
  static const Duration firstCheck = Duration(seconds: 5);
  static const Duration every = Duration(minutes: 30);

  bool _disposed = false;
  bool _checking = false;

  @override
  bool build() {
    if (ref.watch(runningBuildIdProvider).isEmpty) return false;
    final Timer first = Timer(firstCheck, check);
    final Timer periodic = Timer.periodic(every, (_) => check());
    // Back in view (onShow) is enough: on the web, "resumed" also needs the
    // window to have focus, which a returning user may not give it yet.
    final AppLifecycleListener life =
        AppLifecycleListener(onShow: check, onResume: check);
    ref.onDispose(() {
      _disposed = true;
      first.cancel();
      periodic.cancel();
      life.dispose();
    });
    return false;
  }

  Future<void> check() async {
    if (_disposed || state || _checking) return;
    _checking = true;
    try {
      final String running = ref.read(runningBuildIdProvider);
      final String? live =
          await ref.read(appUpdateCheckerProvider).deployedBuild();
      if (_disposed) return;
      if (live != null && live != running) state = true;
    } finally {
      _checking = false;
    }
  }
}
