/// Restarts the app from scratch in place (used after erasing local data on
/// mobile, where there is no page to reload). `main` registers how.
abstract final class AppRestart {
  static Future<void> Function()? _handler;

  static void register(Future<void> Function() handler) => _handler = handler;

  static Future<void> run() async => _handler?.call();
}
