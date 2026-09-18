import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when a market data request fails (non-200, timeout, parse error).
class MarketFetchException implements Exception {
  MarketFetchException(this.message);
  final String message;
  @override
  String toString() => 'MarketFetchException: $message';
}

/// Minimal JSON GET helper for the markets data layer.
///
/// Only talks to keyless public endpoints (no secrets ever ship in the client).
/// On Flutter web this uses the browser Fetch API under the hood.
class MarketHttp {
  const MarketHttp({this.timeout = const Duration(seconds: 12)});
  final Duration timeout;

  Future<dynamic> getJson(Uri url) async {
    try {
      final http.Response resp = await http
          .get(url, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(timeout);
      if (resp.statusCode != 200) {
        throw MarketFetchException('HTTP ${resp.statusCode} from ${url.host}');
      }
      return jsonDecode(resp.body);
    } on MarketFetchException {
      rethrow;
    } catch (e) {
      throw MarketFetchException('${url.host}: $e');
    }
  }
}
