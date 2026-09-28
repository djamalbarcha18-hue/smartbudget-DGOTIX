import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/app_lock/data/device_auth.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';

enum AccountDeletionResult { deleted, activeSubscription, failed }

final accountDeletionProvider =
    Provider<AccountDeletion>((ref) => AccountDeletion(ref));

/// "Delete my account" (required by Google Play and the App Store): the
/// server account and everything stored for it, then all app data on this
/// device, then a fresh start.
class AccountDeletion {
  AccountDeletion(this._ref);
  final Ref _ref;

  Future<AccountDeletionResult> deleteAccount() async {
    final String userId = _ref.read(authControllerProvider).user?.id ?? 'guest';

    if (AppEnv.hasSupabase && userId != 'guest') {
      final String? error = await _deleteOnServer();
      if (error == 'active_subscription') {
        return AccountDeletionResult.activeSubscription;
      }
      if (error != null) return AccountDeletionResult.failed;
    }

    await wipeLocal(await SharedPreferences.getInstance());
    try {
      await _ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {
      // The account is already gone on the server.
    }
    reloadApp();
    return AccountDeletionResult.deleted;
  }

  /// Null when deleted, otherwise the server's error code.
  Future<String?> _deleteOnServer() async {
    try {
      final FunctionResponse res =
          await Supabase.instance.client.functions.invoke('delete-account');
      final Object? data = res.data;
      if (data is Map && data['deleted'] == true) return null;
      return (data is Map ? data['error'] : null)?.toString() ?? 'failed';
    } on FunctionException catch (e) {
      final Object? details = e.details;
      return (details is Map ? details['error'] : null)?.toString() ?? 'failed';
    } catch (_) {
      return 'network';
    }
  }

  /// Erases everything the app stored on this device. Some personal data
  /// (AI chat, zakat inputs, custom categories…) isn't keyed per user, so
  /// nothing less guarantees none of it is left behind.
  static Future<void> wipeLocal(SharedPreferences prefs) => prefs.clear();
}
