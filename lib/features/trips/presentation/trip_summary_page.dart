import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_back_button.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_share_page.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/features/trips/presentation/trip_widgets.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What a trip cost: total, categories, budget, daily average — as real
/// values or, with the switch at the top, as percentages only.
class TripSummaryPage extends ConsumerWidget {
  const TripSummaryPage({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final AsyncValue<List<Trip>> all = ref.watch(tripsProvider);
    Trip? trip;
    for (final Trip x in all.valueOrNull ?? const <Trip>[]) {
      if (x.id == tripId) trip = x;
    }
    if (trip == null) {
      return all.isLoading
          ? const DsLoading()
          : DsEmpty(
              icon: Icons.flight_takeoff_outlined,
              title: l.tripsEmptyTitle,
              action: const DsBackButton(fallbackRoute: '/trips'),
            );
    }
    final Trip tr = trip;
    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final TripReport r = TripReport.of(tr, txns, AppClock.now(),
        currency: ref.watch(baseCurrencyProvider));
    final bool pct = ref.watch(tripPercentModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const DsBackButton(fallbackRoute: '/trips'),
              const SizedBox(width: DsSpacing.xs),
              Expanded(child: Text(l.tripSummaryTitle, style: t.headlineSmall)),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          TripValueToggle(percentOnly: pct),
          const SizedBox(height: DsSpacing.lg),
          ClipRRect(
            borderRadius: DsRadius.brLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Hero(
                    trip: tr,
                    report: r,
                    destination: catalog.byText(tr.destination)),
                if (r.hasExpenses)
                  _TotalPanel(report: r, percentOnly: pct)
                else
                  _NoExpenses(trip: tr),
              ],
            ),
          ),
          if (r.hasExpenses && r.hasBudget) ...<Widget>[
            const SizedBox(height: DsSpacing.lg),
            _BudgetPanel(report: r, percentOnly: pct),
          ],
          const SizedBox(height: DsSpacing.xl),
          DsButton(
            label: l.tripShare,
            icon: Icons.ios_share_rounded,
            expand: true,
            onPressed: r.hasExpenses
                ? () => TripSharePage.open(context, tripId: tr.id)
                : null,
          ),
        ],
      ),
    );
  }
}

/// "Real value" | "Percentage" (shared with the share card).
class TripValueToggle extends ConsumerWidget {
  const TripValueToggle({super.key, required this.percentOnly});
  final bool percentOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Tooltip(
      message: l.tripShowAs,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: <ButtonSegment<bool>>[
          ButtonSegment<bool>(value: false, label: Text(l.tripShowReal)),
          ButtonSegment<bool>(value: true, label: Text(l.tripShowPercent)),
        ],
        selected: <bool>{percentOnly},
        onSelectionChanged: (Set<bool> v) =>
            ref.read(tripPercentModeProvider.notifier).state = v.first,
      ),
    );
  }
}

/// The destination's picture (or its icon on a colour), its name, and the
/// days and travellers over it.
class _Hero extends StatelessWidget {
  const _Hero(
      {required this.trip, required this.report, required this.destination});
  final Trip trip;
  final TripReport report;
  final Destination? destination;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang = appLangOf(context);
    final String? image = destination?.image;
    const Color ink = Colors.white;
    final TextStyle meta = (t.bodySmall ?? const TextStyle())
        .copyWith(color: ink.withValues(alpha: 0.92));
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: Color.lerp(c.brand, Colors.black, 0.35)!),
          if (image != null)
            Image.asset(image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())
          else
            PositionedDirectional(
              end: DsSpacing.xl,
              top: DsSpacing.lg,
              child: Icon(destinationIcon(destination?.icon),
                  size: 110, color: ink.withValues(alpha: 0.16)),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x14000000), Color(0x99000000)],
              ),
            ),
          ),
          if (report.hasExpenses)
            PositionedDirectional(
              top: DsSpacing.md,
              start: DsSpacing.md,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: report.underBudget
                      ? c.income
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.underBudget
                      ? l.tripSavedPct(report.savedPct!)
                      : l.tripNiceTrip,
                  style: t.labelSmall
                      ?.copyWith(color: ink, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          PositionedDirectional(
            start: DsSpacing.lg,
            end: DsSpacing.lg,
            bottom: DsSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  destination?.nameFor(lang) ?? trip.destination,
                  style: t.headlineSmall
                      ?.copyWith(color: ink, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: DsSpacing.xs),
                Wrap(
                  spacing: DsSpacing.md,
                  runSpacing: DsSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _Meta(Icons.calendar_today_outlined,
                        l.tripDaysCount(TripDays.total(trip)), meta),
                    if (trip.travelers > 1)
                      _Meta(Icons.group_outlined,
                          l.tripTravelersCount(trip.travelers), meta),
                    _Meta(Icons.flight_takeoff_outlined, trip.name, meta),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, this.style);
  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: style.color),
          const SizedBox(width: DsSpacing.xs),
          Text(text, style: style),
        ],
      );
}

/// The total (with per person and per day), then the split by category.
class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.report, required this.percentOnly});
  final TripReport report;
  final bool percentOnly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final TripReport r = report;
    final AppLang lang = appLangOf(context);
    final NumberFormat percent =
        NumberFormat.percentPattern(Localizations.localeOf(context).toString());
    final TextStyle side =
        (t.bodySmall ?? const TextStyle()).copyWith(color: c.textMuted);

    final Widget headline;
    if (!percentOnly) {
      headline = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.tripTotalSpent, style: side),
                Text(MoneyFormatter.format(r.spent),
                    style: t.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (r.perPerson != null)
                Text(l.tripPerPerson(MoneyFormatter.format(r.perPerson!)),
                    style: side),
              Text(l.tripPerDay(MoneyFormatter.format(r.dailyAverage)),
                  style: side),
            ],
          ),
        ],
      );
    } else if (r.hasBudget) {
      headline = Text(l.tripUsedPct(r.usedPct!),
          style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: r.overBudget ? c.expense : null));
    } else {
      headline = Text(l.tripByCategory,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700));
    }

    return Container(
      color: c.surface,
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          headline,
          const SizedBox(height: DsSpacing.lg),
          TripSegmentBar(categories: r.categories, height: 12),
          const SizedBox(height: DsSpacing.md),
          for (int i = 0; i < r.categories.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  vertical: DsSpacing.xs + 2),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: DsChartPalette.at(i), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Icon(tripCategoryIcon(r.categories[i].category),
                      size: 20, color: c.textMuted),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(
                        Catalog.label(r.categories[i].category, lang: lang),
                        style: t.bodyMedium),
                  ),
                  Text(
                    percentOnly
                        ? percent.format(r.categories[i].share)
                        : MoneyFormatter.format(r.categories[i].amount),
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A bar split by category, in the chart colours.
class TripSegmentBar extends StatelessWidget {
  const TripSegmentBar(
      {super.key, required this.categories, this.height = 10, this.gap = 3});
  final List<TripCategoryShare> categories;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < categories.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                flex: (categories[i].share * 1000).round().clamp(1, 1000),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DsChartPalette.at(i),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Planned against actual, daily average, what was saved, biggest category.
class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.report, required this.percentOnly});
  final TripReport report;
  final bool percentOnly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final TripReport r = report;
    final AppLang lang = appLangOf(context);
    String money(Money m) => MoneyFormatter.format(m);
    final double scale = r.spent.minorUnits > r.budget!.minorUnits
        ? r.spent.minorUnits.toDouble()
        : r.budget!.minorUnits.toDouble();
    final TripCategoryShare? top = r.top;
    final Money diff = r.difference!;

    Widget bar(String label, String value, double ratio, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Text(label,
                        style: t.bodySmall?.copyWith(color: c.textMuted))),
                Text(value,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            TripBar(value: ratio, color: color),
          ],
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!percentOnly) ...<Widget>[
            Text(l.tripUsedPct(r.usedPct!),
                style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: r.overBudget ? c.expense : null)),
            const SizedBox(height: DsSpacing.md),
          ],
          bar(l.tripPlanned, percentOnly ? '100%' : money(r.budget!),
              r.budget!.minorUnits / scale, c.brand),
          const SizedBox(height: DsSpacing.sm),
          bar(l.tripActual, percentOnly ? '${r.usedPct}%' : money(r.spent),
              r.spent.minorUnits / scale, r.overBudget ? c.expense : c.income),
          const SizedBox(height: DsSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TripStat(
                  label: l.tripDailyAverage,
                  value: percentOnly
                      ? l.tripDailyPctOfBudget(r.dailyPctOfBudget!)
                      : money(r.dailyAverage),
                ),
              ),
              Expanded(
                child: TripStat(
                  label: r.overBudget ? l.tripOverBudget : l.tripSavedLabel,
                  value: percentOnly
                      ? '${r.overBudget ? r.overPct : (r.savedPct ?? 0)}%'
                      : money(r.overBudget ? r.spent - r.budget! : diff),
                  color: r.overBudget ? c.expense : c.income,
                ),
              ),
            ],
          ),
          if (top != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            TripStat(
              label: l.tripTopCategory,
              value:
                  '${Catalog.label(top.category, lang: lang)} · ${percentOnly ? l.tripPctOfTotal((top.share * 100).round()) : money(top.amount)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _NoExpenses extends StatelessWidget {
  const _NoExpenses({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: Column(
        children: <Widget>[
          Text(l.tripNoExpensesYet,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.tripAddExpense,
            icon: Icons.add_rounded,
            onPressed: () => TransactionEditorSheet.show(context,
                type: TransactionType.expense,
                prefill: TransactionDraft(tripId: trip.id)),
          ),
        ],
      ),
    );
  }
}
