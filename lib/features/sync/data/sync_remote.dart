import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/core/time/app_clock.dart';

/// The account's cloud copy as last downloaded.
class RemoteCopy {
  const RemoteCopy({this.doc, this.version, this.versioned = true});

  /// The stored document, or null when the account has none yet.
  final Map<String, dynamic>? doc;

  /// Its version (null: no copy yet).
  final int? version;

  /// False while the database lacks the version column (supabase/sync.sql
  /// not run): uploads then go without the conflict check.
  final bool versioned;
}

/// Where the sync document lives (one per account, RLS: own row only).
abstract interface class SyncRemote {
  Future<RemoteCopy> pull();

  /// Uploads [doc] over [base]; false when another device uploaded first
  /// (merge again and retry).
  Future<bool> push(Map<String, dynamic> doc, RemoteCopy base);
}

/// The Supabase table user_backups (supabase/cloud_backup.sql, sync.sql).
class SupabaseSyncRemote implements SyncRemote {
  const SupabaseSyncRemote();

  static const String _table = 'user_backups';

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) throw StateError('not signed in');
    return id;
  }

  static bool _noVersionColumn(sb.PostgrestException e) =>
      e.code == '42703' ||
      e.code == 'PGRST204' ||
      e.message.contains('version');

  @override
  Future<RemoteCopy> pull() async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('data, version')
          .eq('user_id', _uid)
          .maybeSingle();
      return RemoteCopy(
        doc: _map(row?['data']),
        version: row == null ? null : (row['version'] as num?)?.toInt() ?? 0,
      );
    } on sb.PostgrestException catch (e) {
      if (!_noVersionColumn(e)) rethrow;
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('data')
          .eq('user_id', _uid)
          .maybeSingle();
      return RemoteCopy(doc: _map(row?['data']), versioned: false);
    }
  }

  @override
  Future<bool> push(Map<String, dynamic> doc, RemoteCopy base) async {
    final Map<String, dynamic> row = <String, dynamic>{
      'data': doc,
      'schema_version': 2,
      'updated_at': AppClock.now().toUtc().toIso8601String(),
    };
    if (!base.versioned) {
      await _client
          .from(_table)
          .upsert(<String, dynamic>{'user_id': _uid, ...row}, onConflict: 'user_id');
      return true;
    }
    if (base.version == null) {
      try {
        await _client
            .from(_table)
            .insert(<String, dynamic>{'user_id': _uid, ...row, 'version': 1});
        return true;
      } on sb.PostgrestException catch (e) {
        if (e.code == '23505') return false; // another device created it
        rethrow;
      }
    }
    final List<dynamic> updated = await _client
        .from(_table)
        .update(<String, dynamic>{...row, 'version': base.version! + 1})
        .eq('user_id', _uid)
        .eq('version', base.version!)
        .select('version');
    return updated.isNotEmpty;
  }

  static Map<String, dynamic>? _map(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : null;
}

final syncRemoteProvider =
    Provider<SyncRemote>((_) => const SupabaseSyncRemote());
