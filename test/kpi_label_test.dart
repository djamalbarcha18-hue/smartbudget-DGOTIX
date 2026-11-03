/// A KPI tile's title must be readable in full. On a narrow tile it used to
/// be cut to "إجمالي المصر…", which hides which card it is; it now shrinks
/// a little instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget tile(String label, double width) => MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: KpiCard(
                  label: label,
                  value: '62,900.00 DZD',
                  icon: Icons.north_east_outlined),
            ),
          ),
        ),
      );

  for (final String label in const <String>[
    'إجمالي المصروفات',
    'Total Expenses',
    'Gesamtausgaben',
  ]) {
    testWidgets('"$label" is never cut on a narrow tile',
        (WidgetTester t) async {
      await t.pumpWidget(tile(label, 150));
      final Text text = t.widget<Text>(find.text(label));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.softWrap, isFalse);
      // It sits inside a FittedBox that scales down rather than clipping.
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(FittedBox)),
        findsWidgets,
      );
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a roomy tile keeps the normal size', (WidgetTester t) async {
    await t.pumpWidget(tile('Total Expenses', 400));
    final RenderBox label = t.renderObject(find.text('Total Expenses'));
    final RenderBox box = t.renderObject(find.byType(KpiCard));
    expect(label.size.width, lessThan(box.size.width));
    expect(t.takeException(), isNull);
  });
}
