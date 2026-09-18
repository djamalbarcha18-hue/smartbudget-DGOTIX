/// Compile-time environment configuration.
///
/// Secrets are NEVER hardcoded or committed. They are injected at build time via
/// `--dart-define` (or `--dart-define-from-file`). When no Supabase project is
/// configured, the app falls back to a local fake backend so it runs and can be
/// tested immediately — with zero credentials.
///
/// Example:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
abstract final class AppEnv {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True only when a real Supabase project is configured. Drives which
  /// [AuthRepository] implementation the app binds at startup.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Human-readable backend label (for diagnostics / settings screen).
  static String get backendLabel => hasSupabase ? 'Supabase' : 'Local (dev)';
}
