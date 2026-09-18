import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/debts/presentation/debt_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final DebtSummary summary = ref.watch(debtSummaryProvider);
    final AsyncValue<List<Debt>> async = ref.watch(debtsProvider);

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
          Wrap(
            spacing: DsSpacing.gridGap,
            runSpacing: DsSpacing.gridGap,
            children: <Widget>[
              SizedBox(
                width: 220,
                child: KpiCard(
                  label: l.debtOwedToMe,
                  value: MoneyFormatter.format(summary.owedToMe),
                  icon: Icons.call_received_rounded,
                  accent: c.income,
                ),
              ),
              SizedBox(
                width: 220,
                child: KpiCard(
                  label: l.debtOwedByMe,
                  value: MoneyFormatter.format(summary.owedByMe),
                  icon: Icons.call_made_rounded,
                  accent: c.expense,
                ),
              ),
              SizedBox(
                width: 220,
                child: KpiCard(
                  label: l.debtNet,
                  value: MoneyFormatter.format(summary.net),
                  icon: Icons.balance_rounded,
                  accent: c.net,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          Expanded(
            child: async.when(
              loading: () => const DsLoading(),
              error: (Object e, _) => DsError(message: e.toString()),
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
                  Text(l.debtRemaining,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
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
