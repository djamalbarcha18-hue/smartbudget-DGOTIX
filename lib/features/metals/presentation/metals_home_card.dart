import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// On the home page: gold and silver on its face — today's price of a gram,
/// and for someone who keeps metals, what all of them are worth and how it
/// has moved. A tap opens the page of the four metals. Kept apart from the
/// wallets: it is not money in hand.
class MetalsHomeCard extends ConsumerWidget {
  const MetalsHomeCard({super.key, this.bottomGap = DsSpacing.gridGap});

  final double bottomGap;

  static const List<Metal> _face = <Metal>[Metal.gold, Metal.silver];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MetalHolding> holdings =
        ref.watch(metalHoldingsProvider).valueOrNull ?? const <MetalHolding>[];
    final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);
    final bool keeps = holdings.isNotEmpty;
    if (!keeps && !_face.any(prices.containsKey)) {
      return const SizedBox.shrink();
    }
    if (keeps) ref.watch(metalHistoryRecorderProvider);

    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final MetalsSummary s = ref.watch(metalsSummaryProvider);
    final Color ink = MetalPalette.of(Metal.gold).ink;
    final bool masked = MoneyPrivacy.maybeOf(context)?.masked ?? false;
    final List<double> line = !keeps
        ? const <double>[]
        : <double>[
            for (final MetalPoint p in MetalHistory.series(
                ref.watch(metalHistoryProvider),
                ref.watch(baseCurrencyProvider),
                AppClock.now(),
                days: 30))
              p.minor.toDouble(),
          ];
    final ({Money paid, Money value})? paid = s.paidTotal;
    final double? gain = paid == null || paid.paid.minorUnits <= 0
        ? null
        : (paid.value.minorUnits - paid.paid.minorUnits) / paid.paid.minorUnits;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: MetalPlate(
        metal: Metal.gold,
        onTap: () => context.go('/metals'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const _BarStack(_face),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(l.navMetals,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleSmall?.copyWith(
                                    color: ink, fontWeight: FontWeight.w800)),
                          ),
                          if (keeps) PrivacyEyeButton.of(context, color: ink),
                        ],
                      ),
                      if (keeps) ...<Widget>[
                        Text(
                          masked
                              ? MoneyPrivacy.mask
                              : s.unpriced.isNotEmpty && s.total.minorUnits == 0
                                  ? '—'
                                  : MoneyFormatter.format(s.total),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                              color: ink, fontWeight: FontWeight.w900),
                        ),
                        if (gain != null && !masked)
                          Text(
                            l.metalsSinceBought(
                                '\u2066${gain >= 0 ? '+' : ''}${(gain * 100).toStringAsFixed(1)}%\u2069'),
                            style: t.labelMedium?.copyWith(
                                color: ink, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ],
                  ),
                ),
                if (line.length >= 2 && !masked)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: DsSpacing.sm),
                    child: SizedBox(
                      width: 64,
                      height: 30,
                      child: CustomPaint(
                        painter: _LinePainter(line, ink,
                            rtl: Directionality.of(context) ==
                                TextDirection.rtl),
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right_rounded,
                    color: ink.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: DsSpacing.sm),
            Row(
              children: <Widget>[
                for (final Metal m in _face) ...<Widget>[
                  if (m != _face.first) const SizedBox(width: DsSpacing.sm),
                  Expanded(child: _PriceChip(metal: m, price: prices[m])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's price of a gram of the pure metal, on a small plate of it.
class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.metal, required this.price});
  final Metal metal;
  final MetalPrice? price;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final Color ink = MetalPalette.of(metal).ink;
    final MetalPrice? p = price;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: MetalPalette.of(metal).polish,
        border: Border.all(
            color: MetalPalette.of(metal).edge.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: <Widget>[
          MetalBar(metal: metal, width: 30),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    '${MetalText.name(l, metal)} · ${MetalText.purity(l, metal, metal == Metal.gold ? 24 : 999)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(
                        color: ink.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    p == null
                        ? '—'
                        : l.metalsPerGram(MoneyFormatter.format(
                            Money.fromDouble(p.perGram, p.currency))),
                    maxLines: 1,
                    style: t.titleSmall
                        ?.copyWith(color: ink, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bars of each metal kept, stacked as bullion is: one bar alone, two side
/// by side, three as a small pyramid.
class _BarStack extends StatelessWidget {
  const _BarStack(this.metals);
  final List<Metal> metals;

  @override
  Widget build(BuildContext context) {
    const double w = 48;
    final List<(Metal, double, double)> placed = switch (metals.length) {
      1 => <(Metal, double, double)>[(metals[0], 14, 12)],
      2 => <(Metal, double, double)>[
          (metals[0], 0, 16),
          (metals[1], 40, 16),
        ],
      _ => <(Metal, double, double)>[
          (metals[1], 0, 26),
          (metals[2], 40, 26),
          (metals[0], 20, 2),
        ],
    };
    return SizedBox(
      width: 88,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final (Metal m, double x, double y) in placed)
            PositionedDirectional(
              start: x,
              top: y,
              child: MetalBar(metal: m, width: metals.length == 1 ? 60 : w),
            ),
        ],
      ),
    );
  }
}

/// The last weeks' value as a thin line in the metal's ink.
class _LinePainter extends CustomPainter {
  _LinePainter(this.points, this.color, {required this.rtl});
  final List<double> points;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    double lo = points.first, hi = points.first;
    for (final double p in points) {
      if (p < lo) lo = p;
      if (p > hi) hi = p;
    }
    final double span = hi - lo == 0 ? 1 : hi - lo;
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final double f = i / (points.length - 1);
      final Offset o = Offset((rtl ? 1 - f : f) * size.width,
          size.height - (points[i] - lo) / span * size.height);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: 0.8));
    final double f = rtl ? 0 : size.width;
    canvas.drawCircle(
        Offset(f, size.height - (points.last - lo) / span * size.height),
        3,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.color != color || old.rtl != rtl;
}
