import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
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

  @override
  void initState() {
    super.initState();
    final ZakatInputs i = ref.read(zakatInputsProvider);
    _gold = TextEditingController(
        text: i.goldPricePerGram == 0 ? '' : i.goldPricePerGram.toString());
    _silver = TextEditingController(
        text: i.silverPricePerGram == 0 ? '' : i.silverPricePerGram.toString());
  }

  @override
  void dispose() {
    _gold.dispose();
    _silver.dispose();
    super.dispose();
  }

  void _apply({ZakatStandard? standard}) {
    final ZakatInputs cur = ref.read(zakatInputsProvider);
    ref.read(zakatInputsProvider.notifier).update(
          cur.copyWith(
            goldPricePerGram:
                double.tryParse(_gold.text.trim().replaceAll(',', '.')) ?? 0,
            silverPricePerGram:
                double.tryParse(_silver.text.trim().replaceAll(',', '.')) ?? 0,
            standard: standard ?? cur.standard,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final ZakatInputs inputs = ref.watch(zakatInputsProvider);
    final ZakatResult r = ref.watch(zakatResultProvider);
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
                  _row(context, l.zakatAssets, MoneyFormatter.format(r.assets)),
                  _row(context, l.zakatLiabilities,
                      MoneyFormatter.format(r.liabilities)),
                  const Divider(height: DsSpacing.xl),
                  _row(context, l.zakatNetWealth,
                      MoneyFormatter.format(r.netZakatable),
                      strong: true),
                  const SizedBox(height: DsSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DsSpacing.md),
                    decoration: BoxDecoration(
                      color: (r.obligatory ? c.income : c.textMuted)
                          .withValues(alpha: 0.12),
                      borderRadius: DsRadius.brMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          r.obligatory ? l.zakatObligatory : l.zakatNotDue,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: r.obligatory ? c.income : c.textMuted,
                              ),
                        ),
                        if (r.obligatory) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(l.zakatDue,
                              style: Theme.of(context).textTheme.labelSmall),
                          Text(
                            MoneyFormatter.format(r.due),
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: c.income,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
      {bool strong = false}) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: strong
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: c.textMuted)),
          ),
          Text(value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  )),
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
