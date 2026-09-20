import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/features/zakat/domain/hawl.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ZakatPage extends ConsumerStatefulWidget {
  const ZakatPage({super.key});

  @override
  ConsumerState<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends ConsumerState<ZakatPage> {
  late final TextEditingController _gold;
  late final TextEditingController _silver;
  late final TextEditingController _cash;
  late final TextEditingController _metals;
  late final TextEditingController _investments;

  static String _fmt(double v) => v == 0 ? '' : v.toString();

  @override
  void initState() {
    super.initState();
    final ZakatInputs i = ref.read(zakatInputsProvider);
    _gold = TextEditingController(text: _fmt(i.goldPricePerGram));
    _silver = TextEditingController(text: _fmt(i.silverPricePerGram));
    _cash = TextEditingController(text: _fmt(i.cash));
    _metals = TextEditingController(text: _fmt(i.metals));
    _investments = TextEditingController(text: _fmt(i.investments));
  }

  @override
  void dispose() {
    _gold.dispose();
    _silver.dispose();
    _cash.dispose();
    _metals.dispose();
    _investments.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _apply({ZakatStandard? standard}) {
    final ZakatInputs cur = ref.read(zakatInputsProvider);
    ref.read(zakatInputsProvider.notifier).update(
          cur.copyWith(
            goldPricePerGram: _num(_gold),
            silverPricePerGram: _num(_silver),
            standard: standard ?? cur.standard,
            cash: _num(_cash),
            metals: _num(_metals),
            investments: _num(_investments),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ZakatInputs inputs = ref.watch(zakatInputsProvider);
    final ZakatResult r = ref.watch(zakatResultProvider);
    final HawlStatus? hawl = ref.watch(zakatHawlProvider);
    final bool needsPrices =
        inputs.goldPricePerGram <= 0 && inputs.silverPricePerGram <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.navZakat, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.xl),

          // Inputs.
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.zakatPrices,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DsSpacing.lg),
                DsTextField(
                  label: l.zakatGoldPrice,
                  controller: _gold,
                  prefixIcon: Icons.circle,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: DsSpacing.md),
                DsTextField(
                  label: l.zakatSilverPrice,
                  controller: _silver,
                  prefixIcon: Icons.circle_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: DsSpacing.lg),
                _StandardToggle(
                  value: inputs.standard,
                  onChanged: (ZakatStandard s) => _apply(standard: s),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.lg),

          // Hawl (lunar-year) tracker.
          const _HawlCard(),
          const SizedBox(height: DsSpacing.lg),

          // Manual zakatable wealth (not tracked elsewhere in the app).
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.zakatAddWealth,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DsSpacing.xs),
                Text(l.zakatAddWealthHint,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: DsSpacing.lg),
                DsTextField(
                  label: l.zakatCash,
                  controller: _cash,
                  prefixIcon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: DsSpacing.md),
                DsTextField(
                  label: l.zakatMetalsHoldings,
                  controller: _metals,
                  prefixIcon: Icons.diamond_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: DsSpacing.md),
                DsTextField(
                  label: l.zakatInvestments,
                  controller: _investments,
                  prefixIcon: Icons.trending_up_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: DsSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _apply,
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.lg),

          if (needsPrices)
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Text(l.zakatEnterPrices,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            )
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _row(context, l.zakatNisab,
                      MoneyFormatter.format(r.adoptedNisab)),
                  const Divider(height: DsSpacing.xl),
                  // Gathered assets — component breakdown (non-zero only).
                  if (r.savings.minorUnits != 0)
                    _row(context, l.zakatSavings,
                        MoneyFormatter.format(r.savings), sub: true),
                  if (r.surplus.minorUnits != 0)
                    _row(context, l.zakatSurplus,
                        MoneyFormatter.format(r.surplus), sub: true),
                  if (r.portfolio.minorUnits != 0)
                    _row(context, l.zakatPortfolio,
                        MoneyFormatter.format(r.portfolio), sub: true),
                  if (r.receivables.minorUnits != 0)
                    _row(context, l.zakatReceivables,
                        MoneyFormatter.format(r.receivables), sub: true),
                  if (r.manual.minorUnits != 0)
                    _row(context, l.zakatManualWealth,
                        MoneyFormatter.format(r.manual), sub: true),
                  _row(context, l.zakatAssets, MoneyFormatter.format(r.assets)),
                  _row(context, l.zakatLiabilities,
                      MoneyFormatter.format(r.liabilities)),
                  const Divider(height: DsSpacing.xl),
                  _row(context, l.zakatNetWealth,
                      MoneyFormatter.format(r.netZakatable),
                      strong: true),
                  const SizedBox(height: DsSpacing.md),
                  _StatusBanner(result: r, hawl: hawl),
                ],
              ),
            ),
          const SizedBox(height: DsSpacing.md),
          Text(l.zakatDisclaimer,
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool strong = false, bool sub = false}) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: EdgeInsets.only(
        top: sub ? 3 : 6,
        bottom: sub ? 3 : 6,
        left: sub ? DsSpacing.md : 0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: strong
                    ? Theme.of(context).textTheme.titleSmall
                    : (sub
                        ? Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: c.textFaint)
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: c.textMuted))),
          ),
          Text(value,
              style: (sub
                      ? Theme.of(context).textTheme.bodySmall
                      : Theme.of(context).textTheme.titleSmall)
                  ?.copyWith(
                color: sub ? c.textMuted : c.textPrimary,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

/// Hawl tracker: set the date wealth reached nisab; shows the lunar-year
/// countdown and completion, in Hijri.
class _HawlCard extends ConsumerWidget {
  const _HawlCard();

  Future<void> _pick(BuildContext context, WidgetRef ref, DateTime? current) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked != null) {
      await ref.read(zakatInputsProvider.notifier).setHawlStart(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final DateTime? start = ref.watch(zakatInputsProvider).hawlStart;
    final HawlStatus? hawl = ref.watch(zakatHawlProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.hourglass_bottom_rounded, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Text(l.zakatHawl, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.zakatHawlHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: DsSpacing.md),
          if (start == null || hawl == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ref, null),
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(l.zakatHawlSetDate),
              ),
            )
          else ...<Widget>[
            _kv(context, l.zakatHawlStart, hawl.startHijri.format(ar: ar)),
            _kv(context, l.zakatHawlDue,
                '${hawl.dueHijri.format(ar: ar)} · ${_greg(hawl.due)}'),
            const SizedBox(height: DsSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DsSpacing.sm),
              decoration: BoxDecoration(
                color: (hawl.complete ? c.income : c.saving)
                    .withValues(alpha: 0.12),
                borderRadius: DsRadius.brMd,
              ),
              child: Text(
                hawl.complete
                    ? l.zakatHawlComplete
                    : l.zakatHawlRemaining(hawl.daysRemaining),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: hawl.complete ? c.income : c.saving,
                    ),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => _pick(context, ref, start),
                  child: Text(l.zakatHawlSetDate),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(zakatInputsProvider.notifier).setHawlStart(null),
                  child: Text(l.delete),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(k,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c.textMuted)),
          ),
          Text(v, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  static String _greg(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// The zakat status banner, gated on BOTH nisab and hawl completion.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.result, required this.hawl});
  final ZakatResult result;
  final HawlStatus? hawl;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool nisabMet = result.obligatory;
    final bool dueNow = nisabMet && hawl != null && hawl!.complete;

    final (String, Color, bool) state = !nisabMet
        ? (l.zakatNotDue, c.textMuted, false)
        : dueNow
            ? (l.zakatObligatory, c.income, true)
            : hawl == null
                ? (l.zakatHawlNotSet, c.saving, false)
                : (l.zakatHawlPending, c.saving, false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: state.$2.withValues(alpha: 0.12),
        borderRadius: DsRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(state.$1,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: state.$2)),
          if (state.$3) ...<Widget>[
            const SizedBox(height: 4),
            Text(l.zakatDue, style: Theme.of(context).textTheme.labelSmall),
            Text(MoneyFormatter.format(result.due),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: c.income)),
          ],
        ],
      ),
    );
  }
}

class _StandardToggle extends StatelessWidget {
  const _StandardToggle({required this.value, required this.onChanged});
  final ZakatStandard value;
  final ValueChanged<ZakatStandard> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);

    Widget seg(String label, ZakatStandard v) {
      final bool selected = value == v;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(v),
          borderRadius: DsRadius.brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.brand.withValues(alpha: 0.16) : c.surfaceMuted,
              borderRadius: DsRadius.brMd,
              border: Border.all(color: selected ? c.brand : c.border),
            ),
            child: Text(label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? c.brand : c.textMuted,
                    )),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.zakatStandard,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            seg(l.zakatStandardGold, ZakatStandard.gold),
            const SizedBox(width: DsSpacing.md),
            seg(l.zakatStandardSilver, ZakatStandard.silver),
          ],
        ),
      ],
    );
  }
}
