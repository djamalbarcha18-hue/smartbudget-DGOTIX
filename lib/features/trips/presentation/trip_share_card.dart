import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The four card backgrounds.
enum TripCardColor {
  green(Color(0xFF12705A)),
  blue(Color(0xFF1C5FAE)),
  orange(Color(0xFFB4441E)),
  purple(Color(0xFF5A48B8));

  const TripCardColor(this.color);
  final Color color;

  String label(AppLocalizations l) => switch (this) {
        TripCardColor.green => l.tripColorGreen,
        TripCardColor.blue => l.tripColorBlue,
        TripCardColor.orange => l.tripColorOrange,
        TripCardColor.purple => l.tripColorPurple,
      };
}

/// A story card (9:16) about a trip, exported at 1080 × 1920. Every size is
/// a fraction of the card, so it looks the same at any preview size. The
/// top and bottom [safeZone] stay free of content: Instagram covers them.
class TripShareCard extends StatelessWidget {
  const TripShareCard({
    super.key,
    required this.report,
    required this.color,
    required this.percentOnly,
    this.destination,
    this.photo,
    this.showBranding = true,
  });

  /// Width of the card as laid out; exported with pixel ratio 1080 / this.
  static const double logicalWidth = 360;
  static const double logicalHeight = logicalWidth * 16 / 9;
  static const double exportWidth = 1080;
  static const double exportPixelRatio = exportWidth / logicalWidth;

  /// Share of the height kept clear at the top and at the bottom.
  static const double safeZone = 0.13;

  /// The hero picture's share of the height (photos are cropped to it).
  static const double heroShare = 0.5;
  static const double photoAspect = 1 / (heroShare * 16 / 9);

  final TripReport report;
  final TripCardColor color;
  final bool percentOnly;
  final Destination? destination;

  /// The user's picture; else the destination's own picture, if any.
  final Uint8List? photo;

  /// The logo and QR code (always shown for now; see canRemoveBranding).
  final bool showBranding;

  // Fixed colours: the card is a picture and doesn't follow the app theme.
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _track = Color(0xFFE5E7EB);
  static const Color _good = Color(0xFF059669);
  static const Color _bad = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) =>
            _card(context, box.maxWidth, box.maxHeight),
      ),
    );
  }

  Widget _card(BuildContext context, double w, double h) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang lang = appLangOf(context);
    final double u = w / 100;
    final TextStyle base =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: Colors.white, height: 1.25, letterSpacing: 0);
    final Trip trip = report.trip;
    final String? asset = destination?.image;
    final bool hasPicture = photo != null || asset != null;

    final String kicker = switch (TripMath.status(trip, AppClock.now())) {
      TripStatus.ended => l.tripCardBack,
      TripStatus.active => l.tripCardNow,
      TripStatus.upcoming => l.tripCardNext,
    };

    final Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(kicker,
                  style: base.copyWith(
                      fontSize: 3.8 * u,
                      color: Colors.white.withValues(alpha: 0.9))),
            ),
            if (showBranding) _brandTag(base, u),
          ],
        ),
        SizedBox(height: 1 * u),
        Text(
          destination?.nameFor(lang) ?? trip.destination,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: 8.6 * u,
            fontWeight: FontWeight.w800,
            shadows: hasPicture ? _textShadow : null,
          ),
        ),
        SizedBox(height: 1.4 * u),
        Wrap(
          spacing: 4 * u,
          runSpacing: 1 * u,
          children: <Widget>[
            _meta(Icons.calendar_today_outlined,
                l.tripDaysCount(TripDays.total(trip)), base, u),
            if (trip.travelers > 1)
              _meta(Icons.group_outlined, l.tripTravelersCount(trip.travelers),
                  base, u),
          ],
        ),
      ],
    );

    // The picture fills everything above the panel and is never covered by
    // it: a gentle shade at the top keeps the place readable, and its lower
    // edge melts into the card colour. With a picture the panel is shorter,
    // so the picture keeps more room.
    return ClipRect(
      child: ColoredBox(
        color: color.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (hasPicture) ...<Widget>[
                    if (photo != null)
                      Image.memory(photo!, fit: BoxFit.cover)
                    else
                      Image.asset(asset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink()),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0),
                            color.color,
                          ],
                          stops: const <double>[0, 0.45, 0.82, 1],
                        ),
                      ),
                    ),
                  ] else
                    PositionedDirectional(
                      top: h * 0.16,
                      end: w * 0.05,
                      child: Icon(destinationIcon(destination?.icon),
                          size: w * 0.42,
                          color: Colors.white.withValues(alpha: 0.13)),
                    ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        w * 0.07, h * safeZone, w * 0.07, 0),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.topStart,
                        child: SizedBox(width: w * 0.86, child: header),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  w * 0.07, 2 * u, w * 0.07, h * safeZone),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: h * 0.5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: w * 0.86,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _panel(context, l, lang, base, u, compact: hasPicture),
                        if (showBranding) ...<Widget>[
                          SizedBox(height: 3.2 * u),
                          _footer(l, base, u),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Shadow> _textShadow = <Shadow>[
    Shadow(color: Color(0x66000000), blurRadius: 8),
  ];

  Widget _meta(IconData icon, String text, TextStyle base, double u) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 3.6 * u, color: Colors.white),
          SizedBox(width: 1.2 * u),
          Text(text, style: base.copyWith(fontSize: 3.4 * u)),
        ],
      );

  /// The white panel: total, categories, and the budget when there is one.
  /// [compact] (with a picture): the categories as one short legend and no
  /// repeated tiles, so the picture keeps more of the card.
  Widget _panel(BuildContext context, AppLocalizations l, AppLang lang,
      TextStyle base, double u,
      {bool compact = false}) {
    final TripReport r = report;
    final TextStyle ink = base.copyWith(color: _ink);
    final TextStyle muted = base.copyWith(color: _muted, fontSize: 3 * u);
    String money(Money m) => MoneyFormatter.format(m);
    String pct(double share) => '${(share * 100).round()}%';

    // Largest categories, the rest together as "Other".
    final int keep = compact ? 3 : (r.hasBudget ? 3 : 5);
    final List<TripCategoryShare> cats = r.categories.length <= keep + 1
        ? r.categories
        : <TripCategoryShare>[
            ...r.categories.take(keep),
            TripCategoryShare(
              'أخرى',
              Money(
                  r.categories.skip(keep).fold<int>(0,
                      (int a, TripCategoryShare c) => a + c.amount.minorUnits),
                  r.currency),
              r.categories.skip(keep).fold<double>(
                  0, (double a, TripCategoryShare c) => a + c.share),
            ),
          ];

    final Widget headline;
    if (!percentOnly) {
      headline = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.tripTotalSpent, style: muted),
                Text(money(r.spent),
                    style: ink.copyWith(
                        fontSize: 8 * u, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (r.perPerson != null)
                Text(l.tripPerPerson(money(r.perPerson!)), style: muted),
              Text(l.tripPerDay(money(r.dailyAverage)), style: muted),
            ],
          ),
        ],
      );
    } else if (r.hasBudget) {
      headline = Text(l.tripUsedPct(r.usedPct!),
          style: ink.copyWith(fontSize: 5.2 * u, fontWeight: FontWeight.w800));
    } else {
      headline = Text(l.tripByCategory,
          style: ink.copyWith(fontSize: 4.4 * u, fontWeight: FontWeight.w700));
    }

    final List<Widget> rows = <Widget>[
      for (int i = 0; i < cats.length; i++)
        Padding(
          padding: EdgeInsetsDirectional.only(top: 1.6 * u),
          child: Row(
            children: <Widget>[
              Container(
                width: 2.2 * u,
                height: 2.2 * u,
                decoration: BoxDecoration(
                  color: cats[i].category == 'أخرى' && i == keep
                      ? DsChartPalette.other
                      : DsChartPalette.at(i),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2 * u),
              Icon(tripCategoryIcon(cats[i].category),
                  size: 4 * u, color: _muted),
              SizedBox(width: 1.6 * u),
              Expanded(
                child: Text(Catalog.label(cats[i].category, lang: lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ink.copyWith(fontSize: 3.6 * u)),
              ),
              Text(percentOnly ? pct(cats[i].share) : money(cats[i].amount),
                  style: ink.copyWith(
                      fontSize: 3.8 * u, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
    ];

    return Container(
      padding: EdgeInsets.all(5 * u),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5 * u),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          headline,
          SizedBox(height: 3 * u),
          _segments(cats, u, keep),
          SizedBox(height: 0.6 * u),
          if (compact)
            Padding(
              padding: EdgeInsetsDirectional.only(top: 2.2 * u),
              child: Wrap(
                spacing: 3.4 * u,
                runSpacing: 1.2 * u,
                children: <Widget>[
                  for (int i = 0; i < cats.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 2 * u,
                          height: 2 * u,
                          decoration: BoxDecoration(
                            color: cats[i].category == 'أخرى' && i == keep
                                ? DsChartPalette.other
                                : DsChartPalette.at(i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.2 * u),
                        Text(
                          '${Catalog.label(cats[i].category, lang: lang)} '
                          '${percentOnly ? pct(cats[i].share) : money(cats[i].amount)}',
                          style: ink.copyWith(fontSize: 3.1 * u),
                        ),
                      ],
                    ),
                ],
              ),
            )
          else
            ...rows,
          if (r.hasBudget) ...<Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3 * u),
              child: const Divider(height: 1, color: _track),
            ),
            _bar(l.tripPlanned, percentOnly ? '100%' : money(r.budget!),
                r.budget!.minorUnits / _scale, color.color, ink, muted, u),
            SizedBox(height: 2 * u),
            _bar(
                l.tripActual,
                percentOnly ? '${r.usedPct}%' : money(r.spent),
                r.spent.minorUnits / _scale,
                r.overBudget ? _bad : _good,
                ink,
                muted,
                u),
            if (r.underBudget) ...<Widget>[
              SizedBox(height: 3 * u),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 3 * u, vertical: 1.2 * u),
                  decoration: BoxDecoration(
                    color: _good.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10 * u),
                  ),
                  child: Text(l.tripSavedPct(r.savedPct!),
                      style: ink.copyWith(
                          color: _good,
                          fontSize: 3.6 * u,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
            if (!compact) SizedBox(height: 3 * u),
            if (!compact)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _tile(
                      l.tripDailyAverage,
                      percentOnly
                          ? '${r.dailyPctOfBudget}%'
                          : money(r.dailyAverage),
                      ink,
                      muted,
                      u),
                  _tile(
                      r.overBudget ? l.tripOverBudget : l.tripSavedLabel,
                      percentOnly
                          ? '${r.overBudget ? r.overPct : (r.savedPct ?? 0)}%'
                          : money(r.overBudget
                              ? r.spent - r.budget!
                              : r.difference!),
                      ink.copyWith(color: r.overBudget ? _bad : _good),
                      muted,
                      u),
                  if (r.top != null)
                    _tile(
                        l.tripTopCategory,
                        Catalog.label(r.top!.category, lang: lang),
                        ink,
                        muted,
                        u),
                ],
              ),
          ],
        ],
      ),
    );
  }

  double get _scale {
    final TripReport r = report;
    final int a = r.budget!.minorUnits;
    final int b = r.spent.minorUnits;
    return (a > b ? a : b).toDouble();
  }

  Widget _segments(List<TripCategoryShare> cats, double u, int keep) =>
      SizedBox(
        height: 2.6 * u,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < cats.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: 0.8 * u),
              Expanded(
                flex: (cats[i].share * 1000).round().clamp(1, 1000),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cats[i].category == 'أخرى' && i == keep
                        ? DsChartPalette.other
                        : DsChartPalette.at(i),
                    borderRadius: BorderRadius.circular(2 * u),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _bar(String label, String value, double ratio, Color fill,
          TextStyle ink, TextStyle muted, double u) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label, style: muted)),
              Text(value,
                  style: ink.copyWith(
                      fontSize: 3.4 * u, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 1 * u),
          ClipRRect(
            borderRadius: BorderRadius.circular(2 * u),
            child: SizedBox(
              height: 2.2 * u,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(child: ColoredBox(color: _track)),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: ratio.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: ColoredBox(color: fill),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _tile(String label, String value, TextStyle ink, TextStyle muted,
          double u) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted.copyWith(fontSize: 2.8 * u)),
            SizedBox(height: 0.6 * u),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ink.copyWith(
                    fontSize: 3.6 * u, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  /// The logo, the line, and the QR code to the app.
  /// The app icon, rounded like on a phone.
  Widget _appIcon(double size) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(appIconAsset, width: size, height: size),
      );

  static const String appIconAsset = 'assets/brand/app-icon.png';

  /// The fixed brand mark at the top: icon + "SmartBudget".
  Widget _brandTag(TextStyle base, double u) => Container(
        padding: EdgeInsetsDirectional.fromSTEB(1 * u, 1 * u, 2.6 * u, 1 * u),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10 * u),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _appIcon(5.6 * u),
              SizedBox(width: 1.6 * u),
              Text(AppConfig.appName,
                  style: base.copyWith(
                      fontSize: 3.2 * u, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  /// The logo lockup ("DGOTIX · SmartBudget" with the app icon), the line,
  /// and the QR code to the app.
  Widget _footer(AppLocalizations l, TextStyle base, double u) => Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // The brand reads left to right in every language.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _appIcon(9 * u),
                      SizedBox(width: 2.2 * u),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SvgPicture.asset(
                            'assets/brand/dgotix-logo-mono.svg',
                            height: 3.8 * u,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          SizedBox(height: 0.6 * u),
                          Text(AppConfig.appName,
                              style: base.copyWith(
                                  fontSize: 3.8 * u,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3 * u)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.8 * u),
                Text(l.tripCardTracked,
                    style: base.copyWith(
                        fontSize: 3.3 * u, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(width: 3 * u),
          ClipRRect(
            borderRadius: BorderRadius.circular(2 * u),
            child: SvgPicture.string(
              ShareQr.svg(AppConfig.appShareUrl, size: 256),
              width: 19 * u,
              height: 19 * u,
            ),
          ),
        ],
      );
}
