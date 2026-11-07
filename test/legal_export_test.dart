import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';

/// tool/export_legal.dart builds the website's refund page from three terms
/// sections, found by their English headings and taken from the same position
/// in every language. These checks keep that safe when the texts change.
void main() {
  const List<String> headings = <String>[
    'Subscriptions, billing and renewals',
    'Our payment provider: Whop',
    'Refund policy',
  ];
  final List<AppLang> offered =
      AppLang.values.where((AppLang l) => !l.hidden).toList();

  test('the refund page sections exist in English', () {
    final List<String> en =
        LegalContent.sections(LegalDoc.terms, lang: AppLang.en)
            .map((LegalSection s) => s.heading)
            .toList();
    for (final String h in headings) {
      expect(en, contains(h));
    }
  });

  test('every offered language has the same sections in the same order', () {
    final int n =
        LegalContent.sections(LegalDoc.terms, lang: AppLang.en).length;
    for (final AppLang l in offered) {
      expect(LegalContent.sections(LegalDoc.terms, lang: l).length, n,
          reason: l.code);
    }
  });

  test('the refund rule is the 7-day one, in every offered language', () {
    final int i = LegalContent.sections(LegalDoc.terms, lang: AppLang.en)
        .indexWhere((LegalSection s) => s.heading == 'Refund policy');
    for (final AppLang l in offered) {
      final String body =
          LegalContent.sections(LegalDoc.terms, lang: l)[i].body;
      expect(body.contains('7'), isTrue, reason: l.code);
    }
  });
}
