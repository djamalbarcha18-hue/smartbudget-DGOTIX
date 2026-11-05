/// A debt can be in a currency other than the base one (a friend who borrowed
/// euros while the app is in dinars): the editor offers the choice, saves the
/// debt in it, and keeps an existing debt's currency fixed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_repository.dart';
import 'package:smartbudget/features/debts/presentation/debt_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Keeps what the editor saves, in memory.
class _Repo implements DebtRepository {
  final List<Debt> added = <Debt>[];
  final List<Debt> updated = <Debt>[];

  @override
  Stream<List<Debt>> watchAll() => const Stream<List<Debt>>.empty();
  @override
  List<Debt> get current => const <Debt>[];
  @override
  Future<void> add(Debt debt) async => added.add(debt);
  @override
  Future<void> update(Debt debt) async => updated.add(debt);
  @override
  Future<void> delete(String id) async {}
  @override
  Future<int> importMany(List<Debt> debts) async => 0;
  @override
  Future<void> replaceAll(List<Debt> items) async {}
  @override
  void dispose() {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final Currency eur = Currencies.byCode('EUR');

  Future<_Repo> open(WidgetTester tester, {Debt? existing}) async {
    SharedPreferences.setMockInitialValues(
        <String, Object>{'sb_base_currency': 'DZD'});
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _Repo repo = _Repo();
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[debtRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: Scaffold(body: DebtEditorSheet(existing: existing)),
      ),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  Finder field(int i) => find.byType(TextFormField).at(i);

  testWidgets('a new debt is in the base currency unless another is chosen',
      (WidgetTester tester) async {
    final _Repo repo = await open(tester);
    expect(find.textContaining('DZD'), findsWidgets);

    await tester.enterText(field(0), 'Hamid');
    await tester.enterText(field(1), '500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.added.single.original, Money.fromDouble(500, 'DZD'));
    expect(repo.added.single.paid.currencyCode, 'DZD');
  });

  testWidgets('choosing euros saves the debt, and its paid amount, in euros',
      (WidgetTester tester) async {
    final _Repo repo = await open(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${eur.code} · ${eur.symbol}').last);
    await tester.pumpAndSettle();

    // The amount fields now say EUR, not the base currency.
    expect(find.text('EUR'), findsWidgets);

    await tester.enterText(field(0), 'Hamid');
    await tester.enterText(field(1), '50000');
    await tester.enterText(field(2), '12000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Debt saved = repo.added.single;
    expect(saved.original, Money.fromDouble(50000, 'EUR'));
    expect(saved.paid, Money.fromDouble(12000, 'EUR'));
  });

  testWidgets('an existing debt keeps its currency: the choice is locked',
      (WidgetTester tester) async {
    final Debt existing = Debt(
      id: 'd1',
      party: 'Hamid',
      type: DebtType.lent,
      original: Money.fromDouble(50000, 'EUR'),
      paid: Money.fromDouble(12000, 'EUR'),
      createdAt: DateTime(2026, 1, 1),
    );
    final _Repo repo = await open(tester, existing: existing);

    final DropdownButtonFormField<String> dropdown =
        tester.widget(find.byType(DropdownButtonFormField<String>));
    expect(dropdown.onChanged, isNull, reason: 'cannot be changed');
    expect(
        find.text("The currency can't change after creation."), findsOneWidget);

    // Saving an edit leaves it in euros even though the base is dinars.
    await tester.enterText(field(2), '20000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.updated.single.original.currencyCode, 'EUR');
    expect(repo.updated.single.paid, Money.fromDouble(20000, 'EUR'));
  });
}
