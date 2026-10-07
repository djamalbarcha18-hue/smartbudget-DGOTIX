import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/settings/domain/base_currency_impact.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The one way the base (template) currency changes: confirm first, showing
/// which records would drop out of totals, then switch.
/// Returns true when the currency was changed.
Future<bool> changeBaseCurrency(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final String from = ref.read(baseCurrencyProvider);
  if (code == from) return false;

  Future<List<T>> all<T>(StreamProvider<List<T>> p) async {
    try {
      return await ref.read(p.future).timeout(const Duration(seconds: 2));
    } catch (_) {
      return <T>[];
    }
  }

  final BaseCurrencyImpact impact = BaseCurrencyImpact.of(
    from: from,
    to: code,
    transactions: await all(transactionsProvider),
    budgets: await all(budgetsProvider),
    goals: await all(goalsProvider),
    debts: await all(debtsProvider),
    projects: await all(projectsProvider),
    seasons: await all(seasonPlansProvider),
    darets: await all(daretsProvider),
    convertible: ref.read(fxStatusProvider).trusts,
  );
  if (!context.mounted) return false;

  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) =>
        _ConfirmDialog(from: from, to: code, impact: impact),
  );
  if (ok != true) return false;

  await ref.read(baseCurrencyProvider.notifier).set(code);
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).baseChangeDone(code)),
    ));
  }
  return true;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.from,
    required this.to,
    required this.impact,
  });

  final String from;
  final String to;
  final BaseCurrencyImpact impact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    final List<(String, int)> rows = <(String, int)>[
      (l.impactTransactions, impact.transactions),
      (l.impactBudgets, impact.budgets),
      (l.impactGoals, impact.goals),
      (l.impactDebts, impact.debts),
      (l.impactProjects, impact.projects),
      (l.impactSeasons, impact.seasons),
      (l.impactDarets, impact.darets),
    ].where(((String, int) r) => r.$2 > 0).toList();

    return AlertDialog(
      backgroundColor: c.bgElevated,
      title: Text(l.baseChangeTitle(to)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (impact.isEmpty)
              Text(l.baseChangeNoData(to), style: t.bodyMedium)
            else ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, size: 20, color: c.warning),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.baseChangeBody(from), style: t.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DsSpacing.md),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: DsRadius.brMd,
                ),
                child: Column(
                  children: <Widget>[
                    for (final (String, int) r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(r.$1, style: t.bodyMedium)),
                            Text('${r.$2}',
                                style: t.titleSmall
                                    ?.copyWith(color: c.textPrimary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              Text(l.baseChangeSafe(from),
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.baseChangeConfirm),
        ),
      ],
    );
  }
}
