import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/markets/application/manual_parallel_controller.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/presentation/commodity_sections.dart';
import 'package:smartbudget/features/markets/presentation/sparkline.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Exchange Rates & Markets" — official + parallel FIAT markets and a crypto
/// section. Every number is fetched live from a keyless public source; when a
/// market has no reliable source the row reads "unavailable" (never fabricated).
class MarketsPage extends ConsumerWidget {
  const MarketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.travel_explore_outlined, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.pageMarkets,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    tooltip: l.marketsRefresh,
                    onPressed: () => ref.read(refreshMarketsProvider)(),
                    icon: Icon(Icons.refresh_rounded, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(l.marketsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: DsSpacing.lg),

              const MarketCategoryTabs(),
              const SizedBox(height: DsSpacing.lg),

              _CategoryContent(
                  category: ref.watch(selectedMarketCategoryProvider)),

              const SizedBox(height: DsSpacing.md),
              _Disclaimer(message: l.marketsDisclaimer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the content for the selected Markets tab.
class _CategoryContent extends StatelessWidget {
  const _CategoryContent({required this.category});
  final MarketCategory category;

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case MarketCategory.exchangeRates:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _RateTypeCard(),
            const SizedBox(height: DsSpacing.lg),
            for (final CountryMarket country in MarketConfig.countries) ...<Widget>[
              _CountrySection(country: country),
              const SizedBox(height: DsSpacing.lg),
            ],
          ],
        );
      case MarketCategory.crypto:
        return const _CryptoSection();
      case MarketCategory.preciousMetals:
        return const PreciousMetalsSection();
      case MarketCategory.industrialMetals:
      case MarketCategory.steelIron:
      case MarketCategory.energy:
      case MarketCategory.agriculture:
        return CommodityCategorySection(category: category);
    }
  }
}

// --------------------------------------------------------------------------
// Rate Type selector (Official / Parallel / P2P / Custom)
// --------------------------------------------------------------------------
class _RateTypeCard extends ConsumerWidget {
  const _RateTypeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final MarketType selected = ref.watch(rateTypeProvider);

    String label(MarketType t) => switch (t) {
          MarketType.official => l.rateTypeOfficial,
          MarketType.parallel => l.rateTypeParallel,
          MarketType.p2p => l.rateTypeP2P,
          MarketType.custom => l.rateTypeCustom,
        };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.rateType, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DsSpacing.xs),
          Text(l.rateTypeHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final MarketType t in MarketType.values)
                _Pill(
                  label: label(t),
                  selected: t == selected,
                  onTap: () => ref.read(rateTypeProvider.notifier).set(t),
                  colors: c,
                ),
            ],
          ),
          if (selected == MarketType.custom) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            const _CustomRateField(),
          ],
        ],
      ),
    );
  }
}

class _CustomRateField extends ConsumerStatefulWidget {
  const _CustomRateField();
  @override
  ConsumerState<_CustomRateField> createState() => _CustomRateFieldState();
}

class _CustomRateFieldState extends ConsumerState<_CustomRateField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final double? v = ref.read(customRateProvider);
    _ctrl = TextEditingController(text: v?.toString() ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String base = ref.watch(baseCurrencyProvider);
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            inputFormatters: LatinDigitsFormatter.only,
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.customRateLabel(base),
              isDense: true,
            ),
            onChanged: (String v) => ref
                .read(customRateProvider.notifier)
                .set(double.tryParse(v.trim().replaceAll(',', '.'))),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// FIAT country section
// --------------------------------------------------------------------------
class _CountrySection extends ConsumerWidget {
  const _CountrySection({required this.country});
  final CountryMarket country;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final AsyncValue<FxSnapshot> fx = ref.watch(fxSnapshotProvider);
    final AsyncValue<List<FxQuote>> parallel =
        ref.watch(parallelQuotesProvider(country.country));
    final Map<String, ManualParallel> manual =
        ref.watch(manualParallelProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CurrencyFlag.country(country.country, width: 26),
              const SizedBox(width: DsSpacing.sm),
              Text(ar ? country.nameAr : country.nameEn,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          for (final String pair in country.pairs)
            _PairRow(
              currency: pair,
              base: country.base,
              official: fx.whenOrNull(
                  data: (FxSnapshot s) => s.cross(pair, country.base)),
              officialLoading: fx.isLoading,
              parallel: parallel.whenOrNull(
                  data: (List<FxQuote> qs) => _firstOrNull(qs, pair)),
              manual: manual[manualParallelKey(country.country, pair)],
              onEditManual: () =>
                  _editManual(context, ref, country.country, pair),
            ),
          const SizedBox(height: DsSpacing.sm),
          _SourceLine(
            source: fx.whenOrNull(data: (FxSnapshot s) => s.source) ??
                'open.er-api.com',
            updatedAt: fx.whenOrNull(data: (FxSnapshot s) => s.updatedAt),
          ),
        ],
      ),
    );
  }

  static FxQuote? _firstOrNull(List<FxQuote> qs, String currency) {
    for (final FxQuote q in qs) {
      if (q.currency == currency) return q;
    }
    return null;
  }

  Future<void> _editManual(
    BuildContext context,
    WidgetRef ref,
    String countryCode,
    String currency,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ManualParallel? existing =
        ref.read(manualParallelProvider)[manualParallelKey(countryCode, currency)];
    final TextEditingController buy =
        TextEditingController(text: existing?.buy?.toString() ?? '');
    final TextEditingController sell =
        TextEditingController(text: existing?.sell?.toString() ?? '');

    double? parse(String s) =>
        double.tryParse(s.trim().replaceAll(',', '.'));

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${l.marketSetParallel} · $currency / ${country.base}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.parallelManualHint,
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: DsSpacing.md),
            TextField(
              inputFormatters: LatinDigitsFormatter.only,
              controller: buy,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.marketParallelBuy),
            ),
            const SizedBox(height: DsSpacing.sm),
            TextField(
              inputFormatters: LatinDigitsFormatter.only,
              controller: sell,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.marketParallelSell),
            ),
          ],
        ),
        actions: <Widget>[
          if (existing != null)
            TextButton(
              onPressed: () {
                ref
                    .read(manualParallelProvider.notifier)
                    .clear(countryCode, currency);
                Navigator.of(ctx).pop();
              },
              child: Text(l.delete),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(manualParallelProvider.notifier).setRate(
                    country: countryCode,
                    currency: currency,
                    buy: parse(buy.text),
                    sell: parse(sell.text),
                  );
              Navigator.of(ctx).pop();
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
    buy.dispose();
    sell.dispose();
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.currency,
    required this.base,
    required this.official,
    required this.officialLoading,
    required this.parallel,
    this.manual,
    this.onEditManual,
  });

  final String currency;
  final String base;
  final double? official;
  final bool officialLoading;
  final FxQuote? parallel;
  final ManualParallel? manual;
  final VoidCallback? onEditManual;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    // Live parallel takes priority; the user's manual entry is the fallback.
    final double? buy = parallel?.buy ?? manual?.buy;
    final double? sell = parallel?.sell ?? manual?.sell;
    final bool usingManual = parallel?.buy == null &&
        parallel?.sell == null &&
        manual != null &&
        !manual!.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CurrencyFlag.code(currency, width: 20),
              const SizedBox(width: DsSpacing.sm),
              Text('$currency / $base',
                  style: Theme.of(context).textTheme.titleSmall),
              if (usingManual) ...<Widget>[
                const SizedBox(width: DsSpacing.sm),
                _ManualTag(label: l.parallelManualTag),
              ],
              const Spacer(),
              if (onEditManual != null)
                InkWell(
                  onTap: onEditManual,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 15, color: c.brand),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Wrap(
            spacing: DsSpacing.lg,
            runSpacing: DsSpacing.xs,
            children: <Widget>[
              _Stat(
                  label: l.marketOfficial,
                  value: officialLoading && official == null
                      ? '…'
                      : _fmtOrNull(official, l),
                  color: c.textPrimary),
              _Stat(
                  label: l.marketParallelBuy,
                  value: _fmtOrNull(buy, l),
                  color: c.income),
              _Stat(
                  label: l.marketParallelSell,
                  value: _fmtOrNull(sell, l),
                  color: c.expense),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small "manual" chip shown when a parallel value comes from the user.
class _ManualTag extends StatelessWidget {
  const _ManualTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: c.brand, fontWeight: FontWeight.w600)),
    );
  }
}

// --------------------------------------------------------------------------
// Crypto section
// --------------------------------------------------------------------------
class _CryptoSection extends ConsumerWidget {
  const _CryptoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String base = ref.watch(baseCurrencyProvider);
    final double? usdToBase = ref
        .watch(fxSnapshotProvider)
        .whenOrNull(data: (FxSnapshot s) => s.cross('USD', base));
    final AsyncValue<List<CryptoQuote>> crypto = ref.watch(cryptoQuotesProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.currency_bitcoin_rounded, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Text(l.sectionCrypto,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          crypto.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: DsSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => Text(l.marketUnavailable,
                style: Theme.of(context).textTheme.bodySmall),
            data: (List<CryptoQuote> quotes) => Column(
              children: <Widget>[
                for (final CryptoQuote q in quotes)
                  _CryptoRow(quote: q, base: base, usdToBase: usdToBase),
                const SizedBox(height: DsSpacing.sm),
                if (quotes.isNotEmpty)
                  _SourceLine(
                    source: quotes.first.source,
                    updatedAt: quotes.first.updatedAt,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CryptoRow extends StatelessWidget {
  const _CryptoRow(
      {required this.quote, required this.base, required this.usdToBase});
  final CryptoQuote quote;
  final String base;
  final double? usdToBase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final double? localVal = (quote.usd != null && usdToBase != null)
        ? quote.usd! * usdToBase!
        : null;
    final List<double>? spark = quote.sparkline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 12,
                backgroundColor: c.surfaceMuted,
                child: Text(quote.symbol.substring(0, 1),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: c.brand)),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text('${quote.symbol} · ${quote.name}',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (spark != null && spark.length > 1)
                Sparkline(spark, width: 96, height: 30),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Wrap(
            spacing: DsSpacing.lg,
            runSpacing: DsSpacing.xs,
            children: <Widget>[
              _Stat(label: 'USD', value: _fmtOrNull(quote.usd, l), color: c.textPrimary),
              _Stat(label: base, value: _fmtOrNull(localVal, l), color: c.textPrimary),
              _ChangeStat(label: l.change24h, pct: quote.change24h),
              _ChangeStat(label: l.change7d, pct: quote.change7d),
              _Stat(label: l.rateTypeP2P, value: _fmtOrNull(quote.p2p, l), color: c.saving),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Shared small widgets + helpers
// --------------------------------------------------------------------------
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

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
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: color)),
      ],
    );
  }
}

/// A percentage-change stat: green when up, red when down, "—" when unknown.
class _ChangeStat extends StatelessWidget {
  const _ChangeStat({required this.label, required this.pct});
  final String label;
  final double? pct;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color color = pct == null
        ? c.textFaint
        : (pct! >= 0 ? c.income : c.expense);
    final String text = pct == null
        ? '—'
        : '${pct! >= 0 ? '+' : ''}${pct!.toStringAsFixed(2)}%';
    return _Stat(label: label, value: text, color: color);
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.source, required this.updatedAt});
  final String source;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String updated =
        updatedAt == null ? '—' : _fmtUpdated(updatedAt!);
    return Text(
      '${l.marketSource}: $source · ${l.marketUpdated}: $updated',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.textFaint),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final DsColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.brand : colors.surfaceMuted,
      borderRadius: DsRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg, vertical: DsSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onBrand : colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.info_outline_rounded, size: 14, color: c.textFaint),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: c.textFaint)),
        ),
      ],
    );
  }
}

/// Formats a rate/price, or the localized "unavailable" label when null.
String _fmtOrNull(double? v, AppLocalizations l) {
  if (v == null) return l.marketUnavailable;
  final int dp = v >= 100 ? 2 : (v >= 1 ? 4 : 6);
  return NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: dp)
      .format(v);
}

String _fmtUpdated(DateTime dt) {
  final DateTime local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
