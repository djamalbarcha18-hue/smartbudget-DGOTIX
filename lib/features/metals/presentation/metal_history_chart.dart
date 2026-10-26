import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What the user's metals were worth, day by day, over 30 days, 3 months, a
/// year or all the days noted.
class MetalHistoryCard extends ConsumerStatefulWidget {
  const MetalHistoryCard({super.key});

  @override
  ConsumerState<MetalHistoryCard> createState() => _MetalHistoryCardState();
}

class _MetalHistoryCardState extends ConsumerState<MetalHistoryCard> {
  int? _days = 30;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<MetalPoint> series = MetalHistory.series(
        ref.watch(metalHistoryProvider),
        ref.watch(baseCurrencyProvider),
        AppClock.now(),
        days: _days);
    final double? change = series.length < 2 || series.first.minor <= 0
        ? null
        : (series.last.minor - series.first.minor) / series.first.minor;

    return GlassCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(title: l.metalsHistory, icon: Icons.timeline_rounded),
          const SizedBox(height: DsSpacing.sm),
          Wrap(
            spacing: DsSpacing.xs,
            runSpacing: DsSpacing.xs,
            children: <Widget>[
              for (final (int? days, String label) in <(int?, String)>[
                (30, l.metalsRange30),
                (90, l.metalsRange90),
                (365, l.metalsRange365),
                (null, l.metalsRangeAll),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _days == days,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _days = days),
                ),
            ],
          ),
          if (change != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Text(
              l.metalsHistoryChange(
                  '\u2066${change >= 0 ? '+' : ''}${(change * 100).toStringAsFixed(1)}%\u2069'),
              style: t.labelLarge
                  ?.copyWith(color: change >= 0 ? c.income : c.expense),
            ),
          ],
          const SizedBox(height: DsSpacing.md),
          if (series.length < 2)
            Text(l.metalsHistoryEmpty,
                style: t.bodyMedium?.copyWith(color: c.textMuted))
          else ...<Widget>[
            SizedBox(
              height: 170,
              child: CustomPaint(
                painter: _ChartPainter(
                  series,
                  line: MetalPalette.of(Metal.gold).dark,
                  fill: MetalPalette.of(Metal.gold).mid,
                  grid: c.border,
                  label: c.textMuted,
                  locale: Localizations.localeOf(context),
                  direction: Directionality.of(context),
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(l.metalsHistoryNote,
                style: t.bodySmall?.copyWith(color: c.textFaint)),
          ],
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(
    this.points, {
    required this.line,
    required this.fill,
    required this.grid,
    required this.label,
    required this.locale,
    required this.direction,
  });

  final List<MetalPoint> points;
  final Color line;
  final Color fill;
  final Color grid;
  final Color label;
  final Locale locale;
  final TextDirection direction;

  TextPainter _text(String s, {double size = 10.5}) => TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: size, color: label)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    int lo = points.first.minor;
    int hi = points.first.minor;
    for (final MetalPoint p in points) {
      if (p.minor < lo) lo = p.minor;
      if (p.minor > hi) hi = p.minor;
    }
    // A little air above and below; a flat line sits in the middle.
    final double pad = hi == lo ? (hi == 0 ? 1 : hi * 0.05) : (hi - lo) * 0.18;
    final double top = hi + pad;
    final double bottom = lo - pad;

    const double axis = 18; // dates under the chart
    final double h = size.height - axis;
    final double w = size.width;
    final DateTime first = points.first.day;
    final int span = points.last.day.difference(first).inDays;
    // Time runs with the reading direction.
    double x(MetalPoint p) {
      final double f = span == 0 ? 1 : p.day.difference(first).inDays / span;
      return direction == TextDirection.rtl ? w * (1 - f) : w * f;
    }

    double y(num v) => h - (v - bottom) / (top - bottom) * h;

    // Guide lines at the highest and lowest value, with their amounts.
    final Paint guide = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final String cur = points.first.currency;
    for (final int v in <int>{hi, lo}) {
      final double gy = y(v);
      for (double gx = 0; gx < w; gx += 8) {
        canvas.drawLine(Offset(gx, gy), Offset(gx + 4, gy), guide);
      }
      final TextPainter tp =
          _text('\u2066${MoneyFormatter.format(Money(v, cur))}\u2069');
      final double tx = direction == TextDirection.rtl ? w - tp.width : 0;
      // The highest above its line, the lowest under it: the curve never
      // goes there.
      tp.paint(canvas,
          Offset(tx, v == hi && hi != lo ? gy - tp.height - 2 : gy + 2));
    }

    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final Offset o = Offset(x(points[i]), y(points[i].minor));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    final Path area = Path.from(path)
      ..lineTo(x(points.last), h)
      ..lineTo(x(points.first), h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            fill.withValues(alpha: 0.45),
            fill.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = line,
    );

    // Today.
    final Offset end = Offset(x(points.last), y(points.last.minor));
    canvas.drawCircle(end, 6, Paint()..color = fill.withValues(alpha: 0.35));
    canvas.drawCircle(end, 3.5, Paint()..color = line);

    // First and last day under the chart.
    final TextPainter a = _text(shortDayText(locale, first));
    final TextPainter b = _text(shortDayText(locale, points.last.day));
    final double ay = size.height - a.height;
    if (direction == TextDirection.rtl) {
      a.paint(canvas, Offset(w - a.width, ay));
      b.paint(canvas, Offset(0, ay));
    } else {
      a.paint(canvas, Offset(0, ay));
      b.paint(canvas, Offset(w - b.width, ay));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points ||
      old.line != line ||
      old.grid != grid ||
      old.direction != direction;
}
