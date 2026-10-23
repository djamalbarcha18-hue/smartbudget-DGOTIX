import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_editor_sheet.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/features/trips/presentation/trip_widgets.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The home screen's trip card: the trip closest in time, in one of three
/// states set by its dates (planning, under way, summary ready). With no such
/// trip, a small "New trip" button instead.
class TripHomeCard extends ConsumerWidget {
  const TripHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final List<Trip> trips =
        ref.watch(tripsProvider).valueOrNull ?? const <Trip>[];
    final Trip? trip = TripDashboard.pick(trips, now);

    if (trip == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          icon: const Icon(Icons.flight_takeoff_outlined, size: 18),
          label: Text(l.tripNew),
          onPressed: () => TripEditorSheet.show(context),
        ),
      );
    }

    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final TripReport r = TripReport.of(trip, txns, now,
        currency: ref.watch(baseCurrencyProvider));
    final bool masked = MoneyPrivacy.maybeOf(context)?.masked ?? false;
    String money(Money m) =>
        masked ? MoneyPrivacy.mask : MoneyFormatter.format(m);
    final TripStatus status = TripMath.status(trip, now);
    final String place = catalog.display(trip.destination, appLangOf(context));

    final (String phase, Color phaseColor) = switch (status) {
      TripStatus.upcoming => (l.tripPhasePlanning, c.brand),
      TripStatus.active => (l.tripPhaseOngoing, c.income),
      TripStatus.ended => (l.tripPhaseDone, c.warning),
    };

    final List<Widget> body = switch (status) {
      TripStatus.upcoming => _planning(context, ref, l, c, t, trip, r, money),
      TripStatus.active =>
        _ongoing(context, l, c, t, trip, r, now, txns, money),
      TripStatus.ended => _done(context, l, c, t, trip, r, money),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DestinationAvatar(
                  destination: catalog.byText(trip.destination), size: 44),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(phase,
                        style: t.labelMedium?.copyWith(
                            color: phaseColor, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(trip.name,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(place,
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              if (status == TripStatus.upcoming)
                TripChip(
                    text: l.tripInDays(TripMath.daysUntil(trip, now)),
                    color: c.brand)
              else if (status == TripStatus.active)
                TripChip(
                    text: l.tripDayOf(
                        TripDays.dayNumber(trip, now), TripDays.total(trip)),
                    color: c.income),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          ...body,
        ],
      ),
    );
  }

  // ---- Planning -----------------------------------------------------------

  List<Widget> _planning(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    DsColors c,
    TextTheme t,
    Trip trip,
    TripReport r,
    String Function(Money) money,
  ) {
    if (!r.hasBudget) {
      // No budget: no bars, only what was spent so far (bookings…).
      return <Widget>[
        TripStat(
            label: '${l.tripSpent} · ${l.tripExpenseCount(r.expenseCount)}',
            value: money(r.spent)),
      ];
    }
    final List<Goal> goals =
        ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    Goal? goal;
    for (final Goal g in goals) {
      if (g.id == trip.goalId) goal = g;
    }
    if (goal == null) {
      return <Widget>[
        TripStat(label: l.tripBudget, value: money(r.budget!)),
        const SizedBox(height: DsSpacing.md),
        DsButton(
          label: l.tripStartSaving,
          icon: Icons.savings_outlined,
          variant: DsButtonVariant.secondary,
          onPressed: () => _startSaving(context, ref, l, trip),
        ),
      ];
    }
    final int target = goal.target.minorUnits;
    final bool reached = goal.saved.minorUnits >= target;
    final Money? monthly =
        TripDashboard.monthlyNeeded(goal, trip, AppClock.now());
    return <Widget>[
      Text(l.tripGoalProgress(money(goal.saved), money(goal.target)),
          style: t.bodySmall),
      const SizedBox(height: DsSpacing.sm),
      TripBar(
          value: target == 0 ? 0 : goal.saved.minorUnits / target,
          color: reached ? c.income : c.brand),
      if (reached || monthly != null) ...<Widget>[
        const SizedBox(height: DsSpacing.sm),
        Text(
          reached ? l.tripGoalReached : l.tripMonthlyNeeded(money(monthly!)),
          style: t.bodySmall?.copyWith(color: reached ? c.income : c.textMuted),
        ),
      ],
    ];
  }

  Future<void> _startSaving(BuildContext context, WidgetRef ref,
      AppLocalizations l, Trip trip) async {
    if (!PlanLimits.allowAdd(
        context,
        Feature.goals,
        (ProviderContainer c) =>
            c.read(goalsProvider).valueOrNull?.length ?? 0)) {
      return;
    }
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    await ref.read(tripActionsProvider).startSaving(trip);
    messenger?.showSnackBar(SnackBar(content: Text(l.tripGoalCreated)));
  }

  // ---- Under way ----------------------------------------------------------

  List<Widget> _ongoing(
    BuildContext context,
    AppLocalizations l,
    DsColors c,
    TextTheme t,
    Trip trip,
    TripReport r,
    DateTime now,
    List<Transaction> txns,
    String Function(Money) money,
  ) {
    final Money today = TripDashboard.spentOn(trip, txns, now, r.currency);
    final Money? perDay = TripDashboard.dailyAvailable(r, now);
    return <Widget>[
      if (r.hasBudget) ...<Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(l.tripSpent,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
            ),
            Text(l.tripSpentOfBudget(money(r.spent), money(r.budget!)),
                style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: r.overBudget ? c.expense : null)),
          ],
        ),
        const SizedBox(height: DsSpacing.sm),
        TripBar(
            value: r.usedRatio!, color: r.overBudget ? c.expense : c.income),
        const SizedBox(height: DsSpacing.md),
      ],
      Row(
        children: <Widget>[
          Expanded(
            child: r.hasBudget
                ? TripStat(
                    label: l.tripDailyAvailable,
                    value: r.overBudget ? l.tripOverBudget : money(perDay!),
                    color: r.overBudget ? c.expense : c.income,
                  )
                : TripStat(label: l.tripSpent, value: money(r.spent)),
          ),
          Expanded(child: TripStat(label: l.tripToday, value: money(today))),
        ],
      ),
      const SizedBox(height: DsSpacing.md),
      DsButton(
        label: l.tripAddExpense,
        icon: Icons.add_rounded,
        onPressed: () => TransactionEditorSheet.show(context,
            type: TransactionType.expense,
            prefill: TransactionDraft(tripId: trip.id)),
      ),
    ];
  }

  // ---- Ended --------------------------------------------------------------

  List<Widget> _done(
    BuildContext context,
    AppLocalizations l,
    DsColors c,
    TextTheme t,
    Trip trip,
    TripReport r,
    String Function(Money) money,
  ) {
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
              child: TripStat(label: l.tripTotalSpent, value: money(r.spent))),
          Expanded(
              child: TripStat(
                  label: l.tripDailyAverage, value: money(r.dailyAverage))),
        ],
      ),
      if (r.hasBudget) ...<Widget>[
        const SizedBox(height: DsSpacing.md),
        Text(
          r.underBudget
              ? l.tripSavedPct(r.savedPct!)
              : r.overBudget
                  ? l.tripOverPct(r.overPct!)
                  : l.tripUsedPct(100),
          style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: r.overBudget ? c.expense : c.income),
        ),
      ],
      const SizedBox(height: DsSpacing.md),
      DsButton(
        label: l.tripViewSummary,
        icon: Icons.insights_outlined,
        variant: DsButtonVariant.secondary,
        onPressed: () => context.push('/trips/${trip.id}'),
      ),
    ];
  }
}
