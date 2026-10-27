import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The phone's back button, one step at a time. Pages opened from the menu
/// replace each other (no stack to pop), so without this the back button
/// closed the app from any page. Each page opened is remembered and back
/// returns to the one before; with none left it goes home, and on the home
/// page a first press says how to leave, a second one (soon after) leaves.
///
/// Whatever is open over the page (the menu, a sheet, a dialog) still
/// closes first. The web keeps the browser's own back button.
class BackSteps extends StatefulWidget {
  const BackSteps({
    super.key,
    required this.location,
    required this.child,
    this.home = '/dashboard',
    this.onExit,
  });

  /// The page shown now (path and query).
  final String location;
  final Widget child;
  final String home;

  /// Leaves the app; tests pass their own.
  final VoidCallback? onExit;

  @override
  State<BackSteps> createState() => _BackStepsState();
}

class _BackStepsState extends State<BackSteps> {
  /// The pages opened, oldest first; the last is the one shown.
  late final List<String> _visited = <String>[widget.location];
  DateTime? _armedAt;

  static const int _keep = 30;
  static const Duration _exitWindow = Duration(seconds: 2);

  @override
  void didUpdateWidget(BackSteps old) {
    super.didUpdateWidget(old);
    // Going back lands on the page already last in the list.
    if (widget.location != _visited.last) {
      _visited.add(widget.location);
      if (_visited.length > _keep) _visited.removeAt(0);
    }
  }

  void _back() {
    // The menu (a drawer) open over the page: close it, nothing more.
    if (ModalRoute.of(context)?.willHandlePopInternally ?? false) {
      Navigator.of(context).pop();
      return;
    }
    if (_visited.length > 1) {
      _visited.removeLast();
      context.go(_visited.last);
      return;
    }
    if (Uri.parse(widget.location).path != widget.home) {
      _visited
        ..clear()
        ..add(widget.home);
      context.go(widget.home);
      return;
    }
    final DateTime now = DateTime.now();
    if (_armedAt != null && now.difference(_armedAt!) < _exitWindow) {
      (widget.onExit ?? SystemNavigator.pop)();
      return;
    }
    _armedAt = now;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).backAgainToExit),
        duration: _exitWindow,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _back();
      },
      child: widget.child,
    );
  }
}
