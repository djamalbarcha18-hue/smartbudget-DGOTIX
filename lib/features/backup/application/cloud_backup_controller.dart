import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/data/cloud_backup_service.dart';

/// The cloud-backup data service (bound only when Supabase is configured).
final cloudBackupServiceProvider =
    Provider<CloudBackupService>((ref) => const CloudBackupService());

/// Cloud backup is available only with a real backend AND a signed-in user.
final cloudBackupEnabledProvider = Provider<bool>((ref) =>
    AppEnv.hasSupabase && ref.watch(authControllerProvider).isAuthenticated);

/// Metadata about the user's stored cloud snapshot (null when disabled or none
/// exists yet). Invalidate after a successful push to refresh the timestamp.
final cloudBackupMetaProvider = FutureProvider<CloudBackupMeta?>((ref) async {
  if (!ref.watch(cloudBackupEnabledProvider)) return null;
  return ref.watch(cloudBackupServiceProvider).fetchMeta();
});
