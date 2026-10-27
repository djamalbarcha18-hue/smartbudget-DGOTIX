import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metal_sale.dart';
import 'package:smartbudget/features/metals/presentation/metal_sale_sheet.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

const Map<String, double> _rates = <String, double>{'USD': 1, 'DZD': 135};

class _FixedRates extends RatesController {
  @override
  Map<String, double> build() => _rates;
}

/// 10 g of 21 karat for 2,000 (of which 300 workmanship).
final MetalHolding _bracelet = MetalHolding(
  id: 'b',
  metal: Metal.gold,
  grams: 10,
  purity: 21,
  name: 'Bracelet',
  paid: const Money(200000, 'DZD'),
  making: const Money(30000, 'DZD'),
  boughtOn: DateTime(2023, 3, 10),
  createdAt: DateTime(2023, 3, 10),
);

MetalSale _sale(MetalHolding sold, int received) => MetalSale(
      id: 's',
      sold: sold,
      received: Money(received * 100, 'DZD'),
      soldOn: DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  group('selling part of a piece', () {
    test('each part takes its share of the cost; they add up', () {
      final ({MetalHolding sold, MetalHolding? rest}) p =
          MetalSales.split(_bracelet, 4);
      expect(p.sold.grams, 4);
      expect(p.sold.paid, const Money(80000, 'DZD'));
      expect(p.sold.making, const Money(12000, 'DZD'));
      expect(p.rest!.grams, 6);
      expect(p.rest!.paid!.minorUnits + p.sold.paid!.minorUnits, 200000);
      expect(p.rest!.making!.minorUnits + p.sold.making!.minorUnits, 30000);
      // The rest is still the same piece, bought the same day.
      expect(p.rest!.id, 'b');
      expect(p.rest!.boughtOn, DateTime(2023, 3, 10));
    });

    test('all of it: nothing left', () {
      expect(MetalSales.split(_bracelet, 10).rest, isNull);
    });

    test('what a sale earned: received against its share of the cost', () {
      final Gain g = MetalSales.gain(
          _sale(MetalSales.split(_bracelet, 4).sold, 1100), 'DZD', _rates)!;
      expect(g.amount, const Money(30000, 'DZD'));
    });

    test('sales add up; one with no cost is left out', () {
      final MetalSale a = _sale(MetalSales.split(_bracelet, 4).sold, 1100);
      final MetalSale b = _sale(MetalSales.split(_bracelet, 6).sold, 1000);
      final MetalSale noCost = _sale(
          MetalHolding(
              id: 'x',
              metal: Metal.silver,
              grams: 100,
              purity: 925,
              createdAt: DateTime(2026)),
          500);
      final Gain t =
          MetalSales.total(<MetalSale>[a, b, noCost], 'DZD', _rates)!;
      expect(t.paid, const Money(200000, 'DZD'));
      expect(t.value, const Money(210000, 'DZD'));
      expect(MetalSales.total(<MetalSale>[noCost], 'DZD', _rates), isNull);
    });

    test('undone: the piece is whole again', () {
      final ({MetalHolding sold, MetalHolding? rest}) p =
          MetalSales.split(_bracelet, 4);
      final MetalHolding back = MetalSales.rejoin(_sale(p.sold, 1100), p.rest);
      expect(back.toJson(), _bracelet.toJson());
      // Sold whole: it comes back as it was.
      expect(MetalSales.rejoin(_sale(_bracelet, 2500), null).toJson(),
          _bracelet.toJson());
    });

    test('kept as it was, in backups and sync too', () {
      final MetalSale s = _sale(MetalSales.split(_bracelet, 4).sold, 1100);
      expect(MetalSale.fromJson(s.toJson()).toJson(), s.toJson());
      final BackupData d = BackupData.fromJson(
          BackupData(
            exportedAt: DateTime(2026),
            baseCurrency: 'DZD',
            transactions: const <Transaction>[],
            budgets: const [],
            customIncome: const <String>[],
            customExpense: const <String>[],
            metalSales: <MetalSale>[s],
          ).toJson());
      expect(d.metalSales.single.received, const Money(110000, 'DZD'));
      expect(SyncMerge.listCollections, contains('metalSales'));
    });
  });

  group('recording a sale', () {
    late ProviderContainer c;
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      c = ProviderContainer(overrides: <Override>[
        ratesProvider.overrideWith(_FixedRates.new),
      ]);
      addTearDown(c.dispose);
    });

    Future<List<MetalHolding>> held() => c.read(metalStoreProvider).all();
    Future<List<MetalSale>> sold() => c.read(metalSaleStoreProvider).all();
    Future<List<Transaction>> txns() async {
      final List<Transaction> out =
          await c.read(financeRepositoryProvider).watchAll().first;
      return out;
    }

    test('part sold, with the money as income; undone, all as before',
        () async {
      await c.read(metalActionsProvider).save(_bracelet);
      final MetalSale s = await c.read(metalActionsProvider).sell(
            _bracelet,
            grams: 4,
            received: const Money(110000, 'DZD'),
            soldOn: DateTime(2026, 10, 1),
            incomeLabel: 'Sold Bracelet',
          );
      expect((await held()).single.grams, 6);
      expect((await sold()).single.id, s.id);
      final Transaction t = (await txns()).single;
      expect(t.type, TransactionType.income);
      expect(t.amount, const Money(110000, 'DZD'));
      expect(t.category, MetalActions.saleIncomeCategory);

      await c.read(metalActionsProvider).undoSale(s);
      expect((await held()).single.toJson(), _bracelet.toJson());
      expect(await sold(), isEmpty);
      expect(await txns(), isEmpty);
    });

    test('all of it: the piece goes, and comes back on undo', () async {
      await c.read(metalActionsProvider).save(_bracelet);
      final MetalSale s = await c.read(metalActionsProvider).sell(_bracelet,
          grams: 10,
          received: const Money(250000, 'DZD'),
          soldOn: DateTime(2026, 10, 1));
      expect(await held(), isEmpty);
      expect(await txns(), isEmpty); // no income unless asked
      await c.read(metalActionsProvider).undoSale(s);
      expect((await held()).single.toJson(), _bracelet.toJson());
    });
  });

  testWidgets('the sale window: what it earns as it is typed',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      ratesProvider.overrideWith(_FixedRates.new),
      baseCurrencyProvider.overrideWith(_Dzd.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: Scaffold(body: MetalSaleSheet(holding: _bracelet)),
      ),
    ));
    await tester.pumpAndSettle();
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    // All of it by default; nothing to show until an amount is typed.
    expect(find.text('10'), findsOneWidget);
    expect(find.textContaining(l.metalsSellPreview('')), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '4');
    await tester.enterText(find.byType(TextFormField).at(1), '1100');
    await tester.pump();
    expect(find.textContaining('+'), findsWidgets);
    expect(find.textContaining('300'), findsOneWidget);

    // More than the piece holds is refused.
    await tester.enterText(find.byType(TextFormField).first, '12');
    await tester.tap(find.text(l.metalsSell));
    await tester.pumpAndSettle();
    expect(find.text(l.metalsSellTooMany), findsOneWidget);
  });
}

class _Dzd extends BaseCurrencyController {
  @override
  String build() => 'DZD';
}
