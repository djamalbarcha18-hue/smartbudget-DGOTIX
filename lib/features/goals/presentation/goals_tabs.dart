import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "My goals" | "Funding plan": the two faces of Financial goals (the plan
/// is the projects portfolio, one tap away instead of its own menu item).
class GoalsTabs extends StatelessWidget {
  const GoalsTabs({super.key, required this.plan});

  /// On the funding plan (else the goals list).
  final bool plan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: <ButtonSegment<bool>>[
          ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(l.goalsTabMine)),
          ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.stacked_line_chart_rounded, size: 18),
              label: Text(l.goalsTabPlan)),
        ],
        selected: <bool>{plan},
        onSelectionChanged: (Set<bool> v) =>
            context.go(v.first ? '/portfolio' : '/goals'),
      ),
    );
  }
}
