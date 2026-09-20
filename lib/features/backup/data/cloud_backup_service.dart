import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Failure kinds surfaced to the UI without leaking the Supabase SDK.
enum CloudBackupErrorKind { notSignedIn, network, unknown }

class CloudBackupException implements Exception {
  const CloudBackupException(this.kind, [this.message]);
  final CloudBackupErrorKind kind;
  final String? message;

  @override
  String toString() => 'CloudBackupException($kind, $message)';
}

/// Lightweight metadata about the stored cloud snapshot (no payload).
class CloudBackupMeta {
  const CloudBackupMeta({required this.updatedAt, required this.schemaVersion});
  final DateTime updatedAt;
  final int schemaVersion;
}

/// Reads/writes the signed-in user's single backup row in Supabase.
///
/// Access is guarded server-side by Row Level Security (see
/// supabase/cloud_backup.sql): a user can only touch their own row. The client
/// never holds a service-role key. Methods must only be called when Supabase is
/// configured and a user is signed in (the providers gate this).
class CloudBackupService {
  const CloudBackupService();

  static const String _table = 'user_backups';

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw const CloudBackupException(CloudBackupErrorKind.notSignedIn);
    }
    return id;
  }

  /// Returns metadata about the stored snapshot, or null if none exists yet.
  Future<CloudBackupMeta?> fetchMeta() async {
    return _guard(() async {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('schema_version, updated_at')
          .eq('user_id', _uid)
          .maybeSingle();
      if (row == null) return null;
      final DateTime? updated = DateTime.tryParse('${row['updated_at']}');
      if (updated == null) return null;
      return CloudBackupMeta(
        updatedAt: updated,
        schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Downloads the stored backup JSON map, or null if the user has none.
  Future<Map<String, dynamic>?> pull() async {
    return _guard(() async {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('data')
          .eq('user_id', _uid)
          .maybeSingle();
      final Object? data = row?['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return null;
    });
  }

  /// Uploads (upserts) the snapshot for the current user and returns its meta.
  Future<CloudBackupMeta> push(
    Map<String, dynamic> data,
    int schemaVersion,
  ) async {
    return _guard(() async {
      final DateTime now = DateTime.now().toUtc();
      await _client.from(_table).upsert(
        <String, dynamic>{
          'user_id': _uid,
          'data': data,
          'schema_version': schemaVersion,
          'updated_at': now.toIso8601String(),
        },
        onConflict: 'user_id',
      );
      return CloudBackupMeta(updatedAt: now, schemaVersion: schemaVersion);
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on CloudBackupException {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw CloudBackupException(CloudBackupErrorKind.unknown, e.message);
    } catch (_) {
      throw const CloudBackupException(CloudBackupErrorKind.network);
    }
  }
}
