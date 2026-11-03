/// Asking DGOTIX AI to write the commentary for a report.
///
/// One request per export, through the same gateway as everything else, so
/// the server's quota, daily limit and monthly cost ceiling apply unchanged —
/// there is no separate allowance to keep in step and no new way to spend
/// money. A report is a few hundred words in and out: on the cheapest model
/// in the registry that is a fraction of a cent.
///
/// Never throws. A refusal, an exhausted quota, no network — any of them
/// gives null, and the report is produced exactly as it is today, without
/// the commentary and without an error in the reader's face.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/ai/data/ai_gateway_service.dart';
import 'package:smartbudget/features/ai/domain/ai_registry.dart';
import 'package:smartbudget/features/reports/domain/report_insight.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// The language to write in, named in English for the model. Falls back to
/// English for a language not listed rather than guessing.
String languageNameOf(AppLang lang) =>
    const <AppLang, String>{
      AppLang.ar: 'Arabic',
      AppLang.en: 'English',
      AppLang.fr: 'French',
      AppLang.es: 'Spanish',
      AppLang.id: 'Indonesian',
      AppLang.tr: 'Turkish',
      AppLang.ms: 'Malay',
      AppLang.ur: 'Urdu',
      AppLang.de: 'German',
      AppLang.pt: 'Portuguese',
      AppLang.it: 'Italian',
      AppLang.nl: 'Dutch',
      AppLang.ru: 'Russian',
      AppLang.fa: 'Persian',
      AppLang.hi: 'Hindi',
      AppLang.zh: 'Chinese',
      AppLang.ja: 'Japanese',
      AppLang.ko: 'Korean',
      AppLang.sw: 'Swahili',
      AppLang.ha: 'Hausa',
      AppLang.af: 'Afrikaans',
      AppLang.bs: 'Bosnian',
      AppLang.sq: 'Albanian',
    }[lang] ??
    'English';

class ReportInsightService {
  const ReportInsightService(this._gateway);

  final AiGatewayService _gateway;

  /// The commentary for one report, or null when there is none to be had.
  ///
  /// Takes the computed totals, never the transactions: what is sent is the
  /// same handful of figures the report prints.
  Future<String?> write({
    required FinanceSummary summary,
    required List<CategoryTotal> income,
    required List<CategoryTotal> expenses,
    required String periodLabel,
    required AppLang language,
    required String Function(Money) money,
  }) async {
    try {
      final GatewayAnswer answer = await _gateway.ask(
        task: AiTaskType.report,
        prompt: ReportInsight.prompt(languageNameOf(language)),
        context: ReportInsight.brief(
          summary: summary,
          income: income,
          expenses: expenses,
          periodLabel: periodLabel,
          money: money,
        ),
      );
      return ReportInsight.clean(answer.text);
    } catch (_) {
      // Quota gone, offline, provider down: the report goes out without it.
      return null;
    }
  }
}

final reportInsightServiceProvider = Provider<ReportInsightService>(
    (Ref ref) => ReportInsightService(ref.watch(aiGatewayServiceProvider)));
