import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/kpi_grid.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/debts/application/debt_totals_mode.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/debts/presentation/debt_editor_sheet.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/sync/presentation/page_skeleton.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final DebtSummary summary = ref.watch(debtSummaryProvider);
    final AsyncValue<List<Debt>> async = ref.watch(debtsProvider);
    final String base = ref.watch(baseCurrencyProvider);
    final List<CurrencyPosition> positions = ref.watch(debtPositionsProvider);
    // The choice only matters when debts are in more than one currency.
    final bool mixed = positions.any((CurrencyPosition p) => p.code != base);
    final bool perCurrency = mixed &&
        ref.watch(debtTotalsModeProvider) == DebtTotalsMode.perCurrency;

    final Widget addBtn = DsButton(
      label: l.addDebt,
      icon: Icons.add_rounded,
      onPressed: () => DebtEditorSheet.show(context),
    );

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (context.isMobile) ...<Widget>[
            Text(l.navDebts, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DsSpacing.md),
            addBtn,
          ] else
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(l.navDebts,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                addBtn,
              ],
            ),
          const SizedBox(height: DsSpacing.lg),
          if (mixed) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DebtTotalsMode>(
                showSelectedIcon: false,
                segments: <ButtonSegment<DebtTotalsMode>>[
                  ButtonSegment<DebtTotalsMode>(
                      value: DebtTotalsMode.converted,
                      label: Text(l.debtTotalsInBase)),
                  ButtonSegment<DebtTotalsMode>(
                      value: DebtTotalsMode.perCurrency,
                      label: Text(l.debtTotalsByCurrency)),
                ],
                selected: <DebtTotalsMode>{
                  perCurrency
                      ? DebtTotalsMode.perCurrency
                      : DebtTotalsMode.converted,
                },
                onSelectionChanged: (Set<DebtTotalsMode> v) =>
                    ref.read(debtTotalsModeProvider.notifier).set(v.first),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
          ],
          if (perCurrency)
            // One row per currency, nothing converted. Past a handful of
            // currencies the table scrolls rather than push the debts away.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: _CurrencyPositionsTable(positions: positions),
              ),
            )
          else ...<Widget>[
            KpiGrid(
              children: <Widget>[
                KpiCard(
                  label: l.debtOwedToMe,
                  value: MoneyFormatter.format(summary.owedToMe),
                  icon: Icons.call_received_rounded,
                  accent: c.income,
                ),
                KpiCard(
                  label: l.debtOwedByMe,
                  value: MoneyFormatter.format(summary.owedByMe),
                  icon: Icons.call_made_rounded,
                  accent: c.expense,
                ),
                KpiCard(
                  label: l.debtNet,
                  value: MoneyFormatter.format(summary.net),
                  icon: Icons.balance_rounded,
                  accent: c.net,
                ),
              ],
            ),
            // Debts in another currency are counted at today's rate, and a
            // currency with no rate yet is named, never dropped without a word.
            if (summary.convertedCount > 0) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              Text(l.walletTotalAtRates,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.textMuted)),
            ],
            if (summary.missingRateCodes.isNotEmpty) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              Text(l.walletMissingRate(summary.missingRateCodes.join(', ')),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.expense)),
            ],
          ],
          const SizedBox(height: DsSpacing.lg),
          Expanded(
            child: AsyncListBody<Debt>(
              value: async,
              onRetry: () => ref.invalidate(debtsProvider),
              skeleton: const DsSkeletonList(
                  count: 5, gap: DsSpacing.sm, framed: true),
              data: (List<Debt> debts) => debts.isEmpty
                  ? DsEmpty(
                      title: l.emptyDebtsTitle,
                      message: l.emptyDebtsMessage,
                      icon: Icons.account_balance_outlined,
                    )
                  : ListView.separated(
                      itemCount: debts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DsSpacing.sm),
                      itemBuilder: (BuildContext context, int i) =>
                          _DebtTile(debt: debts[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  const _DebtTile({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final DebtStatus status = DebtCalculator.status(debt);
    final Color typeColor = debt.isLent ? c.income : c.expense;
    // A debt in another currency shows what is left in its own currency, and
    // roughly what that is in the base currency when a rate is known.
    final String base = ref.watch(baseCurrencyProvider);
    final bool apart =
        ref.watch(debtTotalsModeProvider) == DebtTotalsMode.perCurrency;
    final Money? inBase = debt.original.currencyCode == base || apart
        ? null
        : DebtCalculator.inBase(
            DebtCalculator.remaining(debt), base, ref.watch(ratesProvider));

    return Material(
      color: c.surface,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => DebtEditorSheet.show(context, existing: debt),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  debt.isLent
                      ? Icons.call_received_rounded
                      : Icons.call_made_rounded,
                  color: typeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      debt.party,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    MoneyFormatter.format(DebtCalculator.remaining(debt)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (inBase != null)
                    Text('≈ ${MoneyFormatter.format(inBase)}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: c.textMuted)),
                  Text(l.debtRemaining,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await DebtEditorSheet.show(context, existing: debt);
                  } else if (v == 'delete') {
                    await ref.read(debtActionsProvider).delete(debt.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What is owed, one row per currency: lent, borrowed and the balance, as
/// they are and with nothing converted. The column titles are written once.
class _CurrencyPositionsTable extends StatelessWidget {
  const _CurrencyPositionsTable({required this.positions});
  final List<CurrencyPosition> positions;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    const double codeWidth = 68;

    Widget head(String label) => Expanded(
          child: Text(label,
              style: t.labelSmall?.copyWith(color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        );

    Widget value(Money m, Color color) => Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              MoneyFormatter.format(m),
              style: t.titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md, vertical: DsSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: codeWidth),
              head(l.debtOwedToMe),
              const SizedBox(width: DsSpacing.sm),
              head(l.debtOwedByMe),
              const SizedBox(width: DsSpacing.sm),
              head(l.legendNet),
            ],
          ),
          Divider(height: DsSpacing.md, color: c.border),
          for (final CurrencyPosition p in positions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: codeWidth,
                    child: Row(
                      children: <Widget>[
                        CurrencyFlag(Currencies.byCode(p.code), width: 18),
                        const SizedBox(width: 6),
                        Text(p.code, style: t.titleSmall),
                      ],
                    ),
                  ),
                  value(p.owedToMe, c.income),
                  const SizedBox(width: DsSpacing.sm),
                  value(p.owedByMe, c.expense),
                  const SizedBox(width: DsSpacing.sm),
                  value(p.net, c.net),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final (String, DsBadgeTone) data = switch (status) {
      DebtStatus.paid => (l.debtStatusPaid, DsBadgeTone.income),
      DebtStatus.partiallyPaid => (l.debtStatusPartial, DsBadgeTone.warning),
      DebtStatus.overdue => (l.debtStatusOverdue, DsBadgeTone.expense),
      DebtStatus.active => (l.debtStatusActive, DsBadgeTone.saving),
    };
    return DsBadge(label: data.$1, tone: data.$2);
  }
}
