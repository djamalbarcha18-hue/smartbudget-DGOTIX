import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/core/env/app_env.dart';

/// The owner-entered parallel rates kept on the server (parallel_rates.sql):
/// everyone reads them; only an admin account can set them.
class OwnerRatesService {
  const OwnerRatesService();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  bool get _signedIn =>
      AppEnv.hasSupabase && (_client.auth.currentUser?.id.isNotEmpty ?? false);

  /// The stored rates of [country] as raw rows (currency, buy, sell,
  /// updated_at). Throws when the server can't be reached, so the caller can
  /// fall back to what it last saw.
  Future<List<dynamic>> fetch(String country) async {
    if (!AppEnv.hasSupabase) return const <dynamic>[];
    final Object? res = await _client.rpc<Object?>('parallel_rates_for',
        params: <String, dynamic>{'p_country': country});
    return res is List ? res : const <dynamic>[];
  }

  /// May this account edit the rates? False when signed out or unreachable.
  Future<bool> isAdmin() async {
    if (!_signedIn) return false;
    try {
      return await _client.rpc<Object?>('is_app_admin') == true;
    } catch (_) {
      return false;
    }
  }

  /// Sets one rate; both values null removes it. Throws when refused.
  Future<void> setRate(String country, String currency,
      {double? buy, double? sell}) async {
    await _client.rpc<Object?>('set_parallel_rate', params: <String, dynamic>{
      'p_country': country,
      'p_currency': currency,
      'p_buy': buy,
      'p_sell': sell,
    });
  }
}
