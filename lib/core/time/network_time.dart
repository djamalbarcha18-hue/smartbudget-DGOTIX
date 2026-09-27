import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/core/time/http_date.dart';

/// Measures the device clock against world time using the `Date` header of a
/// tiny HEAD request to the site the app is served from: same-origin (so the
/// browser exposes the header), no third-party service, no API key. HEAD also
/// bypasses the Flutter service worker, which only caches GET.
class NetworkTime {
  NetworkTime({http.Client? client, Uri? origin})
      : _client = client ?? http.Client(),
        _origin = origin ?? Uri.base;

  final http.Client _client;
  final Uri _origin;

  static const Duration timeout = Duration(seconds: 4);

  /// Syncs [AppClock]. Returns false when there is no web origin (tests,
  /// non-web builds), no network, or no usable header — the clock then keeps
  /// its previous state (device time if it never synced).
  Future<bool> sync() async {
    if (_origin.scheme != 'http' && _origin.scheme != 'https') return false;
    final Uri target = _origin.resolve('version.json').replace(
        queryParameters: <String, String>{
          'clock': DateTime.now().microsecondsSinceEpoch.toString(),
        });
    try {
      final DateTime sentAt = DateTime.now();
      final http.Response r = await _client.head(target, headers:
          const <String, String>{'cache-control': 'no-cache'}).timeout(timeout);
      final DateTime receivedAt = DateTime.now();
      final DateTime? server = parseHttpDate(r.headers['date']);
      if (server == null) return false;
      AppClock.applyOffset(AppClock.measure(
          serverUtc: server, sentAt: sentAt, receivedAt: receivedAt));
      return true;
    } catch (_) {
      return false;
    }
  }
}
