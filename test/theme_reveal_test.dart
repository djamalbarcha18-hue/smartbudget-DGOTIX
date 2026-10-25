import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/theme/theme_reveal.dart';

void main() {
  Widget app(ValueNotifier<bool> dark, {bool still = false}) =>
      ValueListenableBuilder<bool>(
        valueListenable: dark,
        builder: (BuildContext context, bool d, _) => MaterialApp(
          theme: d ? ThemeData.dark() : ThemeData.light(),
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: still),
            child: ThemeRevealHost(child: child!),
          ),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () => ThemeReveal.run(
                      context,
                      to: Colors.black,
                      () => dark.value = !dark.value),
                  child: const Text('switch'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('the new theme is applied and the old screen wipes away',
      (WidgetTester t) async {
    final ValueNotifier<bool> dark = ValueNotifier<bool>(false);
    await t.pumpWidget(app(dark));
    await t.tap(find.text('switch'));
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
    expect(dark.value, isTrue);
    await t.pump(ThemeReveal.duration ~/ 2);
    // Halfway: the capture of the old screen is still on top.
    expect(find.byType(CustomPaint), findsWidgets);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('without motion the theme simply changes',
      (WidgetTester t) async {
    final ValueNotifier<bool> dark = ValueNotifier<bool>(false);
    await t.pumpWidget(app(dark, still: true));
    await t.tap(find.text('switch'));
    await t.pump();
    expect(dark.value, isTrue);
    expect(t.takeException(), isNull);
  });
}
