import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class FinancialHealthPage extends ConsumerWidget {
  const FinancialHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool hasData = ref.watch(healthHasDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.pageFinancialHealth,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.xl),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.x5l),
              child: DsEmpty(
                title: l.pageFinancialHealth,
                message: l.healthEmpty,
                icon: Icons.monitor_heart_outlined,
              ),
            )
          else
            const _HealthBody(),
        ],
      ),
    );
  }
}

class _HealthBody extends ConsumerWidget {
  const _HealthBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final HealthResult result = ref.watch(healthResultProvider);
    final Color scoreColor = _scoreColor(context, result.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GlassCard(
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: (result.score / 100).clamp(0.0, 1.0),
                        strokeWidth: 9,
                        backgroundColor: context.dsColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Text(
                      result.score.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DsSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.healthScore,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(result.status, l),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scoreColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('${result.score.toStringAsFixed(1)} / 100',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DsSpacing.xxl),
        Text(l.healthIndicators,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: DsSpacing.md),
        for (final HealthIndicator ind in result.indicators)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.md),
            child: _IndicatorRow(indicator: ind),
          ),
      ],
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.indicator});
  final HealthIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final Color color = _scoreColor(context, indicator.score);

    return GlassCard(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(_indicatorName(indicator.key, l),
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Text('${l.healthWeight} ${MoneyFormatter.percent(indicator.weight, decimals: 0)}',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: DsSpacing.md),
              Text(
                indicator.score.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (indicator.score / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

Color _scoreColor(BuildContext context, double score) {
  final DsColors c = context.dsColors;
  if (score >= 75) return c.income;
  if (score >= 50) return c.warning;
  return c.expense;
}

String _statusLabel(HealthStatus s, AppLocalizations l) => switch (s) {
      HealthStatus.excellent => l.healthStatusExcellent,
      HealthStatus.veryGood => l.healthStatusVeryGood,
      HealthStatus.good => l.healthStatusGood,
      HealthStatus.fair => l.healthStatusFair,
      HealthStatus.needsWork => l.healthStatusNeedsWork,
    };

String _indicatorName(HealthIndicatorKey k, AppLocalizations l) => switch (k) {
      HealthIndicatorKey.cashFlow => l.hCashFlow,
      HealthIndicatorKey.savings => l.hSavings,
      HealthIndicatorKey.expense => l.hExpense,
      HealthIndicatorKey.debt => l.hDebt,
      HealthIndicatorKey.goals => l.hGoals,
      HealthIndicatorKey.budget => l.hBudget,
      HealthIndicatorKey.incomeStability => l.hIncomeStability,
    };
