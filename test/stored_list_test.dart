import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/storage/stored_list.dart';
import 'package:smartbudget/features/transactions/data/fake_transaction_repository.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// One unreadable record must never cost the user the rest of their data.
void main() {
  Map<String, dynamic> good(String id) => Transaction(
        id: id,
        date: DateTime(2026, 10, 1),
        type: TransactionType.expense,
        category: 'الطعام',
        amount: const Money(1250, 'SAR'),
        createdAt: DateTime(2026, 10, 1),
      ).toJson();

  test('an unreadable record is skipped, the others are kept', () async {
    final String raw = jsonEncode(<Object?>[
      good('a'),
      <String, dynamic>{'date': 'not a date'}, // no id, bad date
      42,
      good('b'),
    ]);
    SharedPreferences.setMockInitialValues(<String, Object>{'k': raw});
    final SharedPreferences p = await SharedPreferences.getInstance();
    final List<Transaction> list =
        StoredList.read(p, 'k', raw, Transaction.fromJson);
    expect(list.map((Transaction t) => t.id), <String>['a', 'b']);
    // The full text is kept aside before anything can overwrite it.
    expect(p.getString(StoredList.asideKey('k')), raw);
  });

  test('text that is not JSON at all is kept aside, not lost', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(StoredList.read(p, 'k', '[{"id":"a",', Transaction.fromJson),
        isEmpty);
    expect(p.getString(StoredList.asideKey('k')), '[{"id":"a",');
  });

  test('a readable list sets nothing aside', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String raw = jsonEncode(<Object>[good('a')]);
    expect(StoredList.read(p, 'k', raw, Transaction.fromJson), hasLength(1));
    expect(p.getString(StoredList.asideKey('k')), isNull);
  });

  test('saving after a bad record keeps every readable transaction',
      () async {
    final String raw = jsonEncode(<Object?>[
      good('a'),
      <String, dynamic>{'oops': true},
      good('b'),
    ]);
    SharedPreferences.setMockInitialValues(
        <String, Object>{'sb_txns_u1': raw});
    final FakeTransactionRepository repo =
        FakeTransactionRepository(userId: 'u1');
    await repo.add(Transaction.fromJson(good('c')));
    final SharedPreferences p = await SharedPreferences.getInstance();
    final List<dynamic> stored =
        jsonDecode(p.getString('sb_txns_u1')!) as List<dynamic>;
    expect(stored.map((dynamic e) => (e as Map)['id']).toSet(),
        <String>{'a', 'b', 'c'});
    expect(p.getString(StoredList.asideKey('sb_txns_u1')), raw);
    repo.dispose();
  });
}
