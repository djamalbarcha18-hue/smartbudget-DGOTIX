import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_reminder.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Last full backup and any snooze of the reminder, stored on this device for
/// each account.
class BackupStatus {
  const BackupStatus({this.lastBackup, this.snoozedUntil});
  final DateTime? lastBackup;
  final DateTime? snoozedUntil;
}

/// `null` until loaded, so the dashboard reminder never flashes.
final backupStatusProvider =
    NotifierProvider<BackupStatusController, BackupStatus?>(
        BackupStatusController.new);

class BackupStatusController extends Notifier<BackupStatus?> {
  static const String _baseLast = 'sb_last_backup';
  static const String _baseSnooze = 'sb_backup_snooze';
  String _kLast = '';
  String _kSnooze = '';

  @override
  BackupStatus? build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _kLast = AccountKeys.of(_baseLast, account);
    _kSnooze = AccountKeys.of(_baseSnooze, account);
    _load(account);
    return null;
  }

  Future<void> _load(String? account) async {
    BackupStatus s = const BackupStatus();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await AccountKeys.open(p, _baseSnooze, account);
      if (await AccountKeys.open(p, _baseLast, account) != _kLast) {
        return; // another account signed in meanwhile
      }
      s = BackupStatus(
        lastBackup: DateTime.tryParse(p.getString(_kLast) ?? ''),
        snoozedUntil: DateTime.tryParse(p.getString(_kSnooze) ?? ''),
      );
    } catch (_) {
      // Unavailable storage ⇒ treat as never backed up.
    }
    state = s;
  }

  /// Call after a FULL backup succeeded (JSON export or cloud backup).
  Future<void> markBackedUp() async {
    final DateTime now = AppClock.now();
    state = BackupStatus(lastBackup: now);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_kLast, now.toIso8601String());
      await p.remove(_kSnooze);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Hide the reminder for [BackupReminder.snoozeDays] days.
  Future<void> snooze() async {
    final DateTime until =
        AppClock.now().add(const Duration(days: BackupReminder.snoozeDays));
    state = BackupStatus(lastBackup: state?.lastBackup, snoozedUntil: until);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_kSnooze, until.toIso8601String());
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// Whether the dashboard should show the backup reminder right now.
final backupReminderDueProvider = Provider<bool>((ref) {
  final BackupStatus? status = ref.watch(backupStatusProvider);
  final List<Transaction>? txns = ref.watch(transactionsProvider).valueOrNull;
  if (status == null || txns == null || txns.isEmpty) return false;
  DateTime oldest = txns.first.createdAt;
  for (final Transaction t in txns) {
    if (t.createdAt.isBefore(oldest)) oldest = t.createdAt;
  }
  return BackupReminder.isDue(
    now: AppClock.now(),
    lastBackup: status.lastBackup,
    oldestData: oldest,
    snoozedUntil: status.snoozedUntil,
  );
});
