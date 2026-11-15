import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/core/time/app_clock.dart';

/// The account's cloud copy as last downloaded.
class RemoteCopy {
  const RemoteCopy(
      {this.doc, this.version, this.versioned = true, this.owner});

  /// The signed-in user this copy was downloaded for. An upload based on it
  /// is refused when someone else is signed in by then (the account was
  /// switched mid-round): one account's data never goes to another's row.
  final String? owner;

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

  /// The cloud copy's version alone (a few bytes, not the whole document):
  /// null when the account has no copy yet or the database lacks the
  /// version column. Lets a device that has nothing new to send skip
  /// downloading a copy it already has.
  Future<int?> probe();

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
      isMissingVersionColumn(e.code, e.message);

  /// True only when the error says the `version` column itself is missing
  /// (an old database without the sync.sql migration). Postgres reports an
  /// unknown column as 42703 and PostgREST as PGRST204; both name the column.
  ///
  /// Any other error must be rethrown: falling back to the unversioned path
  /// skips the optimistic-concurrency check, and an unconditional upload can
  /// overwrite what another device just saved.
  @visibleForTesting
  static bool isMissingVersionColumn(String? code, String message) {
    if (code != '42703' && code != 'PGRST204') return false;
    return RegExp(r'''(^|[^a-z_])version([^a-z_]|$)''')
        .hasMatch(message.toLowerCase());
  }

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
        owner: _uid,
      );
    } on sb.PostgrestException catch (e) {
      if (!_noVersionColumn(e)) rethrow;
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('data')
          .eq('user_id', _uid)
          .maybeSingle();
      return RemoteCopy(
          doc: _map(row?['data']), versioned: false, owner: _uid);
    }
  }

  @override
  Future<int?> probe() async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('version')
          .eq('user_id', _uid)
          .maybeSingle();
      return (row?['version'] as num?)?.toInt();
    } on sb.PostgrestException catch (e) {
      if (_noVersionColumn(e)) return null;
      rethrow;
    }
  }

  @override
  Future<bool> push(Map<String, dynamic> doc, RemoteCopy base) async {
    if (base.owner != null && base.owner != _uid) {
      throw StateError('the account changed during sync');
    }
    final Map<String, dynamic> row = <String, dynamic>{
      'data': doc,
      'schema_version': 2,
      'updated_at': AppClock.now().toUtc().toIso8601String(),
    };
    if (!base.versioned) {
      await _client.from(_table).upsert(
          <String, dynamic>{'user_id': _uid, ...row},
          onConflict: 'user_id');
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
