/// Talking to the referral functions in Supabase.
///
/// Every call is an RPC: the client has no insert, update or delete on the
/// referral tables (see supabase/referrals.sql), so it can neither invent a
/// referral count nor grant itself a reward. Nothing here throws — a referral
/// that cannot be read must never block the app, so a failure reads as
/// "nothing earned yet" and the next good answer corrects it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

/// How many people the invite has brought in, and how far along they are.
class ReferralProgress {
  const ReferralProgress({this.joined = 0, this.activated = 0});

  /// Accounts created from the invite.
  final int joined;

  /// Of those, the ones that confirmed their mailbox and started using it.
  /// This is the number the reward is counted on.
  final int activated;

  int get remaining {
    final int left = ReferralRewards.needed - activated;
    return left < 0 ? 0 : left;
  }

  bool get earned => activated >= ReferralRewards.needed;

  /// 0..1, for the progress bar.
  double get fraction {
    final double f = activated / ReferralRewards.needed;
    return f > 1 ? 1 : f;
  }

  static const ReferralProgress none = ReferralProgress();
}

class ReferralService {
  const ReferralService();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  bool get _ready =>
      AppEnv.hasSupabase && (_client.auth.currentUser?.id.isNotEmpty ?? false);

  /// This member's invite code, made on the server the first time it is asked
  /// for. Null when signed out or unreachable.
  Future<String?> code() async {
    if (!_ready) return null;
    try {
      final Object? res = await _client.rpc<Object?>('my_referral_code');
      final String code = '${res ?? ''}';
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }

  /// Records who invited this (new) account. Safe to call more than once: the
  /// server keeps the first answer and ignores the rest.
  Future<bool> claim(String code) async {
    if (!_ready || code.trim().isEmpty) return false;
    try {
      final Object? res = await _client
          .rpc<Object?>('claim_referral', params: <String, dynamic>{
        'p_code': code.trim().toUpperCase(),
      });
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Tells the server this account is up and running, which is what counts
  /// towards the inviter's reward. The server checks the mailbox was
  /// confirmed before it believes it.
  Future<bool> complete() async {
    if (!_ready) return false;
    try {
      final Object? res = await _client.rpc<Object?>('complete_referral');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Counts only — the server never returns who was invited.
  Future<ReferralProgress> progress() async {
    if (!_ready) return ReferralProgress.none;
    try {
      final Object? res = await _client.rpc<Object?>('my_referral_progress');
      final Object? row = res is List && res.isNotEmpty ? res.first : res;
      if (row is! Map) return ReferralProgress.none;
      return ReferralProgress(
        joined: (row['joined'] as num?)?.toInt() ?? 0,
        activated: (row['activated'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return ReferralProgress.none;
    }
  }

  /// The rewards this account holds. An empty set is the safe answer: it
  /// locks nothing the plan already allows, it only withholds the extras.
  Future<Set<ReferralReward>> grants() async {
    if (!_ready) return const <ReferralReward>{};
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('reward_grants')
          .select('reward')
          .eq('user_id', _client.auth.currentUser!.id);
      return <ReferralReward>{
        for (final Map<String, dynamic> row in rows)
          if (ReferralReward.byId('${row['reward']}')
              case final ReferralReward r)
            r,
      };
    } catch (_) {
      return const <ReferralReward>{};
    }
  }
}

final referralServiceProvider =
    Provider<ReferralService>((Ref ref) => const ReferralService());
