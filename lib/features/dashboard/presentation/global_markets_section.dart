import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/presentation/sparkline.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// One global-market indicator tile (label + value + change/sub), data-backed.
class _Indicator {
  const _Indicator({
    required this.label,
    required this.value,
    this.sub,
    this.changePct,
    this.spark,
  });
  final String label;
  final String value;
  final String? sub;
  final double? changePct;
  final List<double>? spark;
}

/// A cohesive "Global markets" strip on the dashboard: live gold/silver, crypto
/// and major FX pulled from the same keyless sources as the Markets page. Every
/// figure is real; anything a source doesn't provide shows "—" (never faked).
class GlobalMarketsSection extends ConsumerWidget {
  const GlobalMarketsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';

    final AsyncValue<FxSnapshot> fx = ref.watch(fxSnapshotProvider);
    final AsyncValue<List<CryptoQuote>> crypto = ref.watch(cryptoQuotesProvider);
    final AsyncValue<List<CommodityQuote>> metals =
        ref.watch(commodityQuotesProvider(MarketCategory.preciousMetals));

    final List<_Indicator> tiles = <_Indicator>[
      _metal(metals, 'XAU', ar),
      _metal(metals, 'XAG', ar),
      _crypto(crypto, 'BTC'),
      _crypto(crypto, 'ETH'),
      _fx(fx, 'EUR', l),
      _fx(fx, 'GBP', l),
      _fx(fx, 'JPY', l),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DsSectionHeader(
                  title: l.sectionGlobalMarkets,
                  icon: Icons.public_outlined),
            ),
            TextButton(
              onPressed: () => context.go('/markets'),
              child: Text(l.viewDetails),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.md),
        GlassCard(
          child: Wrap(
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              for (final _Indicator t in tiles)
                SizedBox(width: 168, child: _MarketTile(indicator: t)),
            ],
          ),
        ),
      ],
    );
  }

  _Indicator _metal(
      AsyncValue<List<CommodityQuote>> async, String code, bool ar) {
    final CommodityQuote? q = async.whenOrNull(
        data: (List<CommodityQuote> list) {
      for (final CommodityQuote c in list) {
        if (c.code == code) return c;
      }
      return null;
    });
    final String label = q == null ? code : (ar ? q.nameAr : q.nameEn);
    return _Indicator(
      label: label,
      value: q?.priceUsd == null ? '—' : _fmtNum(q!.priceUsd!),
      sub: q?.priceUsd == null ? null : q!.unitLabel,
      changePct: q?.change24h,
    );
  }

  _Indicator _crypto(AsyncValue<List<CryptoQuote>> async, String symbol) {
    final CryptoQuote? q = async.whenOrNull(
        data: (List<CryptoQuote> list) {
      for (final CryptoQuote c in list) {
        if (c.symbol == symbol) return c;
      }
      return null;
    });
    return _Indicator(
      label: symbol,
      value: q?.usd == null ? '—' : _fmtNum(q!.usd!),
      sub: 'USD',
      changePct: q?.change24h,
      spark: q?.sparkline,
    );
  }

  _Indicator _fx(AsyncValue<FxSnapshot> async, String code, AppLocalizations l) {
    final double? rate = async.whenOrNull(
        data: (FxSnapshot s) => s.ratesPerUsd[code]);
    return _Indicator(
      label: code,
      value: rate == null ? '—' : _fmtNum(rate),
      sub: l.perUsd,
    );
  }

  static String _fmtNum(double v) {
    final int dp = v >= 1000 ? 0 : (v >= 1 ? 2 : 4);
    return NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: dp)
        .format(v);
  }
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({required this.indicator});
  final _Indicator indicator;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final double? pct = indicator.changePct;
    final Color changeColor =
        pct == null ? c.textFaint : (pct >= 0 ? c.income : c.expense);

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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(indicator.label,
                    style: t.labelMedium?.copyWith(color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (indicator.spark != null && indicator.spark!.length > 1)
                Sparkline(indicator.spark!, width: 46, height: 18),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(indicator.value,
              style: t.titleMedium?.copyWith(
                  color: c.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              if (indicator.sub != null)
                Text(indicator.sub!,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              if (indicator.sub != null && pct != null)
                Text('  ·  ',
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              if (pct != null)
                Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: t.labelSmall?.copyWith(color: changeColor)),
            ],
          ),
        ],
      ),
    );
  }
}
