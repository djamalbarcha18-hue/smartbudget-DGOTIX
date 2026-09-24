import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/salary_split/application/salary_split_controller.dart';
import 'package:smartbudget/features/salary_split/domain/salary_split.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Preview of a suggested salary split for the month selected on the budget
/// screen. The user can change the income; nothing is saved until "Apply".
class SalarySplitSheet extends ConsumerStatefulWidget {
  const SalarySplitSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SalarySplitSheet(),
    );
  }

  @override
  ConsumerState<SalarySplitSheet> createState() => _SalarySplitSheetState();
}

class _SalarySplitSheetState extends ConsumerState<SalarySplitSheet> {
  late final SplitInputs _inputs = ref.read(salarySplitInputsProvider);
  late final TextEditingController _income = TextEditingController(
      text: _inputs.defaultIncome.minorUnits > 0
          ? _fmtInput(_inputs.defaultIncome.asDouble)
          : '');
  bool _saving = false;

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  Money get _incomeMoney {
    final double v = double.tryParse(_income.text.trim()) ?? 0;
    return Money.fromDouble(
        v < 0 ? 0 : v, _inputs.defaultIncome.currencyCode);
  }

  Future<void> _apply(SalarySplit split) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final int n = await applySalarySplit(ref,
          split: split, year: _inputs.year, month: _inputs.month);
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.splitApplied(n))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final SalarySplit split = _inputs.splitFor(_incomeMoney);
    final String monthLabel =
        '${_inputs.year}-${_inputs.month.toString().padLeft(2, '0')}';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.call_split_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text('${l.splitTitle} · $monthLabel',
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),

              // Income to split (editable).
              Text(l.splitIncome,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.xs),
              TextField(
                controller: _income,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  const LatinDigitsFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '0',
                  suffixText: _inputs.defaultIncome.currencyCode,
                  filled: true,
                  fillColor: c.surfaceMuted,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DsRadius.brMd,
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: DsRadius.brMd,
                    borderSide: BorderSide(color: c.brand),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              _Note(
                icon: Icons.info_outline_rounded,
                color: c.textMuted,
                text: !split.hasIncome
                    ? l.splitNeedIncome
                    : split.basis == SplitBasis.rule
                        ? l.splitBasisRule
                        : l.splitBasisHistory(split.monthsOfHistory),
              ),

              if (split.hasIncome) ...<Widget>[
                const SizedBox(height: DsSpacing.lg),
                _BucketBar(split: split),
                const SizedBox(height: DsSpacing.md),
                if (split.isDeficit)
                  _Note(
                      icon: Icons.error_outline_rounded,
                      color: c.expense,
                      text: l.splitDeficit(
                          MoneyFormatter.format(split.shortfall))),
                if (!split.isDeficit && split.trimmed.minorUnits > 0)
                  _Note(
                      icon: Icons.content_cut_rounded,
                      color: c.saving,
                      text: l.splitTrimmed(
                          MoneyFormatter.format(split.trimmed))),
                if (split.goalsUncovered.minorUnits > 0)
                  _Note(
                      icon: Icons.flag_outlined,
                      color: c.saving,
                      text: l.splitGoalsShort(
                          MoneyFormatter.format(split.goalsUncovered))),
                const SizedBox(height: DsSpacing.md),

                for (final SplitBucket b in SplitBucket.values)
                  if (split.lines.any((SplitLine x) => x.bucket == b))
                    ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: DsSpacing.sm, bottom: DsSpacing.xs),
                        child: Text(_bucketName(l, b),
                            style: t.labelLarge?.copyWith(
                                color: _bucketColor(c, b),
                                fontWeight: FontWeight.w700)),
                      ),
                      for (final SplitLine line
                          in split.lines.where((SplitLine x) => x.bucket == b))
                        _LineRow(
                          label: Catalog.label(line.category, ar: ar),
                          line: line,
                          averageLabel: line.average.minorUnits > 0
                              ? l.splitAverage(
                                  MoneyFormatter.format(line.average))
                              : null,
                        ),
                    ],

                const SizedBox(height: DsSpacing.md),
                Text(l.splitReplaceNote,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
                const SizedBox(height: DsSpacing.md),
                DsButton(
                  label: l.splitApply(monthLabel),
                  icon: Icons.check_rounded,
                  expand: true,
                  onPressed: (_saving ||
                          split.lines.every(
                              (SplitLine x) => x.suggested.minorUnits <= 0))
                      ? null
                      : () => _apply(split),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtInput(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String _bucketName(AppLocalizations l, SplitBucket b) => switch (b) {
      SplitBucket.needs => l.splitNeeds,
      SplitBucket.wants => l.splitWants,
      SplitBucket.savings => l.splitSavings,
    };

Color _bucketColor(DsColors c, SplitBucket b) => switch (b) {
      SplitBucket.needs => c.expense,
      SplitBucket.wants => c.saving,
      SplitBucket.savings => c.income,
    };

/// Needs / wants / savings as one stacked bar with amounts and shares.
class _BucketBar extends StatelessWidget {
  const _BucketBar({required this.split});
  final SalarySplit split;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<(SplitBucket, Money)> parts = <(SplitBucket, Money)>[
      (SplitBucket.needs, split.needs),
      (SplitBucket.wants, split.wants),
      (SplitBucket.savings, split.savings),
    ];
    final int total =
        parts.fold(0, (int a, (SplitBucket, Money) p) => a + p.$2.minorUnits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: DsRadius.brPill,
          child: SizedBox(
            height: 10,
            child: Row(
              children: <Widget>[
                for (final (SplitBucket, Money) p in parts)
                  if (p.$2.minorUnits > 0 && total > 0)
                    Expanded(
                      flex: (p.$2.minorUnits * 1000 / total).round().clamp(1, 1000),
                      child: Container(color: _bucketColor(c, p.$1)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        Wrap(
          spacing: DsSpacing.lg,
          runSpacing: DsSpacing.xs,
          children: <Widget>[
            for (final (SplitBucket, Money) p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _bucketColor(c, p.$1),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_bucketName(l, p.$1)} · ${MoneyFormatter.format(p.$2)} '
                    '(${MoneyFormatter.percent(split.shareOf(p.$2), decimals: 0)})',
                    style: t.labelSmall?.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.label,
    required this.line,
    this.averageLabel,
  });

  final String label;
  final SplitLine line;
  final String? averageLabel;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool reduced = line.bucket == SplitBucket.wants &&
        line.suggested.minorUnits < line.average.minorUnits;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: t.bodyMedium),
                if (averageLabel != null)
                  Text(averageLabel!,
                      style: t.labelSmall?.copyWith(color: c.textFaint)),
              ],
            ),
          ),
          Text(
            MoneyFormatter.format(line.suggested),
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: reduced ? c.saving : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
