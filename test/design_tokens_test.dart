import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';

void main() {
  group('DsColors tokens', () {
    double contrast(Color a, Color b) {
      final double la = a.computeLuminance();
      final double lb = b.computeLuminance();
      final double hi = la > lb ? la : lb;
      final double lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('dark and light expose the DGOTIX brand blue (the logo color)', () {
      expect(DsColors.dark.brand, const Color(0xFF1680F7));
      expect(DsColors.light.brand, const Color(0xFF1680F7));
    });

    test('financial semantics stay distinct: gains green, losses red', () {
      for (final DsColors c in <DsColors>[DsColors.dark, DsColors.light]) {
        expect(HSVColor.fromColor(c.income).hue, inInclusiveRange(140, 170));
        final double loss = HSVColor.fromColor(c.expense).hue;
        expect(loss > 330 || loss < 10, isTrue, reason: 'red hue');
      }
    });

    test('text stays readable (WCAG AA) in both themes', () {
      for (final DsColors c in <DsColors>[DsColors.dark, DsColors.light]) {
        expect(contrast(c.textPrimary, c.bgElevated), greaterThanOrEqualTo(7));
        expect(contrast(c.textMuted, c.bgElevated), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onBrand, c.brand), greaterThanOrEqualTo(3));
      }
    });

    test('lerp between light and dark is stable at the endpoints', () {
      expect(DsColors.light.lerp(DsColors.dark, 0).brand, DsColors.light.brand);
      expect(DsColors.light.lerp(DsColors.dark, 1).bgPage, DsColors.dark.bgPage);
    });
  });

  group('AppConfig', () {
    test('support email is never a placeholder; empty means not set up yet',
        () {
      expect(AppConfig.supportEmail.toUpperCase(),
          isNot(contains('YOUR-DOMAIN')));
      expect(AppConfig.hasSupportEmail,
          AppConfig.supportEmail.trim().isNotEmpty);
      if (AppConfig.hasSupportEmail) {
        expect(
            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                .hasMatch(AppConfig.supportEmail),
            isTrue,
            reason: 'configured support email must be a real address');
      }
    });

    test('legal pages never show a placeholder contact', () {
      for (final LegalDoc doc in LegalDoc.values) {
        for (final bool ar in <bool>[false, true]) {
          for (final LegalSection s in LegalContent.sections(doc, ar: ar)) {
            expect(s.body.toUpperCase(), isNot(contains('YOUR-DOMAIN')));
          }
        }
      }
    });

    test('parent brand leads the lockup', () {
      expect(AppConfig.parentBrand, 'DGOTIX');
      expect(AppConfig.parentBrandFirst, isTrue);
    });
  });
}
