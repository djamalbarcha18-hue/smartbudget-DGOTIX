import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';

void main() {
  group('DsColors tokens', () {
    test('dark and light expose the DGOTIX brand blue', () {
      expect(DsColors.dark.brand, const Color(0xFF1680F7));
      expect(DsColors.light.brand, const Color(0xFF1680F7));
    });

    test('lerp between light and dark is stable at the endpoints', () {
      expect(DsColors.light.lerp(DsColors.dark, 0).brand, DsColors.light.brand);
      expect(DsColors.light.lerp(DsColors.dark, 1).bgPage, DsColors.dark.bgPage);
    });
  });

  group('AppConfig', () {
    test('support email is a single placeholder (to be replaced in one place)', () {
      expect(AppConfig.supportEmail, 'support@YOUR-DOMAIN.com');
    });

    test('parent brand leads the lockup', () {
      expect(AppConfig.parentBrand, 'DGOTIX');
      expect(AppConfig.parentBrandFirst, isTrue);
    });
  });
}
