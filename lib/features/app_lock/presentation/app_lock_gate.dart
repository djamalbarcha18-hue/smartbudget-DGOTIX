import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/presentation/lock_screen.dart';
import 'package:smartbudget/features/app_lock/data/secure_screen.dart';

/// Covers the whole app with the lock screen while locked, and re-locks after
/// the app has spent the chosen time in the background.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => ref.read(appLockProvider.notifier).onHidden(),
    onShow: () => ref.read(appLockProvider.notifier).onShown(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    SecureScreen.set(ref.read(appLockProvider).config.enabled);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
        appLockProvider.select((AppLockState s) => s.config.enabled),
        (bool? _, bool on) => SecureScreen.set(on));
    final bool locked = ref.watch(appLockProvider.select((AppLockState s) => s.locked));
    return Stack(
      children: <Widget>[
        ExcludeFocus(
          excluding: locked,
          child: ExcludeSemantics(excluding: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: _LockLayer()),
      ],
    );
  }
}

/// The lock screen gets its own Overlay: it sits above the app's Navigator.
class _LockLayer extends StatefulWidget {
  const _LockLayer();

  @override
  State<_LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<_LockLayer> {
  final OverlayEntry _entry =
      OverlayEntry(builder: (_) => const LockScreen(), opaque: true);

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entry]);
}
