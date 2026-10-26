import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/business_impact.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/metals_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';

String marketCategoryLabel(AppLocalizations l, MarketCategory c) => switch (c) {
      MarketCategory.exchangeRates => l.tabExchangeRates,
      MarketCategory.crypto => l.tabCrypto,
      MarketCategory.preciousMetals => l.tabPreciousMetals,
      MarketCategory.industrialMetals => l.tabIndustrialMetals,
      MarketCategory.steelIron => l.tabSteelIron,
      MarketCategory.energy => l.tabEnergy,
      MarketCategory.agriculture => l.tabAgriculture,
    };

/// Horizontal, scrollable category tab bar bound to the selected category.
class MarketCategoryTabs extends ConsumerWidget {
  const MarketCategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final MarketCategory selected = ref.watch(selectedMarketCategoryProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final MarketCategory cat in MarketCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: DsSpacing.sm),
              child: Material(
                color: cat == selected ? c.brand : c.surfaceMuted,
                borderRadius: DsRadius.brPill,
                child: InkWell(
                  borderRadius: DsRadius.brPill,
                  onTap: () =>
                      ref.read(selectedMarketCategoryProvider.notifier).state = cat,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.lg, vertical: DsSpacing.sm),
                    child: Text(
                      marketCategoryLabel(l, cat),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cat == selected ? c.onBrand : c.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small coloured badge for a price's data quality.
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.quality});
  final PriceQuality quality;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final (String text, Color color) = switch (quality) {
      PriceQuality.realtime => (l.qualityRealtime, c.income),
      PriceQuality.nearRealtime => (l.qualityNearRealtime, c.income),
      PriceQuality.delayed => (l.qualityDelayed, c.warning),
      PriceQuality.indicative => (l.qualityIndicative, c.warning),
      PriceQuality.unavailable => (l.qualityUnavailable, c.textFaint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: DsRadius.brPill,
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color)),
    );
  }
}

/// Precious metals: spot per ounce/gram/kg + karats (gold) / fineness (silver),
/// in USD and the user's base currency.
class PreciousMetalsSection extends ConsumerWidget {
  const PreciousMetalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String base = ref.watch(baseCurrencyProvider);
    final double? usdToBase = ref
        .watch(fxSnapshotProvider)
        .whenOrNull(data: (FxSnapshot s) => s.cross('USD', base));
    final AsyncValue<List<CommodityQuote>> quotes =
        ref.watch(commodityQuotesProvider(MarketCategory.preciousMetals));

    return quotes.when(
      loading: () => const _Loading(),
      error: (Object e, StackTrace _) => _ErrorText(message: l.marketUnavailable),
      data: (List<CommodityQuote> list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final CommodityQuote q in list) ...<Widget>[
            _MetalCard(quote: q, base: base, usdToBase: usdToBase),
            const SizedBox(height: DsSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MetalCard extends StatelessWidget {
  const _MetalCard(
      {required this.quote, required this.base, required this.usdToBase});
  final CommodityQuote quote;
  final String base;
  final double? usdToBase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang lang = appLangOf(context);
    final bool local = usdToBase != null;
    final String cur = local ? base : 'USD';
    double conv(double usd) => local ? usd * usdToBase! : usd;

    final double? oz = quote.priceUsd;
    final List<int>? karats = quote.code == 'XAU' ? MetalsCalculator.goldKarats : null;
    final List<int>? fineness =
        quote.code == 'XAG' ? MetalsCalculator.silverFineness : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('${lang.isAr ? quote.nameAr : quote.nameEn} · ${quote.code}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              QualityBadge(quality: quote.quality),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          if (oz == null)
            Text(l.marketUnavailable,
                style: Theme.of(context).textTheme.bodySmall)
          else ...<Widget>[
            Wrap(
              spacing: DsSpacing.xl,
              runSpacing: DsSpacing.sm,
              children: <Widget>[
                _Stat(label: l.perOunce, value: '${_fmt(conv(oz))} $cur'),
                _Stat(
                    label: l.perGram,
                    value: '${_fmt(conv(MetalsCalculator.perGram(oz)))} $cur'),
                _Stat(
                    label: l.perKilogram,
                    value:
                        '${_fmt(conv(MetalsCalculator.perKilogram(oz)))} $cur'),
              ],
            ),
            if (karats != null) ...<Widget>[
              const SizedBox(height: DsSpacing.md),
              Text(l.karatTable, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: DsSpacing.xs),
              _KaratChips(
                labels: <String>[for (final int k in karats) '${k}K'],
                pricesPerGram: <double>[
                  for (final int k in karats)
                    conv(MetalsCalculator.karatPrice(
                        MetalsCalculator.perGram(oz), k)),
                ],
                cur: cur,
              ),
            ],
            if (fineness != null) ...<Widget>[
              const SizedBox(height: DsSpacing.md),
              Text(l.purityTable, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: DsSpacing.xs),
              _KaratChips(
                labels: <String>[for (final int f in fineness) '$f'],
                pricesPerGram: <double>[
                  for (final int f in fineness)
                    conv(MetalsCalculator.finenessPrice(
                        MetalsCalculator.perGram(oz), f)),
                ],
                cur: cur,
              ),
            ],
          ],
          const SizedBox(height: DsSpacing.sm),
          _SourceLine(source: quote.source, updatedAt: quote.updatedAt),
        ],
      ),
    );
  }
}

class _KaratChips extends StatelessWidget {
  const _KaratChips(
      {required this.labels, required this.pricesPerGram, required this.cur});
  final List<String> labels;
  final List<double> pricesPerGram;
  final String cur;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Wrap(
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.sm,
      children: <Widget>[
        for (int i = 0; i < labels.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md, vertical: DsSpacing.xs),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: DsRadius.brSm,
              border: Border.all(color: c.border),
            ),
            child: Text('${labels[i]} · ${_fmt(pricesPerGram[i])} $cur/g',
                style: Theme.of(context).textTheme.labelSmall),
          ),
      ],
    );
  }
}

/// Generic commodity list for industrial metals, steel, energy, agriculture.
class CommodityCategorySection extends ConsumerWidget {
  const CommodityCategorySection({super.key, required this.category});
  final MarketCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String base = ref.watch(baseCurrencyProvider);
    final double? usdToBase = ref
        .watch(fxSnapshotProvider)
        .whenOrNull(data: (FxSnapshot s) => s.cross('USD', base));
    final AsyncValue<List<CommodityQuote>> quotes =
        ref.watch(commodityQuotesProvider(category));

    return quotes.when(
      loading: () => const _Loading(),
      error: (Object e, StackTrace _) => _ErrorText(message: l.marketUnavailable),
      // Live prices first, each on its own card; the ones still waiting for
      // a data source together on one, so they don't crowd the page.
      data: (List<CommodityQuote> list) {
        final List<CommodityQuote> live = <CommodityQuote>[
          for (final CommodityQuote q in list)
            if (q.priceUsd != null) q,
        ];
        final List<CommodityQuote> waiting = <CommodityQuote>[
          for (final CommodityQuote q in list)
            if (q.priceUsd == null) q,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final CommodityQuote q in live) ...<Widget>[
              _CommodityCard(quote: q, base: base, usdToBase: usdToBase),
              const SizedBox(height: DsSpacing.md),
            ],
            if (waiting.isNotEmpty) _WaitingCard(quotes: waiting),
          ],
        );
      },
    );
  }
}

/// What the price is (a month's average or a day's price), where it comes
/// from, and how it moved since the period before.
class _PeriodLine extends StatelessWidget {
  const _PeriodLine({required this.quote});
  final CommodityQuote quote;

  /// "2026-09" or "2026-10-24", else null.
  static DateTime? _date(String p) {
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})(?:-(\d{2}))?').firstMatch(p);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!),
        m[3] == null ? 1 : int.parse(m[3]!));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Locale locale = Localizations.localeOf(context);
    final DateTime? d = _date(quote.period!);
    final String when = d == null
        ? quote.period!
        : quote.monthly
            ? l.marketMonthlyAvg(monthText(locale, d))
            : l.marketDayPrice(dayText(locale, d));
    final double? pct = quote.changePct;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (pct != null)
            Row(
              children: <Widget>[
                Icon(
                    pct >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: pct >= 0 ? c.income : c.expense),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    (quote.monthly ? l.marketVsPrevMonth : l.marketVsPrevDay)(
                        '\u2066${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%\u2069'),
                    style: t.labelMedium
                        ?.copyWith(color: pct >= 0 ? c.income : c.expense),
                  ),
                ),
              ],
            ),
          Text('$when · ${l.marketSource}: ${quote.source}',
              style: t.labelSmall?.copyWith(color: c.textFaint)),
        ],
      ),
    );
  }
}

/// Commodities with no data source yet, named on one card.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.quotes});
  final List<CommodityQuote> quotes;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang lang = appLangOf(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Set<String> benchmarks = <String>{
      for (final CommodityQuote q in quotes)
        if (q.benchmark != null) q.benchmark!,
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(l.marketUnavailable,
                    style: t.titleSmall?.copyWith(color: c.textMuted)),
              ),
              const QualityBadge(quality: PriceQuality.unavailable),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final CommodityQuote q in quotes)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md, vertical: DsSpacing.xs),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: DsRadius.brPill,
                    border: Border.all(color: c.border),
                  ),
                  child: Text('${lang.isAr ? q.nameAr : q.nameEn} · ${q.code}',
                      style: t.labelMedium),
                ),
            ],
          ),
          if (benchmarks.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Text('${l.benchmarkLabel}: ${benchmarks.join(' · ')}',
                style: t.labelSmall?.copyWith(color: c.textFaint)),
          ],
        ],
      ),
    );
  }
}

class _CommodityCard extends StatelessWidget {
  const _CommodityCard(
      {required this.quote, required this.base, required this.usdToBase});
  final CommodityQuote quote;
  final String base;
  final double? usdToBase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang lang = appLangOf(context);
    final ImpactNote? impact = BusinessImpact.forCode(quote.code);
    final bool local = usdToBase != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('${lang.isAr ? quote.nameAr : quote.nameEn} · ${quote.code}',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              QualityBadge(quality: quote.quality),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: quote.priceUsd == null
                    ? Text(l.marketUnavailable,
                        style: Theme.of(context).textTheme.bodyMedium)
                    : Text(
                        '${_fmt(quote.priceUsd!)} USD'
                        '${local ? '  ·  ${_fmt(quote.priceUsd! * usdToBase!)} $base' : ''}',
                        style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(quote.unitLabel,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: context.dsColors.textMuted)),
            ],
          ),
          if (quote.priceUsd != null && quote.period != null)
            _PeriodLine(quote: quote),
          // Priced by the troy ounce (platinum, palladium): the gram too.
          if (quote.priceUsd != null && quote.unitLabel == 'USD/oz')
            Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xs),
              child: Text(
                '${l.perGram}: ${_fmt(MetalsCalculator.perGram(quote.priceUsd!) * (usdToBase ?? 1))} ${local ? base : 'USD'}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (quote.benchmark != null || quote.region != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(
              <String>[
                if (quote.benchmark != null) '${l.benchmarkLabel}: ${quote.benchmark}',
                if (quote.region != null) '${l.regionLabel}: ${quote.region}',
              ].join('  ·  '),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: context.dsColors.textFaint),
            ),
          ],
          if (impact != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Text(l.businessImpact,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.dsColors.textMuted)),
            const SizedBox(height: DsSpacing.xxs),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.xs,
              children: <Widget>[
                for (final String s in (lang.isAr ? impact.sectorsAr : impact.sectorsEn))
                  Text('• $s', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---- shared bits ----
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c.textFaint)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.source, required this.updatedAt});
  final String source;
  final DateTime updatedAt;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final DateTime lo = updatedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final String u =
        '${lo.year}-${two(lo.month)}-${two(lo.day)} ${two(lo.hour)}:${two(lo.minute)}';
    return Text('${l.marketSource}: $source · ${l.marketUpdated}: $u',
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: c.textFaint));
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: DsSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Text(message, style: Theme.of(context).textTheme.bodySmall);
}

String _fmt(double v) {
  final int dp = v >= 100 ? 2 : (v >= 1 ? 3 : 4);
  return NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: dp)
      .format(v);
}
