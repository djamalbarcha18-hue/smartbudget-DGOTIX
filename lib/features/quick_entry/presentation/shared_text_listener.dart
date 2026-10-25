import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/quick_entry/data/shared_text.dart';
import 'package:smartbudget/features/quick_entry/domain/bank_message.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Turns a bank message shared with the app into a transaction to check and
/// save. Sits in the app shell, so it waits for sign-in and the lock.
class SharedTextListener extends ConsumerStatefulWidget {
  const SharedTextListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SharedTextListener> createState() => _SharedTextListenerState();
}

class _SharedTextListenerState extends ConsumerState<SharedTextListener> {
  @override
  void initState() {
    super.initState();
    SharedText.arrived.addListener(_check);
    // Text that launched the app came before this was built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    SharedText.arrived.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final String? text = await SharedText.take();
    if (!mounted || text == null || text.trim().isEmpty) return;
    await openSharedMessage(context, ref, text);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The draft a bank message gives: its amount, day and merchant, the category
/// the merchant suggests, and the wallet holding its currency.
({TransactionType type, TransactionDraft draft, String? missingCurrency})
    draftFromMessage(
  BankMessage m, {
  required List<Wallet> wallets,
  required String baseCurrency,
  required DateTime today,
}) {
  final TransactionType type =
      m.income ? TransactionType.income : TransactionType.expense;
  String? category;
  if (m.merchant != null) {
    final QuickEntry? guess =
        QuickEntryParser.parse('${m.merchant} 1', today: today);
    if (guess != null && guess.recognized && guess.type == type) {
      category = guess.category;
    }
  }
  String? walletId;
  String? missing;
  final String? code = m.currency;
  if (code != null && code != baseCurrency) {
    final Wallet? holder = wallets
        .where((Wallet w) => !w.isGeneral && w.currency == code)
        .firstOrNull;
    walletId = holder?.id;
    if (holder == null) missing = code;
  }
  return (
    type: type,
    draft: TransactionDraft(
      amount: m.amount,
      category: category,
      date: m.date,
      description: m.merchant,
      walletId: walletId,
    ),
    missingCurrency: missing,
  );
}

/// Reads [text] and opens the filled-in editor, or says no amount was found.
Future<void> openSharedMessage(
    BuildContext context, WidgetRef ref, String text) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final DateTime today = AppClock.now();
  final BankMessage? m = BankMessageParser.parse(text, today: today);
  if (m == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.shareSmsNoAmount)));
    return;
  }
  final d = draftFromMessage(
    m,
    wallets: ref.read(walletsProvider),
    baseCurrency: ref.read(baseCurrencyProvider),
    today: today,
  );
  messenger.showSnackBar(SnackBar(
    content: Text(d.missingCurrency == null
        ? l.shareSmsFilled
        : '${l.shareSmsFilled} ${l.quickNoWalletFor(d.missingCurrency!)}'),
  ));
  await TransactionEditorSheet.show(context, type: d.type, prefill: d.draft);
}
