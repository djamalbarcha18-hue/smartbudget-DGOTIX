/// Asking DGOTIX AI to write the commentary for a report.
///
/// At most one request per export, through the same gateway as everything
/// else, so the server's quota, daily limit and monthly cost ceiling apply
/// unchanged — there is no separate allowance to keep in step and no new way
/// to spend money.
///
/// Often no request at all: an analysis of the same period, the same figures
/// and the same language is read back from the device (see
/// [ReportInsightCache]). Re-exporting a report costs nothing; only figures
/// that have actually moved are worth a new one.
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
import 'package:smartbudget/features/reports/data/report_insight_cache.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_insight.dart';

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
  const ReportInsightService(this._gateway, this._cache);

  final AiGatewayService _gateway;
  final ReportInsightCache _cache;

  /// The commentary for one report, or null when there is none to be had.
  ///
  /// Takes the computed figures, never the records behind them: what is sent
  /// is the same handful of numbers the report prints.
  ///
  /// [accountKey] separates one account's cache from another's on a shared
  /// device; it never leaves the device and is not sent with the request.
  Future<String?> write({
    required ReportFigures figures,
    required String periodLabel,
    required AppLang language,
    required String Function(Money) money,
    required String Function(String) label,
    String accountKey = '',
  }) async {
    final String brief = ReportInsight.brief(
      figures: figures,
      periodLabel: periodLabel,
      money: money,
      label: label,
    );
    final String key = ReportInsightCache.keyFor(
      accountKey: accountKey,
      language: language.code,
      periodLabel: periodLabel,
      brief: brief,
    );

    final String? remembered = await _cache.read(key);
    if (remembered != null) return remembered;

    try {
      final GatewayAnswer answer = await _gateway.ask(
        task: AiTaskType.report,
        prompt: ReportInsight.prompt(languageNameOf(language)),
        context: brief,
      );
      final String? text = ReportInsight.clean(answer.text);
      if (text != null) await _cache.write(key, text);
      return text;
    } catch (_) {
      // Quota gone, offline, provider down: the report goes out without it.
      return null;
    }
  }
}

final reportInsightServiceProvider =
    Provider<ReportInsightService>((Ref ref) => ReportInsightService(
          ref.watch(aiGatewayServiceProvider),
          ref.watch(reportInsightCacheProvider),
        ));
