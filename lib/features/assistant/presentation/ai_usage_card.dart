import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
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
                child: Text(l.usageNote,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              ),
            ],
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
