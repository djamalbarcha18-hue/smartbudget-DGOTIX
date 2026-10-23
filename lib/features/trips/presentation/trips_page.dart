import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/presentation/trip_editor_sheet.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// My trips: current and upcoming, then past.
class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<Trip> trips =
        ref.watch(tripsProvider).valueOrNull ?? const <Trip>[];
    final DateTime now = AppClock.now();
    final List<Trip> current = TripMath.current(trips, now);
    final List<Trip> past = TripMath.past(trips, now);

    final bool wide = !context.isMobile;
    Widget grid(List<Trip> items) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final int cols = wide && box.maxWidth > 760 ? 2 : 1;
            final double w = (box.maxWidth - DsSpacing.lg * (cols - 1)) / cols;
            return Wrap(
              spacing: DsSpacing.lg,
              runSpacing: DsSpacing.lg,
              children: <Widget>[
                for (final Trip x in items)
                  SizedBox(width: w, child: _TripCard(trip: x)),
              ],
            );
          },
        );
    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.md),
          child: Text(title,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: DsSpacing.md,
            spacing: DsSpacing.md,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.navTrips, style: t.headlineSmall),
                  const SizedBox(height: DsSpacing.xs),
                  Text(l.tripsSubtitle,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
              DsButton(
                label: l.tripNew,
                icon: Icons.add_rounded,
                onPressed: () => TripEditorSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xl),
          if (trips.isEmpty)
            DsEmpty(
              icon: Icons.flight_takeoff_outlined,
              title: l.tripsEmptyTitle,
              message: l.tripsEmptyBody,
            ),
          if (current.isNotEmpty) ...<Widget>[
            section(l.tripsCurrent),
            grid(current),
            const SizedBox(height: DsSpacing.xxl),
          ],
          if (past.isNotEmpty) ...<Widget>[
            section(l.tripsPast),
            grid(past),
          ],
        ],
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final Money? budget = trip.plannedBudget;
    final String currency =
        budget?.currencyCode ?? ref.watch(baseCurrencyProvider);
    final Money spent = TripMath.spent(trip, txns, currency);
    final int count = TripMath.expensesOf(trip, txns).length;
    final bool over = budget != null && spent.minorUnits > budget.minorUnits;
    final Color chipColor = tripStatusColor(c, trip, now);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(trip.name,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    // Place and dates on their own lines, so a place in
                    // another script never reorders the dates around it.
                    Text(catalog.display(trip.destination, appLangOf(context)),
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                    Text(tripDates(context, trip),
                        style: t.bodySmall?.copyWith(color: c.textFaint)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(tripStatusLabel(l, trip, now),
                    style: t.labelSmall?.copyWith(
                        color: chipColor, fontWeight: FontWeight.w700)),
              ),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await TripEditorSheet.show(context, existing: trip);
                  } else if (v == 'delete') {
                    await _confirmDelete(context, ref, l);
                  }
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('${l.tripSpent} · ${l.tripExpenseCount(count)}',
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
              ),
              Text(
                budget == null
                    ? MoneyFormatter.format(spent)
                    : '${MoneyFormatter.format(spent)} / ${MoneyFormatter.format(budget)}',
                style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: over ? c.expense : null),
              ),
            ],
          ),
          if (budget != null && budget.minorUnits > 0) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (spent.minorUnits / budget.minorUnits).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: c.surfaceMuted,
                valueColor:
                    AlwaysStoppedAnimation<Color>(over ? c.expense : c.income),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tripDeleteTitle),
        content: Text(l.tripDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(tripActionsProvider).delete(trip);
  }
}
