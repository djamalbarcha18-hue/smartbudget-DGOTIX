import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/design_system/theme/ds_readable.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Readability on a phone: larger text and icons, 44×44 icon buttons, and
/// nothing changed on tablets and desktops.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<BuildContext> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext inside;
    await tester.pumpWidget(MaterialApp(
      theme: DsTheme.dark(),
      builder: (BuildContext _, Widget? child) => DsReadable(child: child!),
      home: Scaffold(
        body: Builder(builder: (BuildContext context) {
          inside = context;
          return Column(children: <Widget>[
            const Icon(Icons.home, size: 18),
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.close, size: 16)),
            const Text('x', style: TextStyle(fontSize: 10)),
          ]);
        }),
      ),
    ));
    return inside;
  }

  /// The size a style is drawn at.
  double drawn(BuildContext c, TextStyle? s) =>
      MediaQuery.textScalerOf(c).scale(s!.fontSize!);

  for (final double width in <double>[320, 360, 390, 430]) {
    testWidgets('phone $width wide: the sizes asked for',
        (WidgetTester tester) async {
      final BuildContext c = await pump(tester, width);
      final TextTheme t = Theme.of(c).textTheme;
      // Body text 15–16 at least, secondary 14 at least.
      expect(drawn(c, t.bodyMedium), closeTo(15.5, 0.01));
      expect(drawn(c, t.bodyLarge), closeTo(16.5, 0.01));
      expect(drawn(c, t.bodySmall), closeTo(14, 0.01));
      expect(drawn(c, t.titleSmall), greaterThanOrEqualTo(14));
      // Card titles 19–21, page titles 21–23.
      expect(drawn(c, t.titleMedium), closeTo(19, 0.01));
      expect(drawn(c, t.titleLarge), closeTo(21, 0.01));
      expect(drawn(c, t.headlineSmall), closeTo(23, 0.01));
      // The big figures keep their size.
      expect(drawn(c, t.displaySmall), closeTo(34, 0.01));
      expect(drawn(c, t.headlineMedium), closeTo(26, 0.01));
      // The smallest labels: 10.5 → 12.5.
      expect(drawn(c, t.labelSmall), closeTo(12.5, 0.01));
      // Icons 15% larger; a fixed-size label too.
      expect(tester.getSize(find.byIcon(Icons.home)).width,
          closeTo(18 * 1.15, 0.01));
      expect(MediaQuery.textScalerOf(c).scale(10), closeTo(11.5, 0.01));
      // An icon button is at least 44×44 to press.
      final Size button = tester.getSize(find.byType(IconButton));
      expect(button.width, greaterThanOrEqualTo(DsReadable.minTapTarget));
      expect(button.height, greaterThanOrEqualTo(DsReadable.minTapTarget));
      // Colours and glass are the theme's own.
      expect(Theme.of(c).colorScheme, DsTheme.dark().colorScheme);
    });
  }

  for (final double width in <double>[640, 800, 1280]) {
    testWidgets('$width wide (tablet, desktop): nothing changes',
        (WidgetTester tester) async {
      final BuildContext c = await pump(tester, width);
      final TextTheme t = Theme.of(c).textTheme;
      expect(MediaQuery.textScalerOf(c).scale(10), 10);
      expect(t.bodyMedium!.fontSize, 13.5);
      expect(t.bodySmall!.fontSize, 12);
      expect(t.titleMedium!.fontSize, 15);
      expect(tester.getSize(find.byIcon(Icons.home)).width, 18);
    });
  }

  testWidgets("the phone's own font-size setting still applies on top",
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext inside;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          size: Size(360, 800), textScaler: TextScaler.linear(1.3)),
      child: MaterialApp(
        useInheritedMediaQuery: true,
        theme: DsTheme.dark(),
        builder: (BuildContext _, Widget? child) => DsReadable(child: child!),
        home: Builder(builder: (BuildContext context) {
          inside = context;
          return const SizedBox();
        }),
      ),
    ));
    expect(
        MediaQuery.textScalerOf(inside).scale(10),
        closeTo(10 * 1.3 * DsTypography.compactScale, 0.01));
  });
}
