import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/billing/domain/plan.dart';

/// Why a checkout couldn't start. [notConfigured] means the owner hasn't wired
/// the payment provider yet — the UI treats that as "billing coming soon".
enum CheckoutError { notConfigured, unknownPrice, provider, network }

/// The result of asking the server to start a checkout: either a URL to open or
/// a reason it couldn't.
class CheckoutStart {
  const CheckoutStart._({this.url, this.error});
  final String? url;
  final CheckoutError? error;

  factory CheckoutStart.ready(String url) => CheckoutStart._(url: url);
  factory CheckoutStart.failed(CheckoutError e) => CheckoutStart._(error: e);

  bool get ok => url != null;
}

/// Asks the `create-checkout` Edge Function for a hosted checkout URL. All
/// provider keys stay on the server; the client only ever receives a URL to
/// open. Never throws to the UI.
class CheckoutService {
  const CheckoutService();

  Future<CheckoutStart> start({
    required Plan plan,
    required BillingPeriod period,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'plan': plan.storageId,
      'period': period == BillingPeriod.yearly ? 'yearly' : 'monthly',
    };
    try {
      final FunctionResponse res = await Supabase.instance.client.functions
          .invoke('create-checkout', body: body);
      final Object? data = res.data;
      if (data is Map && data['url'] is String) {
        return CheckoutStart.ready(data['url'] as String);
      }
      final Object? err = data is Map ? data['error'] : null;
      return CheckoutStart.failed(_map(err?.toString()));
    } on FunctionException catch (e) {
      final Object? details = e.details;
      final Object? err = details is Map ? details['error'] : null;
      return CheckoutStart.failed(_map(err?.toString()));
    } catch (_) {
      return CheckoutStart.failed(CheckoutError.network);
    }
  }

  CheckoutError _map(String? code) => switch (code) {
        'not_configured' => CheckoutError.notConfigured,
        'unknown_price' || 'invalid_plan' => CheckoutError.unknownPrice,
        'provider_error' || 'no_checkout_url' => CheckoutError.provider,
        _ => CheckoutError.network,
      };
}

final checkoutServiceProvider =
    Provider<CheckoutService>((_) => const CheckoutService());
