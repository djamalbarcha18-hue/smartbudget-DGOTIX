import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';

void main() {
  final DateTime now = DateTime(2026, 6, 15, 12);
  final DateTime today = DateTime(2026, 6, 15);

  Trip trip(
          {int days = 7,
          int? budget,
          TripLevel? level,
          Map<TripItem, int>? split}) =>
      Trip(
        id: 'a',
        name: 'Trip',
        destination: 'Istanbul',
        start: today.subtract(Duration(days: days + 2)),
        end: today.subtract(const Duration(days: 3)),
        plannedBudget: budget == null ? null : Money(budget * 100, 'USD'),
        createdAt: DateTime(2026),
        level: level,
        split: split,
      );

  Transaction spend(String id, int amount, String cat) => Transaction(
        id: id,
        date: today.subtract(const Duration(days: 4)),
        type: TransactionType.expense,
        category: cat,
        amount: Money(amount * 100, 'USD'),
        description: '',
        tripId: 'a',
        createdAt: DateTime(2026),
      );

  int sum(Map<TripItem, int> m) =>
      m.values.fold<int>(0, (int a, int v) => a + v);

  group('the suggested split', () {
    test('adds up to 100 for every level and length', () {
      for (final TripLevel? level in <TripLevel?>[null, ...TripLevel.values]) {
        for (final int days in <int>[1, 3, 4, 7, 9, 10, 30]) {
          final Map<TripItem, int> s = TripItems.suggested(level, days);
          expect(sum(s), 100, reason: '$level $days');
          expect(s.keys, TripItems.planned);
          expect(s.values.every((int v) => v > 0), isTrue);
        }
      }
    });

    test('by level: more for the hotel in luxury, more buffer in economy', () {
      final Map<TripItem, int> eco = TripItems.suggested(TripLevel.economy, 7);
      final Map<TripItem, int> std = TripItems.suggested(TripLevel.standard, 7);
      final Map<TripItem, int> lux = TripItems.suggested(TripLevel.luxury, 7);
      expect(std[TripItem.flights], 30);
      expect(std[TripItem.stay], 25);
      expect(lux[TripItem.stay]! > std[TripItem.stay]!, isTrue);
      expect(eco[TripItem.emergency]! > std[TripItem.emergency]!, isTrue);
    });

    test('by length: a long trip shifts from flights to stay and food', () {
      final Map<TripItem, int> week = TripItems.suggested(null, 7);
      final Map<TripItem, int> long = TripItems.suggested(null, 14);
      final Map<TripItem, int> short = TripItems.suggested(null, 2);
      expect(long[TripItem.flights]! < week[TripItem.flights]!, isTrue);
      expect(long[TripItem.stay]! > week[TripItem.stay]!, isTrue);
      expect(short[TripItem.flights]! > week[TripItem.flights]!, isTrue);
    });
  });

  group('changing one item', () {
    test('the rest share what is left, in proportion, total 100', () {
      final Map<TripItem, int> s = TripItems.suggested(null, 7);
      final Map<TripItem, int> out =
          TripItems.withShare(s, TripItem.flights, 0);
      expect(out[TripItem.flights], 0);
      expect(sum(out), 100);
      // Stay stays the largest, and the order of the others holds.
      expect(out[TripItem.stay]! > out[TripItem.food]!, isTrue);
      expect(out[TripItem.gifts], out[TripItem.emergency]);
    });

    test('all of it on one item, then back: evenly when others are zero', () {
      final Map<TripItem, int> all =
          TripItems.withShare(TripItems.suggested(null, 7), TripItem.stay, 100);
      expect(all[TripItem.stay], 100);
      expect(sum(all), 100);
      final Map<TripItem, int> back =
          TripItems.withShare(all, TripItem.stay, 40);
      expect(sum(back), 100);
      // The other seven share 60 evenly (8 or 9 each).
      final Iterable<int> rest = back.entries
          .where((MapEntry<TripItem, int> e) => e.key != TripItem.stay)
          .map((MapEntry<TripItem, int> e) => e.value);
      expect(rest.every((int v) => v == 8 || v == 9), isTrue);
    });

    test('saved and read back; a broken split is ignored', () {
      final Map<TripItem, int> s =
          TripItems.withShare(TripItems.suggested(null, 7), TripItem.food, 30);
      final Trip t = Trip.fromJson(trip(split: s).toJson());
      expect(t.split, s);
      expect(Trip.fromJson(trip().toJson()).split, isNull);
      expect(
          TripItems.parse(<String, Object>{
            for (final TripItem i in TripItems.planned) i.name: 10,
          }),
          isNull); // 70, not 100
    });
  });

  group('an organized trip', () {
    test('a package instead of flights and stay, and internet for all', () {
      final Map<TripItem, int> org =
          TripItems.suggested(TripLevel.standard, 7, TripKind.organized);
      expect(org.keys, TripItems.plannedOrganized);
      expect(sum(org), 100);
      expect(org[TripItem.package], 65);
      expect(org.containsKey(TripItem.flights), isFalse);
      for (final TripLevel? level in <TripLevel?>[null, ...TripLevel.values]) {
        for (final int days in <int>[2, 7, 14]) {
          expect(
              sum(TripItems.suggested(level, days, TripKind.organized)), 100);
        }
      }
      expect(TripItems.suggested(null, 7)[TripItem.connectivity], 3);
    });

    test('flights and stay count as its package; kind and who saved', () {
      expect(TripItems.of('السفر', TripKind.organized), TripItem.package);
      expect(TripItems.of('السكن', TripKind.organized), TripItem.package);
      expect(TripItems.of('الاتصالات والإنترنت'), TripItem.connectivity);
      final Trip t = Trip(
        id: 'a', // the expenses' trip
        name: 'Umrah',
        destination: 'Makkah',
        start: today,
        end: today.add(const Duration(days: 9)),
        createdAt: DateTime(2026),
        plannedBudget: const Money(300000, 'USD'),
        kind: TripKind.organized,
        agency: 'Al Noor Travel',
        hotel: 'Near the Haram',
      );
      final Trip back = Trip.fromJson(t.toJson());
      expect(back.kind, TripKind.organized);
      expect(back.agency, 'Al Noor Travel');
      expect(back.hotel, 'Near the Haram');
      expect(back.airline, isNull);
      expect(Trip.fromJson(trip().toJson()).kind, TripKind.independent);
      final TripReport r = TripReport.of(
          t,
          <Transaction>[spend('1', 1900, 'السفر'), spend('2', 40, 'السكن')],
          now,
          currency: 'USD');
      expect(r.plan.first.item, TripItem.package);
      expect(r.plan.first.spent, const Money(194000, 'USD'));
    });
  });

  group('items from categories', () {
    test('every expense category counts under one item', () {
      expect(TripItems.of('السفر'), TripItem.flights);
      expect(TripItems.of('السكن'), TripItem.stay);
      expect(TripItems.of('الطعام'), TripItem.food);
      expect(TripItems.of('الوقود'), TripItem.transport);
      expect(TripItems.of('الملابس'), TripItem.gifts);
      expect(TripItems.of('التأمين'), TripItem.emergency);
      expect(TripItems.of('الفواتير'), TripItem.other);
      for (final TripItem i in TripItem.values) {
        final String cat = TripItems.categoryOf(i);
        final TripKind kind =
            i == TripItem.package ? TripKind.organized : TripKind.independent;
        expect(Catalog.expenseCategories, contains(cat));
        // Picked as an item, read back as it.
        expect(TripItems.of(cat, kind), i);
      }
    });
  });

  group('the plan against what was spent', () {
    final List<Transaction> txns = <Transaction>[
      spend('1', 300, 'المطاعم'),
      spend('2', 500, 'السكن'),
      spend('3', 50, 'النقل'),
      spend('4', 400, 'التسوق'),
      spend('5', 70, 'الطعام'),
      spend('6', 20, 'الفواتير'),
    ];

    test('each item: its share of the budget and what it cost', () {
      final TripReport r =
          TripReport.of(trip(budget: 1500), txns, now, currency: 'USD');
      expect(r.plan.map((TripItemPlan p) => p.item),
          <TripItem>[...TripItems.planned, TripItem.other]);
      final int planned = r.plan
          .fold<int>(0, (int a, TripItemPlan p) => a + p.planned.minorUnits);
      expect(planned, r.budget!.minorUnits);
      final TripItemPlan stay =
          r.plan.firstWhere((TripItemPlan p) => p.item == TripItem.stay);
      expect(stay.planned, const Money(37500, 'USD')); // 25%
      expect(stay.spent, const Money(50000, 'USD'));
      expect(stay.over, isTrue);
      final TripItemPlan food =
          r.plan.firstWhere((TripItemPlan p) => p.item == TripItem.food);
      expect(food.spent, const Money(37000, 'USD')); // restaurants + food
    });

    test('the tip: the item furthest over, covered by the one with most left',
        () {
      final TripItemTip tip =
          TripReport.of(trip(budget: 1500), txns, now, currency: 'USD').tip!;
      expect(tip.over, TripItem.gifts); // 400 of 75
      expect(tip.overBy, const Money(32500, 'USD'));
      expect(tip.spare, TripItem.flights); // nothing spent of 450
      expect(tip.spareLeft, const Money(45000, 'USD'));
    });

    test('the user’s own split; no tip when all is within its share', () {
      final Map<TripItem, int> s = <TripItem, int>{
        TripItem.flights: 0,
        TripItem.stay: 40,
        TripItem.food: 30,
        TripItem.transport: 5,
        TripItem.activities: 0,
        TripItem.connectivity: 0,
        TripItem.gifts: 25,
        TripItem.emergency: 0,
      };
      final TripReport r = TripReport.of(
          trip(budget: 2000, split: s), txns.take(5).toList(), now,
          currency: 'USD');
      expect(r.tip, isNull);
      expect(r.plan.length, 8); // no "other" without spending on it
    });

    test('a little over (5% or less) is not flagged', () {
      // Standard week, 1,400: food gets 224 (16%); 230 is 6 over.
      final TripReport r = TripReport.of(
          trip(budget: 1400), <Transaction>[spend('1', 230, 'المطاعم')], now,
          currency: 'USD');
      final TripItemPlan food =
          r.plan.firstWhere((TripItemPlan p) => p.item == TripItem.food);
      expect(food.over, isTrue);
      expect(food.clearlyOver, isFalse);
      expect(r.tip, isNull);
      final TripReport more = TripReport.of(
          trip(budget: 1400), <Transaction>[spend('1', 260, 'المطاعم')], now,
          currency: 'USD');
      expect(more.tip!.over, TripItem.food);
    });

    test('no budget: no plan, no tip', () {
      final TripReport r = TripReport.of(trip(), txns, now, currency: 'USD');
      expect(r.plan, isEmpty);
      expect(r.tip, isNull);
    });
  });
}
