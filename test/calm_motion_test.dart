import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/monthly_bars_chart.dart';
import 'package:smartbudget/design_system/motion/ds_motion.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

List<DonutSegment> _ring(double a) => <DonutSegment>[
      DonutSegment(label: 'A', value: a, color: Colors.blue),
      const DonutSegment(label: 'B', value: 30, color: Colors.orange),
    ];

List<MonthPoint> _months(int k) => <MonthPoint>[
      for (int i = 0; i < 12; i++)
        MonthPoint(
          monthIndex: i,
          income: Money(100000 * k, 'EUR'),
          expense: Money(60000 * k, 'EUR'),
          net: Money(40000 * k, 'EUR'),
        ),
    ];

Widget _bars(int k) => SizedBox(
      width: 360,
      child: MonthlyBarsChart(
        points: _months(k),
        income: Colors.green,
        expense: Colors.red,
        net: Colors.blue,
        axis: Colors.grey,
        grid: Colors.black12,
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a score fills from nothing, then moves from where it was',
      (WidgetTester tester) async {
    double shown = -1;
    Widget gauge(double v) => DsEased(
        value: v,
        builder: (_, double x) {
          shown = x;
          return const SizedBox();
        });
    await tester.pumpWidget(_host(gauge(80)));
    expect(shown, 0);
    await tester.pump(); // on screen: it starts
    await tester.pump(const Duration(milliseconds: 300));
    expect(shown, inExclusiveRange(0, 80));
    await tester.pumpAndSettle();
    expect(shown, 80);
    // Another month: from 80 to 60, not from 0.
    await tester.pumpWidget(_host(gauge(60)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown, inExclusiveRange(60, 80));
    await tester.pumpAndSettle();
    expect(shown, 60);
  });

  testWidgets('"reduce motion" on: the score is simply there',
      (WidgetTester tester) async {
    double shown = -1;
    await tester.pumpWidget(_host(
        DsEased(
            value: 80,
            builder: (_, double x) {
              shown = x;
              return const SizedBox();
            }),
        reduce: true));
    await tester.pump();
    await tester.pump();
    expect(shown, 80);
  });

  testWidgets('the ring draws itself once, and again for new figures only',
      (WidgetTester tester) async {
    Widget ring(double a, {int? chosen}) => DonutChart(
          segments: _ring(a),
          selectedIndex: chosen,
          onSelectionChanged: (_) {},
        );
    await tester.pumpWidget(_host(ring(70)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    // Choosing a slice doesn't redraw the ring (only the centre fades).
    await tester.pumpWidget(_host(ring(70, chosen: 0)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.hasRunningAnimations, isFalse);

    // Other figures (another month): drawn again.
    await tester.pumpWidget(_host(ring(40, chosen: 0)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('a ring further down the page waits to be scrolled to',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(ListView(
      children: <Widget>[
        const SizedBox(height: 2000),
        Center(child: DonutChart(segments: _ring(70))),
      ],
    )));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse); // unseen: not drawn yet
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue); // in view: drawing
    await tester.pumpAndSettle();
  });

  testWidgets('a ring in a page view further down waits for the page scroll',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(ListView(
      children: <Widget>[
        const SizedBox(height: 2000),
        SizedBox(
          height: 200,
          child: PageView(children: <Widget>[
            Center(child: DonutChart(segments: _ring(70))),
          ]),
        ),
      ],
    )));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('"reduce motion" on: the ring is drawn at once',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_host(DonutChart(segments: _ring(70)), reduce: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the bars rise once, and again for new figures only',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(_bars(1)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(_bars(1)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_host(_bars(2)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('"reduce motion" on: the bars are simply there',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(_bars(1), reduce: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a new figure rolls in over the old one, briefly',
      (WidgetTester tester) async {
    Widget card(String v, {bool reduce = false}) =>
        _host(SizedBox(width: 220, child: KpiCard(label: 'Income', value: v)),
            reduce: reduce);
    await tester.pumpWidget(card('€ 1,000.00'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(card('€ 2,500.00'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('€ 1,000.00'), findsOneWidget); // on its way out
    expect(find.text('€ 2,500.00'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('€ 1,000.00'), findsNothing);
  });

  testWidgets('"reduce motion" on: straight to the new figure',
      (WidgetTester tester) async {
    Widget card(String v) =>
        _host(SizedBox(width: 220, child: KpiCard(label: 'Income', value: v)),
            reduce: true);
    await tester.pumpWidget(card('€ 2,500.00'));
    await tester.pump();
    await tester.pumpWidget(card('€ 3,000.00'));
    await tester.pump();
    await tester.pump(); // no time passes: nothing to watch
    expect(find.text('€ 2,500.00'), findsNothing);
    expect(find.text('€ 3,000.00'), findsOneWidget);
  });
}
