import 'package:flutter/gestures.dart';
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

  testWidgets('the smiling owl paints and stays still', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(smiling: true)));
    expect(t.takeException(), isNull);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('the icon form never animates', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(headOnly: true)));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('an interactive owl hops when tapped', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(interactive: true)));
    await t.tap(find.byType(DgotixOwl));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });

  testWidgets('its eyes follow the pointer, then rest', (WidgetTester t) async {
    await t
        .pumpWidget(_host(const DgotixOwl(interactive: true, smiling: true)));
    final TestGesture g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    await g.moveTo(const Offset(20, 20));
    await t.pump(const Duration(milliseconds: 200));
    await g.moveTo(const Offset(700, 500));
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
    // After a quiet moment it rests (and smiles again).
    await t.pump(const Duration(seconds: 3));
    await g.removePointer();
    // Leaving the screen unhooks it from the pointer.
    await t.pumpWidget(_host(const SizedBox()));
    await g.addPointer(location: Offset.zero);
    await g.moveTo(const Offset(30, 30));
    expect(t.takeException(), isNull);
    await g.removePointer();
  });

  testWidgets('an answer makes it hop; moods paint', (WidgetTester t) async {
    for (final OwlMood m in OwlMood.values) {
      await t.pumpWidget(
          _host(DgotixOwl(headOnly: true, interactive: true, mood: m)));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
    }
    await t.pumpWidget(_host(const DgotixOwl(interactive: true)));
    await t.pumpWidget(
        _host(const DgotixOwl(interactive: true, mood: OwlMood.happy)));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('no life under reduced motion', (WidgetTester t) async {
    await t.pumpWidget(
        _host(const DgotixOwl(interactive: true), reduceMotion: true));
    await t.tap(find.byType(DgotixOwl));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('dances while signing in, then stops', (WidgetTester t) async {
    await t.pumpWidget(
        _host(const DgotixOwl(interactive: true, mood: OwlMood.dancing)));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpWidget(_host(const DgotixOwl(interactive: true)));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.hasRunningAnimations, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('shakes its head once when angry', (WidgetTester t) async {
    await t.pumpWidget(_host(const DgotixOwl(interactive: true)));
    await t.pumpWidget(
        _host(const DgotixOwl(interactive: true, mood: OwlMood.angry)));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('dances and frowns stay still under reduced motion',
      (WidgetTester t) async {
    for (final OwlMood m in <OwlMood>[OwlMood.dancing, OwlMood.angry]) {
      await t.pumpWidget(
          _host(DgotixOwl(interactive: true, mood: m), reduceMotion: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.hasRunningAnimations, isFalse);
    }
  });
}
