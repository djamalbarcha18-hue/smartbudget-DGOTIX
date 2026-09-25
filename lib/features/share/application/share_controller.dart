import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/share/domain/share_highlight.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';

final shareHighlightProvider = Provider<ShareHighlight>((ref) {
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  return ShareHighlight.pick(
    hasData: ref.watch(healthHasDataProvider),
    healthScore: ref.watch(healthResultProvider).score,
    savingsRate: ref.watch(financeSummaryProvider).savingsRate,
    goalsCompleted: goals
        .where((Goal g) => GoalCalculator.status(g) == GoalStatus.completed)
        .length,
  );
});
