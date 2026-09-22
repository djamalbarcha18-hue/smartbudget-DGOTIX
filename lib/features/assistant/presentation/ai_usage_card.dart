import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/features/assistant/application/ai_usage_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Shows this month's AI usage (requests, tokens, approximate cost) counted from
/// provider responses on this device, to help the user rationalize consumption.
class AiUsageCard extends ConsumerWidget {
  const AiUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AiUsageSummary u = ref.watch(aiUsageMonthProvider);
    final AiUsageLimit limit = ref.watch(aiUsageLimitProvider);
    final UsageAlert alert = ref.watch(aiUsageAlertProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.speed_rounded, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.usageTitle,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: l.limitEdit,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.tune_rounded, size: 18, color: c.textMuted),
                onPressed: () => _LimitSheet.show(context, limit),
              ),
              if (!u.isEmpty)
                TextButton(
                  onPressed: () => ref.read(aiUsageProvider.notifier).reset(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.sm, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: c.textMuted,
                  ),
                  child: Text(l.usageReset, style: t.labelSmall),
                ),
            ],
          ),
          if (limit.isSet && alert.level != UsageLevel.ok) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            _AlertBanner(
              over: alert.level == UsageLevel.over,
              text: alert.level == UsageLevel.over
                  ? l.limitOverWarn
                  : l.limitNearWarn,
            ),
          ],
          if (limit.isSet) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            if (alert.reqRatio != null)
              _LimitBar(
                label: l.usageRequests,
                used: _fmtInt(u.requests),
                cap: _fmtInt(limit.maxRequests!),
                ratio: alert.reqRatio!,
              ),
            if (alert.reqRatio != null && alert.costRatio != null)
              const SizedBox(height: DsSpacing.sm),
            if (alert.costRatio != null)
              _LimitBar(
                label: l.usageCost,
                used: _fmtCost(u.estCostUsd),
                cap: _fmtCost(limit.maxCostUsd!),
                ratio: alert.costRatio!,
              ),
          ],
          const SizedBox(height: DsSpacing.md),

          if (u.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
              child: Text(l.usageEmpty,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                _Stat(label: l.usageRequests, value: _fmtInt(u.requests)),
                _Divider(color: c.border),
                _Stat(label: l.usageTokens, value: _fmtInt(u.totalTokens)),
                _Divider(color: c.border),
                _Stat(label: l.usageCost, value: _fmtCost(u.estCostUsd)),
              ],
            ),
            const SizedBox(height: DsSpacing.md),
            for (final MapEntry<String, AiUsageStat> e in u.perModel.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: c.brand, borderRadius: DsRadius.brPill),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(e.key,
                          style: t.bodySmall, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '${_fmtInt(e.value.requests)} · ${_fmtInt(e.value.totalTokens)}',
                      style: t.labelSmall?.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: DsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 13, color: c.textFaint),
              const SizedBox(width: DsSpacing.xs),
              Expanded(
                child: Text('${l.usageNote} ${l.pricesAsOf(kPricesAsOf)}',
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                final AiKeyConfig? cfg = ref.read(aiKeyProvider);
                _PriceSheet.show(context, cfg?.provider.models ?? const <String>[]);
              },
              icon: Icon(Icons.price_change_outlined, size: 15, color: c.brand),
              label: Text(l.pricesAdjust,
                  style: t.labelSmall?.copyWith(color: c.brand)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.sm, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtInt(int n) {
  final String s = n.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

String _fmtCost(double usd) {
  if (usd <= 0) return '≈ \$0.00';
  return '≈ \$${usd.toStringAsFixed(usd >= 1 ? 2 : 4)}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: t.labelSmall?.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
      color: color,
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.over, required this.text});
  final bool over;
  final String text;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color color = over ? c.expense : c.saving;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md, vertical: DsSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DsRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(over ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
              size: 16, color: color),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({
    required this.label,
    required this.used,
    required this.cap,
    required this.ratio,
  });
  final String label;
  final String used;
  final String cap;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Color color = ratio >= 1.0
        ? c.expense
        : (ratio >= 0.8 ? c.saving : c.income);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label,
                  style: t.labelSmall?.copyWith(color: c.textMuted)),
            ),
            Text('$used / $cap',
                style: t.labelSmall?.copyWith(
                    color: c.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: c.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet to set or clear the optional monthly caps.
class _LimitSheet extends ConsumerStatefulWidget {
  const _LimitSheet({required this.initial});
  final AiUsageLimit initial;

  static Future<void> show(BuildContext context, AiUsageLimit initial) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LimitSheet(initial: initial),
    );
  }

  @override
  ConsumerState<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends ConsumerState<_LimitSheet> {
  late final TextEditingController _req = TextEditingController(
      text: widget.initial.maxRequests?.toString() ?? '');
  late final TextEditingController _cost = TextEditingController(
      text: widget.initial.maxCostUsd == null
          ? ''
          : widget.initial.maxCostUsd!
              .toStringAsFixed(widget.initial.maxCostUsd! >= 1 ? 2 : 4));

  @override
  void dispose() {
    _req.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _save() {
    final int? req = int.tryParse(_req.text.trim());
    final double? cost = double.tryParse(_cost.text.trim());
    ref.read(aiUsageLimitProvider.notifier).save(maxRequests: req, maxCostUsd: cost);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(aiUsageLimitProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.tune_rounded, size: 20, color: c.brand),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(l.limitTitle,
                      style:
                          t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(l.limitHint, style: t.bodySmall?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.lg),
            _Field(
                controller: _req,
                label: l.limitRequests,
                digitsOnly: true,
                color: c),
            const SizedBox(height: DsSpacing.md),
            _Field(
                controller: _cost,
                label: l.limitCost,
                digitsOnly: false,
                color: c),
            const SizedBox(height: DsSpacing.lg),
            DsButton(
                label: l.save,
                icon: Icons.check_rounded,
                onPressed: _save),
            if (widget.initial.isSet) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              DsButton(
                  label: l.clearSelection,
                  variant: DsButtonVariant.secondary,
                  onPressed: _clear),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sheet to override the USD price per 1M tokens for the connected provider's
/// models, so the estimate stays accurate when provider prices change.
class _PriceSheet extends ConsumerStatefulWidget {
  const _PriceSheet({required this.models});
  final List<String> models;

  static Future<void> show(BuildContext context, List<String> models) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PriceSheet(models: models),
    );
  }

  @override
  ConsumerState<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<_PriceSheet> {
  final Map<String, TextEditingController> _in = <String, TextEditingController>{};
  final Map<String, TextEditingController> _out = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final Map<String, (double, double)> overrides =
        ref.read(aiPriceOverrideProvider);
    for (final String m in widget.models) {
      final (double, double) p = effectivePriceOf(m, overrides);
      _in[m] = TextEditingController(text: _fmtPrice(p.$1));
      _out[m] = TextEditingController(text: _fmtPrice(p.$2));
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _in.values) {
      c.dispose();
    }
    for (final TextEditingController c in _out.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final AiPriceOverrideController ctl =
        ref.read(aiPriceOverrideProvider.notifier);
    for (final String m in widget.models) {
      final double? inp = double.tryParse(_in[m]!.text.trim());
      final double? out = double.tryParse(_out[m]!.text.trim());
      if (inp != null && out != null) ctl.set(m, inp, out);
    }
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(aiPriceOverrideProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                  Icon(Icons.price_change_outlined, size: 20, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.pricesTitle,
                        style:
                            t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text('${l.pricesHint} ${l.pricesAsOf(kPricesAsOf)}',
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.lg),
              if (widget.models.isEmpty)
                Text(l.usageEmpty,
                    style: t.bodySmall?.copyWith(color: c.textMuted))
              else
                for (final String m in widget.models) ...<Widget>[
                  Text(m,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: DsSpacing.xs),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Field(
                            controller: _in[m]!,
                            label: l.pricesInput,
                            digitsOnly: false,
                            color: c),
                      ),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        child: _Field(
                            controller: _out[m]!,
                            label: l.pricesOutput,
                            digitsOnly: false,
                            color: c),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.md),
                ],
              const SizedBox(height: DsSpacing.sm),
              DsButton(
                  label: l.save, icon: Icons.check_rounded, onPressed: _save),
              const SizedBox(height: DsSpacing.sm),
              DsButton(
                  label: l.pricesReset,
                  variant: DsButtonVariant.secondary,
                  onPressed: _reset),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtPrice(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.digitsOnly,
    required this.color,
  });
  final TextEditingController controller;
  final String label;
  final bool digitsOnly;
  final DsColors color;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: t.labelMedium?.copyWith(color: color.textMuted)),
        const SizedBox(height: DsSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !digitsOnly),
          inputFormatters: digitsOnly
              ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
              : <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
          decoration: InputDecoration(
            isDense: true,
            hintText: '—',
            filled: true,
            fillColor: color.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md, vertical: DsSpacing.sm),
            enabledBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: color.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: color.brand),
            ),
          ),
        ),
      ],
    );
  }
}
