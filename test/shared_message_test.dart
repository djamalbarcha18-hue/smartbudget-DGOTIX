import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/quick_entry/domain/bank_message.dart';
import 'package:smartbudget/features/quick_entry/presentation/shared_text_listener.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final DateTime today = DateTime(2026, 10, 25);

  group('the draft a message gives', () {
    final List<Wallet> wallets = <Wallet>[
      Wallet.general('SAR'),
      Wallet(
          id: 'w-usd',
          name: 'USD',
          type: WalletType.bank,
          opening: const Money(0, 'USD'),
          createdAt: DateTime(2026)),
    ];

    test('amount, day, merchant and the category it suggests', () {
      final d = draftFromMessage(
        const BankMessage(
            amount: 120.5,
            income: false,
            currency: 'SAR',
            merchant: 'CARREFOUR'),
        wallets: wallets,
        baseCurrency: 'SAR',
        today: today,
      );
      expect(d.type, TransactionType.expense);
      expect(d.draft.amount, 120.5);
      expect(d.draft.description, 'CARREFOUR');
      expect(d.draft.category, 'الطعام');
      expect(d.draft.walletId, isNull); // the default wallet
      expect(d.missingCurrency, isNull);
    });

    test('another currency goes to the wallet that holds it', () {
      final d = draftFromMessage(
        const BankMessage(amount: 12, income: false, currency: 'USD'),
        wallets: wallets,
        baseCurrency: 'SAR',
        today: today,
      );
      expect(d.draft.walletId, 'w-usd');
      final e = draftFromMessage(
        const BankMessage(amount: 12, income: false, currency: 'EUR'),
        wallets: wallets,
        baseCurrency: 'SAR',
        today: today,
      );
      expect(e.draft.walletId, isNull);
      expect(e.missingCurrency, 'EUR');
    });

    test('money in is income', () {
      final d = draftFromMessage(
        const BankMessage(amount: 5000, income: true),
        wallets: wallets,
        baseCurrency: 'SAR',
        today: today,
      );
      expect(d.type, TransactionType.income);
    });
  });

  group('sharing a message with the app', () {
    const MethodChannel channel = MethodChannel('smartbudget/shared_text');
    String? pending;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method != 'take') return null;
        final String? text = pending;
        pending = null;
        return text;
      });
    });

    tearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    Future<ProviderContainer> pump(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = ProviderContainer();
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
          home: const SharedTextListener(child: Scaffold(body: SizedBox())),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('opens the filled-in expense; saving records it',
        (WidgetTester tester) async {
      pending = 'Purchase of USD 120.50 at CARREFOUR on 01/03/2024. '
          'Available balance: USD 3,450.00';
      final ProviderContainer c = await pump(tester);
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.shareSmsFilled), findsOneWidget);
      expect(find.text('CARREFOUR'), findsOneWidget);
      await tester.ensureVisible(find.text(l.save));
      await tester.tap(find.text(l.save));
      await tester.pumpAndSettle();
      final Transaction t =
          (await c.read(financeRepositoryProvider).watchAll().first).single;
      expect(t.amount.asDouble, 120.5);
      expect(t.type, TransactionType.expense);
      expect(t.description, 'CARREFOUR');
      expect(t.category, 'الطعام');
      expect(<int>[t.date.year, t.date.month, t.date.day], <int>[2024, 3, 1]);
    });

    testWidgets('a message without an amount only says so',
        (WidgetTester tester) async {
      pending = 'Your OTP is 482913';
      final ProviderContainer c = await pump(tester);
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.shareSmsNoAmount), findsOneWidget);
      expect(await c.read(financeRepositoryProvider).watchAll().first, isEmpty);
    });

    testWidgets('nothing shared: nothing happens', (WidgetTester tester) async {
      pending = null;
      await pump(tester);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
