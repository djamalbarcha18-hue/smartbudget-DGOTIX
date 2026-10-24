import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/design_system/brand/dgotix_owl.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[DsColors.light]),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('sizes to its height in both forms', (WidgetTester t) async {
    await t.pumpWidget(_host(const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DgotixOwl(size: 44, key: Key('full')),
        DgotixOwl(size: 22, headOnly: true, key: Key('head')),
      ],
    )));
    final Size full = t.getSize(find.byKey(const Key('full')));
    final Size head = t.getSize(find.byKey(const Key('head')));
    expect(full.height, 44);
    expect(full.width, closeTo(44 * 1600 / 1700, 0.01));
    expect(head.height, 22);
    expect(head.width, closeTo(22 * 1360 / 1200, 0.01));
    expect(t.takeException(), isNull);
  });

  testWidgets('the waiting owl keeps moving', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(animate: true)));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.hasRunningAnimations, isTrue);
    // Leaving the screen stops the loop cleanly.
    await t.pumpWidget(_host(const SizedBox()));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('holds still when reduced motion is asked',
      (WidgetTester t) async {
    await t
        .pumpWidget(_host(const DgotixOwl(animate: true), reduceMotion: true));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('the icon form never animates', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(headOnly: true)));
    expect(t.hasRunningAnimations, isFalse);
  });
}
