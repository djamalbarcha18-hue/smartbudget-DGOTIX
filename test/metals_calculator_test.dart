import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/markets/data/gold_api_metals_repository.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/metals_calculator.dart';

void main() {
  group('MetalsCalculator', () {
    test('per gram / per kilogram from troy ounce', () {
      // 2488.278144 / 31.1034768 = 80.0 per gram
      expect(MetalsCalculator.perGram(2488.278144), closeTo(80.0, 1e-6));
      expect(MetalsCalculator.perKilogram(2488.278144), closeTo(80000.0, 1e-3));
    });

    test('karat price = 24K × karat / 24', () {
      expect(MetalsCalculator.karatPrice(80.0, 24), 80.0);
      expect(MetalsCalculator.karatPrice(80.0, 18), closeTo(60.0, 1e-9));
      expect(MetalsCalculator.karatPrice(80.0, 21), closeTo(70.0, 1e-9));
    });

    test('fineness price = fine × fineness / 1000', () {
      expect(MetalsCalculator.finenessPrice(1.0, 925), closeTo(0.925, 1e-9));
      expect(MetalsCalculator.finenessPrice(1.0, 999), closeTo(0.999, 1e-9));
    });

    test('karat list is descending and starts at 24', () {
      expect(MetalsCalculator.goldKarats.first, 24);
      expect(MetalsCalculator.goldKarats.last, 9);
    });
  });

  group('GoldApiMetalsRepository.parse', () {
    const CommoditySpec gold = CommoditySpec(
      code: 'XAU',
      nameEn: 'Gold',
      nameAr: 'الذهب',
      category: MarketCategory.preciousMetals,
      unitLabel: 'USD/oz',
      providerId: 'gold_api',
      apiSymbol: 'XAU',
    );

    test('parses a live price as a delayed quote', () {
      final CommodityQuote q = GoldApiMetalsRepository.parse(
        gold,
        <String, dynamic>{
          'name': 'Gold',
          'price': 2650.5,
          'symbol': 'XAU',
          'updatedAt': '2026-01-01T00:00:00Z',
        },
      );
      expect(q.priceUsd, 2650.5);
      expect(q.quality, PriceQuality.delayed);
      expect(q.source, 'gold-api.com');
    });

    test('missing/absent price -> unavailable (never fabricated)', () {
      final CommodityQuote q1 =
          GoldApiMetalsRepository.parse(gold, <String, dynamic>{});
      final CommodityQuote q2 = GoldApiMetalsRepository.parse(gold, null);
      expect(q1.priceUsd, isNull);
      expect(q1.quality, PriceQuality.unavailable);
      expect(q2.quality, PriceQuality.unavailable);
    });
  });
}
