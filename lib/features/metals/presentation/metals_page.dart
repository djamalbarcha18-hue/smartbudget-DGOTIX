import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metal_editor_sheet.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Gold, silver and platinum kept as savings: each piece or bar, what it is
/// worth at today's price, and the price per gram used.
class MetalsPage extends ConsumerWidget {
  const MetalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<MetalHolding> holdings =
        ref.watch(metalHoldingsProvider).valueOrNull ?? const <MetalHolding>[];
    final MetalsSummary summary = ref.watch(metalsSummaryProvider);
    final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.metalsTitle, style: t.headlineSmall),
          const SizedBox(height: DsSpacing.xs),
          Text(l.metalsHint, style: t.bodyMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.lg),
          DsButton(
            label: l.metalsAdd,
            icon: Icons.add_rounded,
            onPressed: () => MetalEditorSheet.show(context),
          ),
          const SizedBox(height: DsSpacing.lg),
          if (holdings.isEmpty)
            DsEmpty(
              title: l.metalsEmptyTitle,
              message: l.metalsEmptyMessage,
              icon: Icons.toll_outlined,
            )
          else ...<Widget>[
            _SummaryCard(summary: summary),
            const SizedBox(height: DsSpacing.lg),
            for (final MetalHolding h in holdings)
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                child: _HoldingTile(holding: h, price: prices[h.metal]),
              ),
          ],
          const SizedBox(height: DsSpacing.lg),
          const _PricesCard(),
          const SizedBox(height: DsSpacing.md),
          Text(l.metalsEstimate,
              style: t.bodySmall?.copyWith(color: c.textFaint)),
          const SizedBox(height: DsSpacing.xl),
        ],
      ),
    );
  }
}

String _percent(double r) {
  final String s = (r * 100).toStringAsFixed(1);
  return '\u2066${r >= 0 ? '+' : ''}$s%\u2069';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final MetalsSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ({Money paid, Money value})? paid = summary.paidTotal;
    return GlassCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.metalsWorthToday,
              style: t.labelLarge?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.xs),
          Text(MoneyFormatter.format(summary.total),
              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (paid != null && paid.paid.minorUnits > 0) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(
              l.metalsSinceBought(_percent(
                  (paid.value.minorUnits - paid.paid.minorUnits) /
                      paid.paid.minorUnits)),
              style: t.labelLarge?.copyWith(
                  color: paid.value.minorUnits >= paid.paid.minorUnits
                      ? c.income
                      : c.expense),
            ),
          ],
          const SizedBox(height: DsSpacing.md),
          for (final Metal m in Metal.values)
            if (summary.pureGrams.containsKey(m))
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.circle, size: 10, color: MetalText.color(m)),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(
                        '${MetalText.name(l, m)} · ${l.metalsPure(MetalText.grams(l, summary.pureGrams[m]!))}',
                        style: t.bodyMedium,
                      ),
                    ),
                    Text(
                      summary.byMetal[m] == null
                          ? '—'
                          : MoneyFormatter.format(summary.byMetal[m]!),
                      style: t.titleSmall,
                    ),
                  ],
                ),
              ),
          if (summary.unpriced.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(l.metalsNoPrice,
                style: t.bodySmall?.copyWith(color: c.warning)),
          ],
        ],
      ),
    );
  }
}

class _HoldingTile extends ConsumerWidget {
  const _HoldingTile({required this.holding, required this.price});
  final MetalHolding holding;
  final MetalPrice? price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final MetalHolding h = holding;
    final Money? value =
        price == null ? null : MetalsValuation.value(h, price!);
    final String title =
        h.name.isNotEmpty ? h.name : MetalText.name(l, h.metal);
    return Material(
      color: c.surface,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => MetalEditorSheet.show(context, existing: h),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: MetalText.color(h.metal).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.toll_outlined,
                    size: 20, color: MetalText.color(h.metal)),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall),
                    Text(
                      <String>[
                        if (h.name.isNotEmpty) MetalText.name(l, h.metal),
                        MetalText.grams(l, h.grams),
                        MetalText.purity(l, h.metal, h.purity),
                      ].join(' · '),
                      style: t.labelSmall,
                    ),
                  ],
                ),
              ),
              Text(value == null ? '—' : MoneyFormatter.format(value),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await MetalEditorSheet.show(context, existing: h);
                  } else if (v == 'delete') {
                    final bool? ok = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                        title: Text(l.metalsDeleteTitle),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(l.cancel)),
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(l.delete)),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(metalActionsProvider).delete(h.id);
                    }
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

/// Today's price per gram of each pure metal, where it comes from, and the
/// user's own local price.
class _PricesCard extends ConsumerWidget {
  const _PricesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);
    final Locale locale = Localizations.localeOf(context);
    return GlassCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(
              title: l.metalsPrices, icon: Icons.show_chart_rounded),
          const SizedBox(height: DsSpacing.sm),
          for (final Metal m in Metal.values)
            InkWell(
              borderRadius: DsRadius.brMd,
              onTap: () => _setPrice(context, ref, m, prices[m]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.circle, size: 10, color: MetalText.color(m)),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                              '${MetalText.name(l, m)} · ${MetalText.purity(l, m, m == Metal.gold ? 24 : 999)}',
                              style: t.titleSmall),
                          Text(
                            switch (prices[m]?.source) {
                              null => l.metalsNoPriceShort,
                              MetalPriceSource.mine => l.metalsSourceMine,
                              MetalPriceSource.market =>
                                l.metalsSourceMarket(prices[m]!.updatedAt ==
                                        null
                                    ? '—'
                                    : '${dayText(locale, prices[m]!.updatedAt!.toLocal())} '
                                        '${_hm(prices[m]!.updatedAt!.toLocal())}'),
                            },
                            style: t.labelSmall?.copyWith(
                                color:
                                    prices[m]?.source == MetalPriceSource.mine
                                        ? c.brand
                                        : null),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      prices[m] == null
                          ? '—'
                          : l.metalsPerGram(MoneyFormatter.format(
                              Money.fromDouble(
                                  prices[m]!.perGram, prices[m]!.currency))),
                      style: t.titleSmall,
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    Icon(Icons.edit_outlined, size: 16, color: c.textFaint),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _hm(DateTime d) =>
      '\u2066${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}\u2069';

  Future<void> _setPrice(
      BuildContext context, WidgetRef ref, Metal m, MetalPrice? now) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final TextEditingController ctrl = TextEditingController(
        text: now?.source == MetalPriceSource.mine
            ? AmountInput.text(now!.perGram)
            : '');
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.metalsSetPrice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.metalsSetPriceHint(MetalText.name(l, m))),
            const SizedBox(height: DsSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    '${MetalText.name(l, m)} · ${MetalText.purity(l, m, m == Metal.gold ? 24 : 999)}',
                suffixText: currency,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop('market'),
              child: Text(l.metalsUseMarket)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              child: Text(l.save)),
        ],
      ),
    );
    if (result == 'market') {
      await ref.read(myMetalPricesProvider.notifier).set(m, null, currency);
    } else if (result == 'save') {
      await ref
          .read(myMetalPricesProvider.notifier)
          .set(m, AmountInput.parse(ctrl.text), currency);
    }
    ctrl.dispose();
  }
}
