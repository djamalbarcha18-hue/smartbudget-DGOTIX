/// Non-web stub for backup file IO. These are no-ops: the app ships to the web,
/// and this file only exists so the Dart VM (test runner) can compile.

/// Triggers a browser "save file" download. No-op off the web.
Future<void> downloadText({
  required String filename,
  required String text,
  required String mime,
}) async {}

/// Prompts the user to choose a file and returns its text. Always null off web.
Future<String?> pickTextFile() async => null;
