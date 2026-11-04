import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';

/// The refund window (7 days) is a promise to customers: it must be stated in
/// every language of the terms, and the old "non-refundable" wording must not
/// survive anywhere.
void main() {
  // The refund section is the one that mentions both Whop and PayPal by name
  // and the contact address; its number is written in Latin digits, or in
  // Persian/Arabic-Indic digits for those languages.
  final RegExp seven = RegExp('(?<![0-9])7(?![0-9])|۷|٧|七');

  for (final AppLang lang in AppLang.values) {
    test('terms in ${lang.code} state the 7-day refund window', () {
      final List<LegalSection> sections =
          LegalContent.sections(LegalDoc.terms, lang: lang);
      final Iterable<LegalSection> refund = sections.where((LegalSection s) =>
          s.body.contains('Whop') &&
          s.body.contains('PayPal') &&
          seven.hasMatch(s.body));
      expect(refund, isNotEmpty,
          reason: 'no refund section with the 7-day window in ${lang.code}');
      for (final LegalSection s in sections) {
        expect(s.body.toLowerCase(),
            isNot(contains('non-refundable once a billing')));
      }
    });
  }
}
