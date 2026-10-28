import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// How long the free PRO trial lasts (set by `start_pro_trial` in
/// supabase/launch_offers.sql; shown in the offer text).
const int kProTrialDays = 14;

enum TrialError { used, paid, network }

/// The answer to starting a trial: when it ends, or why it didn't start.
class TrialStart {
  const TrialStart.ok(DateTime this.endsAt) : error = null;
  const TrialStart.failed(TrialError this.error) : endsAt = null;

  final DateTime? endsAt;
  final TrialError? error;

  bool get ok => endsAt != null;
}

/// Starts the signed-in account's one free PRO trial on the server, which
/// decides: once per account, never for one that pays.
class TrialService {
  const TrialService();

  Future<TrialStart> start() async {
    try {
      final Object? ends =
          await sb.Supabase.instance.client.rpc('start_pro_trial');
      final DateTime? at = DateTime.tryParse('$ends');
      return at == null
          ? const TrialStart.failed(TrialError.network)
          : TrialStart.ok(at);
    } on sb.PostgrestException catch (e) {
      return TrialStart.failed(errorFrom(e.message));
    } catch (_) {
      return const TrialStart.failed(TrialError.network);
    }
  }

  /// The server's refusal, from its message.
  static TrialError errorFrom(String message) {
    if (message.contains('trial_used')) return TrialError.used;
    if (message.contains('already_paid')) return TrialError.paid;
    return TrialError.network;
  }
}

final trialServiceProvider =
    Provider<TrialService>((_) => const TrialService());
