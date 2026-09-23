import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Posts due recurring transactions while the signed-in app is open: once on
/// start, whenever the rules change, and hourly so a tab left open overnight
/// still posts the next day's items. Invisible; wraps the routed page.
///
/// A failure here is swallowed: recurring posting must never get in the way of
/// the rest of the app.
class RecurringAutoPoster extends ConsumerStatefulWidget {
  const RecurringAutoPoster({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RecurringAutoPoster> createState() =>
      _RecurringAutoPosterState();
}

class _RecurringAutoPosterState extends ConsumerState<RecurringAutoPoster> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fires on the first load and after every change to the rules.
    ref.listenManual<AsyncValue<List<RecurringRule>>>(
      recurringRulesProvider,
      (_, AsyncValue<List<RecurringRule>> next) {
        if (next.hasValue) _post();
      },
      fireImmediately: true,
    );
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _post());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _post() async {
    try {
      final int added = await ref.read(recurringActionsProvider).postDue();
      if (added > 0 && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).recurringPosted(added)),
        ));
      }
    } catch (_) {
      // Never block the app on recurring posting; the next trigger retries.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
