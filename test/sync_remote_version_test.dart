import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/sync/data/sync_remote.dart';

/// The unversioned fallback skips the conflict check, so it must only be taken
/// when the database really lacks the `version` column.
void main() {
  bool missing(String? code, String message) =>
      SupabaseSyncRemote.isMissingVersionColumn(code, message);

  test('Postgres: the version column does not exist', () {
    expect(
        missing('42703', 'column user_backups.version does not exist'), isTrue);
    expect(missing('42703', 'column "version" does not exist'), isTrue);
  });

  test('PostgREST: the version column is not in the schema cache', () {
    expect(
        missing('PGRST204',
            "Could not find the 'version' column of 'user_backups' in the schema cache"),
        isTrue);
  });

  test('another missing column is not the version column', () {
    expect(missing('42703', 'column user_backups.schema_version does not exist'),
        isFalse);
    expect(missing('42703', 'column user_backups.data does not exist'), isFalse);
  });

  test('any other error mentioning "version" is rethrown, not swallowed', () {
    expect(missing('23505', 'duplicate key, version 3 already exists'), isFalse);
    expect(missing('P0001', 'version conflict'), isFalse);
    expect(missing(null, 'unsupported client version'), isFalse);
    expect(missing('PGRST301', 'JWT expired (version 2)'), isFalse);
  });
}
