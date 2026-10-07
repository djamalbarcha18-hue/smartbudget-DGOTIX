import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has a network connection. A hint, not a promise (a
/// connection may still have no internet), so callers keep handling network
/// errors; it drives the offline banner and syncing on reconnect.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final Connectivity c = Connectivity();
  bool on(List<ConnectivityResult> r) =>
      r.any((ConnectivityResult x) => x != ConnectivityResult.none);
  yield on(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(on);
});

/// True only when the device reports no connection (unknown counts as online).
final isOfflineProvider =
    Provider<bool>((ref) => ref.watch(onlineProvider).valueOrNull == false);
