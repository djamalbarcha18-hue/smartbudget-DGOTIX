import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
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
    final HealthReport r = ref.watch(healthReportProvider);
    final Color scoreColor = _scoreColor(context, r.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ---- Score hero: circle + status + confidence/resilience + trend ----
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ScoreRing(score: r.score, color: scoreColor),
                  const SizedBox(width: DsSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.healthScore,
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(_statusLabel(r.status, l),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: scoreColor)),
                        const SizedBox(height: 4),
                        Text('${r.score.toStringAsFixed(1)} / 100',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: DsSpacing.sm),
                        _TrendChip(trend: r.trend),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MiniStat(
                      label: l.healthConfidence,
                      value: '${r.confidence.toStringAsFixed(0)}%',
                      color: _confColor(context, r.confidence),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: _MiniStat(
                      label: l.healthResilience,
                      value: '${r.resilience.toStringAsFixed(0)}/100',
                      color: _scoreColor(context, r.resilience),
                    ),
                  ),
                ],
              ),
              if (r.confidence < 80) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                Text(l.healthPartialData,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: context.dsColors.textFaint)),
              ],
            ],
          ),
        ),

        // ---- Critical risks ----
        if (r.risks.isNotEmpty) ...<Widget>[
          const SizedBox(height: DsSpacing.lg),
          _RisksCard(risks: r.risks),
        ],

        // ---- Strengths & needs-improvement ----
        if (r.strengths.isNotEmpty || r.weaknesses.isNotEmpty) ...<Widget>[
          const SizedBox(height: DsSpacing.lg),
          _ChipsCard(
            strengths: r.strengths,
            weaknesses: r.weaknesses,
          ),
        ],

        // ---- Emergency fund / resilience input ----
        const SizedBox(height: DsSpacing.lg),
        _EmergencyCard(coverage: r.emergencyMonths),

        // ---- Dimensions (pillars) ----
        const SizedBox(height: DsSpacing.xxl),
        Text(l.healthDimensions,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: DsSpacing.md),
        for (final HealthPillar p in r.pillars)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.md),
            child: _PillarRow(pillar: p),
          ),

        // ---- Recommendations ----
        if (_recs(r).isNotEmpty) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          _RecommendationsCard(keys: _recs(r)),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------------------
// Pieces
// --------------------------------------------------------------------------

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});
  final double score;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 9,
              backgroundColor: context.dsColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(color: c.textFaint)),
          const SizedBox(height: 2),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});
  final HealthTrend trend;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final (String, IconData, Color) d = switch (trend) {
      HealthTrend.improving =>
        (l.healthTrendImproving, Icons.trending_up_rounded, c.income),
      HealthTrend.stable =>
        (l.healthTrendStable, Icons.trending_flat_rounded, c.textMuted),
      HealthTrend.declining =>
        (l.healthTrendDeclining, Icons.trending_down_rounded, c.expense),
      HealthTrend.unknown =>
        (l.healthTrendUnknown, Icons.horizontal_rule_rounded, c.textFaint),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(d.$2, size: 15, color: d.$3),
        const SizedBox(width: 4),
        Text('${l.healthTrend}: ${d.$1}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: d.$3)),
      ],
    );
  }
}

class _RisksCard extends StatelessWidget {
  const _RisksCard({required this.risks});
  final List<HealthRisk> risks;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 18, color: c.expense),
              const SizedBox(width: DsSpacing.sm),
              Text(l.healthRisks,
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          for (final HealthRisk risk in risks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.circle, size: 7, color: c.expense),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(_riskMsg(risk, l),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: c.textPrimary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({required this.strengths, required this.weaknesses});
  final List<HealthPillarKey> strengths;
  final List<HealthPillarKey> weaknesses;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (strengths.isNotEmpty) ...<Widget>[
            _ChipGroup(
              title: l.healthStrengths,
              color: c.income,
              icon: Icons.check_circle_outline_rounded,
              keys: strengths,
            ),
          ],
          if (strengths.isNotEmpty && weaknesses.isNotEmpty)
            const SizedBox(height: DsSpacing.md),
          if (weaknesses.isNotEmpty)
            _ChipGroup(
              title: l.healthWeaknesses,
              color: c.warning,
              icon: Icons.trending_up_rounded,
              keys: weaknesses,
            ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup(
      {required this.title,
      required this.color,
      required this.icon,
      required this.keys});
  final String title;
  final Color color;
  final IconData icon;
  final List<HealthPillarKey> keys;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: DsSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: DsSpacing.sm),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            for (final HealthPillarKey k in keys)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_pillarName(k, l),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color)),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmergencyCard extends ConsumerStatefulWidget {
  const _EmergencyCard({required this.coverage});
  final double? coverage;
  @override
  ConsumerState<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends ConsumerState<_EmergencyCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final double? v = ref.read(emergencySavingsProvider);
    _ctrl = TextEditingController(text: v == null ? '' : v.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply() {
    final String s = _ctrl.text.trim().replaceAll(',', '.');
    ref.read(emergencySavingsProvider.notifier).set(double.tryParse(s));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.healthEmergencyTitle,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.healthEmergencyHint,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.healthEmergencyTitle,
                    filled: true,
                    fillColor: c.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.brand),
                    ),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              TextButton(onPressed: _apply, child: Text(l.save)),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            children: <Widget>[
              Icon(
                  widget.coverage == null
                      ? Icons.info_outline_rounded
                      : (widget.coverage! >= 3
                          ? Icons.verified_outlined
                          : Icons.error_outline_rounded),
                  size: 16,
                  color: widget.coverage == null
                      ? c.textMuted
                      : (widget.coverage! >= 3 ? c.income : c.warning)),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  widget.coverage == null
                      ? l.healthEmergencyUnknown
                      : l.healthEmergencyCoverage(
                          widget.coverage!.toStringAsFixed(1)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  const _PillarRow({required this.pillar});
  final HealthPillar pillar;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool avail = pillar.available;
    final Color color = avail ? _scoreColor(context, pillar.score) : c.textFaint;

    return GlassCard(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(_pillarName(pillar.key, l),
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(
                  '${l.healthWeight} ${(pillar.weight * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: DsSpacing.md),
              Text(
                avail ? pillar.score.toStringAsFixed(0) : '—',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: avail ? (pillar.score / 100).clamp(0.0, 1.0) : 0,
              minHeight: 7,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (!avail) ...<Widget>[
            const SizedBox(height: 4),
            Text(l.healthUnavailable,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: c.textFaint)),
          ],
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.keys});
  final List<String> keys;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tips_and_updates_outlined, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Text(l.healthRecommendations,
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          for (final String k in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.arrow_forward_rounded, size: 14, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(_recText(k, l),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Helpers
// --------------------------------------------------------------------------

Color _scoreColor(BuildContext context, double score) {
  final DsColors c = context.dsColors;
  if (score >= 70) return c.income;
  if (score >= 45) return c.warning;
  return c.expense;
}

Color _confColor(BuildContext context, double conf) {
  final DsColors c = context.dsColors;
  if (conf >= 80) return c.income;
  if (conf >= 55) return c.warning;
  return c.expense;
}

String _statusLabel(HealthStatus s, AppLocalizations l) => switch (s) {
      HealthStatus.excellent => l.healthStatusExcellent,
      HealthStatus.veryGood => l.healthStatusVeryGood,
      HealthStatus.good => l.healthStatusGood,
      HealthStatus.fair => l.healthStatusFair,
      HealthStatus.needsWork => l.healthStatusNeedsWork,
    };

String _pillarName(HealthPillarKey k, AppLocalizations l) => switch (k) {
      HealthPillarKey.cashFlow => l.hCashFlow,
      HealthPillarKey.savings => l.hSavings,
      HealthPillarKey.resilience => l.hResilience,
      HealthPillarKey.debt => l.hDebt,
      HealthPillarKey.incomeStability => l.hIncomeStability,
      HealthPillarKey.planning => l.hPlanning,
    };

String _riskMsg(HealthRisk r, AppLocalizations l) => switch (r.kind) {
      RiskKind.negativeCashFlow => l.riskNegativeCashFlow,
      RiskKind.spendingExceedsIncome => l.riskSpendingExceedsIncome,
      RiskKind.highDebtService => l.riskHighDebtService,
      RiskKind.highDebtToIncome => l.riskHighDebtToIncome,
      RiskKind.noEmergencyBuffer => l.riskNoEmergencyBuffer,
      RiskKind.incomeInstability => l.riskIncomeInstability,
    };

String _recText(String key, AppLocalizations l) => switch (key) {
      'resilience' => l.recResilience,
      'cashFlow' => l.recCashFlow,
      'savings' => l.recSavings,
      'debt' => l.recDebt,
      'incomeStability' => l.recIncomeStability,
      'planning' => l.recPlanning,
      _ => '',
    };

List<String> _recs(HealthReport r) {
  final List<String> out = <String>[];
  void add(String k) {
    if (!out.contains(k)) out.add(k);
  }

  // Risks first (most urgent), then weaknesses.
  for (final HealthRisk risk in r.risks) {
    switch (risk.kind) {
      case RiskKind.noEmergencyBuffer:
        add('resilience');
      case RiskKind.negativeCashFlow:
      case RiskKind.spendingExceedsIncome:
        add('cashFlow');
      case RiskKind.highDebtService:
      case RiskKind.highDebtToIncome:
        add('debt');
      case RiskKind.incomeInstability:
        add('incomeStability');
    }
  }
  for (final HealthPillarKey k in r.weaknesses) {
    add(k.name);
  }
  if (r.emergencyMonths == null) add('resilience');
  return out.take(4).toList();
}
