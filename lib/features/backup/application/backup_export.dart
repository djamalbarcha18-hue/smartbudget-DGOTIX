import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/backup/application/backup_controller.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';

String _stamp(DateTime n) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}';
}

/// Downloads a complete JSON backup and records it as the latest backup (which
/// resets the dashboard reminder). Shared by Settings and the reminder card.
Future<void> exportFullBackup(WidgetRef ref) async {
  final String json = await ref.read(backupServiceProvider).exportJson();
  await downloadText(
    filename: 'smartbudget-backup-${_stamp(DateTime.now())}.json',
    text: json,
    mime: 'application/json;charset=utf-8',
  );
  await ref.read(backupStatusProvider.notifier).markBackedUp();
}
