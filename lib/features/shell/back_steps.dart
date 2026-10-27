import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The phone's back button, one step at a time. Pages opened from the menu
/// replace each other (no stack to pop), so without this the back button
/// closed the app from any page. Each page opened is remembered and back
/// returns to the one before; with none left it goes home, and from home it
/// leaves at once, as Android apps do (the app stays in the background).
///
/// A page opened again takes the list back to it, so back never shows the
/// same page twice. Whatever is open over the page (the menu, a sheet, a
/// dialog) still closes first. The web keeps the browser's own back button.
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

  static const int _keep = 30;

  @override
  void didUpdateWidget(BackSteps old) {
    super.didUpdateWidget(old);
    final String now = widget.location;
    if (now == _visited.last) return; // going back lands here
    // Opened again: back to it, not a second copy.
    final int seen = _visited.indexOf(now);
    if (seen >= 0) {
      _visited.removeRange(seen + 1, _visited.length);
    } else {
      _visited.add(now);
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
    (widget.onExit ?? SystemNavigator.pop)();
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
