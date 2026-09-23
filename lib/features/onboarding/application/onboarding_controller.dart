import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';

/// Persisted onboarding flags. `null` until loaded from storage, so the welcome
/// card never flashes for someone who already dismissed it.
final onboardingFlagsProvider =
    NotifierProvider<OnboardingController, OnboardingFlags?>(
        OnboardingController.new);

class OnboardingController extends Notifier<OnboardingFlags?> {
  static const String _key = 'sb_onboarding';

  @override
  OnboardingFlags? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    OnboardingFlags flags = const OnboardingFlags();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        flags = OnboardingFlags.fromJson(
            (jsonDecode(raw) as Map).cast<String, dynamic>());
      }
    } catch (_) {
      // Corrupt/unavailable storage ⇒ start fresh.
    }
    state = flags;
  }

  void dismiss() => _update((OnboardingFlags f) => f.copyWith(dismissed: true));
  void markSettingsVisited() =>
      _update((OnboardingFlags f) => f.copyWith(visitedSettings: true));
  void markGuideVisited() =>
      _update((OnboardingFlags f) => f.copyWith(visitedGuide: true));

  /// Bring the welcome card back (e.g. from the user guide).
  void reopen() => _update((OnboardingFlags f) => f.copyWith(dismissed: false));

  void _update(OnboardingFlags Function(OnboardingFlags) change) {
    final OnboardingFlags next = change(state ?? const OnboardingFlags());
    state = next;
    _persist(next);
  }

  Future<void> _persist(OnboardingFlags f) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(f.toJson()));
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The checklist, or null while flags or data are still loading (so nothing
/// is shown half-computed).
final onboardingStepsProvider = Provider<List<OnboardingStep>?>((ref) {
  final OnboardingFlags? flags = ref.watch(onboardingFlagsProvider);
  final int? txCount = ref.watch(transactionsProvider).valueOrNull?.length;
  final int? budgetCount = ref.watch(budgetsProvider).valueOrNull?.length;
  final int? goalCount = ref.watch(goalsProvider).valueOrNull?.length;
  if (flags == null ||
      txCount == null ||
      budgetCount == null ||
      goalCount == null) {
    return null;
  }
  return buildOnboardingSteps(
    visitedSettings: flags.visitedSettings,
    visitedGuide: flags.visitedGuide,
    hasTransaction: txCount > 0,
    hasBudget: budgetCount > 0,
    hasGoal: goalCount > 0,
  );
});
