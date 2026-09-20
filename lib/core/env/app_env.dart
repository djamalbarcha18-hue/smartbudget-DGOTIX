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

  /// Public base URL of the owner's Market Intelligence proxy (a Supabase Edge
  /// Function or similar). This is NON-SECRET (a plain URL). The proxy holds the
  /// provider API keys server-side and picks the data provider — the OWNER
  /// configures the provider there, never the end user, and no key ever ships
  /// in the frontend. Injected at build time, e.g.:
  ///   --dart-define=MARKET_API_URL=https://xxx.functions.supabase.co/market-proxy
  static const String marketApiUrl =
      String.fromEnvironment('MARKET_API_URL', defaultValue: '');

  /// True when a market proxy URL is configured; drives whether the commodity
  /// categories fetch live data or render "unavailable".
  static bool get hasMarketApi => marketApiUrl.isNotEmpty;

  /// Public base URL of the owner's Parallel-market proxy (a Supabase Edge
  /// Function or similar). Like [marketApiUrl] this is NON-SECRET: the owner
  /// chooses each country's parallel-rate source server-side, and no key ships
  /// in the frontend. Injected at build time, e.g.:
  ///   --dart-define=PARALLEL_API_URL=https://xxx.functions.supabase.co/parallel-proxy
  static const String parallelApiUrl =
      String.fromEnvironment('PARALLEL_API_URL', defaultValue: '');

  /// True when a parallel-market proxy URL is configured; drives whether the
  /// country parallel rows fetch live data or render "unavailable".
  static bool get hasParallelApi => parallelApiUrl.isNotEmpty;
}
