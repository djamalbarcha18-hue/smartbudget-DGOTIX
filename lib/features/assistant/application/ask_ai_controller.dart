import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/assistant/data/ai_chat_service.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// The AI chat service (BYOK, direct-to-provider from the browser).
final aiChatServiceProvider =
    Provider<AiChatService>((ref) => const AiChatService());

/// A compact, REAL-DATA snapshot of the user's finances, handed to the model as
/// context so answers are personalized. Contains only figures the app already
/// computed — never fabricated. Kept short to stay cheap on the user's key.
final aiContextProvider = Provider<String>((ref) {
  final FinanceSummary sum = ref.watch(financeSummaryProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  final HealthReport report = ref.watch(healthReportProvider);

  final StringBuffer b = StringBuffer();
  b.writeln('Base currency: $currency.');
  if (sum.count > 0) {
    b.writeln('This year — income: ${MoneyFormatter.format(sum.income)}, '
        'expenses: ${MoneyFormatter.format(sum.expense)}, '
        'net: ${MoneyFormatter.format(sum.net)}, '
        'savings rate: ${MoneyFormatter.percent(sum.savingsRate)}.');
  } else {
    b.writeln('No transactions recorded yet.');
  }
  if (report.hasData) {
    b.writeln('Financial health score: ${report.score.round()}/100 '
        '(data confidence ${report.confidence.round()}%).');
  }
  return b.toString().trim();
});
