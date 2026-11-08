import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/pro_highlights.dart';

void main() {
  test('the pop-up shows at most popupCount reasons, strongest first', () {
    final List<ProHighlight> shown = ProHighlights.forPopup();
    expect(shown.length, lessThanOrEqualTo(ProHighlights.popupCount));
    expect(shown.length, greaterThan(0));
    expect(shown.first, same(ProHighlights.all.first));
  });

  test('a highlight behind a flag is left out until the flag is on', () {
    final List<ProHighlight> hidden = ProHighlights.all
        .where((ProHighlight h) => h.visible != null && !h.visible!())
        .toList();
    for (final ProHighlight h in hidden) {
      expect(ProHighlights.forPopup(), isNot(contains(h)));
    }
  });
}
