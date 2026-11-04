import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/reports/application/reports_controller.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/data/report_document.dart';
import 'package:smartbudget/features/reports/data/report_fonts.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/data/report_insight_service.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';

/// Exports the current report as a branded DGOTIX PDF (print / save-as-PDF).
class ExportPdfButton extends ConsumerStatefulWidget {
  const ExportPdfButton({super.key});

  @override
  ConsumerState<ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends ConsumerState<ExportPdfButton> {
  bool _busy = false;

  /// Whether to ask the assistant to write the commentary. Off by default:
  /// it spends one of the account's AI requests, so it is the reader's
  /// choice, made before the export, not a surprise after it.
  bool _withInsight = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool full = ref.watch(featureGateProvider(Feature.reportPdf)).allowed;
    // The written analysis is the PRO half of this feature: the document
    // itself is everyone's. Both gates are checked — the plan, and an
    // assistant request left to spend on it.
    final bool canWrite = full &&
        ref.watch(featureGateProvider(Feature.advancedReports)).allowed &&
        ref.watch(featureGateProvider(Feature.dgotixAi)).allowed;

    final Widget button = TextButton.icon(
      onPressed: _busy
          ? null
          : full
              ? _export
              : () => PlanLimits.allow(context, Feature.reportPdf),
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              full ? Icons.picture_as_pdf_outlined : Icons.lock_outline_rounded,
              size: 16),
      label: Text(l.reportExportPdf),
    );

    if (!canWrite) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SwitchListTile.adaptive(
          value: _withInsight,
          onChanged:
              _busy ? null : (bool v) => setState(() => _withInsight = v),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l.reportWithInsight,
              style: Theme.of(context).textTheme.bodySmall),
          subtitle: Text(l.reportInsightHint,
              style: Theme.of(context).textTheme.labelSmall),
        ),
        button,
      ],
    );
  }

  Future<void> _export() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = AppLocalizations.of(context).reportPdfFailed;
    final String noInsight = AppLocalizations.of(context).reportInsightFailed;
    final AppLang ui = appLangOf(context);
    // Some scripts can't be set in the PDF (AppLang.pdfInEnglish): those
    // reports, and only they, are written in English.
    final AppLang lang = ui.pdfInEnglish ? AppLang.en : ui;
    final AppLocalizations l = lang == ui
        ? AppLocalizations.of(context)
        : lookupAppLocalizations(const Locale('en'));

    setState(() => _busy = true);
    try {
      final ReportFigures f = ref.read(reportFiguresProvider);
      final int year = f.range.year;
      final FinanceSummary s = f.summary;
      final String periodText = ReportDocument.periodText(f, l, lang);

      // Asked for before the document is laid out; a null answer (quota
      // gone, offline, refused) simply leaves the commentary out. An answer
      // already written for these same figures comes back from the device
      // without a request being made at all.
      String? insight;
      if (_withInsight) {
        insight = await ref.read(reportInsightServiceProvider).write(
              figures: f,
              periodLabel: periodText,
              language: lang,
              money: MoneyFormatter.format,
              label: (String c) => Catalog.label(c, lang: lang),
              accountKey: ref.read(currentAccountIdProvider) ?? '',
            );
        // Asked for but not written (quota used, offline, assistant busy): the
        // report still goes out, and the reader is told why it has no
        // commentary instead of wondering whether the feature broke.
        if (insight == null) {
          messenger.showSnackBar(SnackBar(content: Text(noInsight)));
        }
      }

      final ReportPdfData data = ReportDocument.build(
        figures: f,
        l: l,
        lang: lang,
        now: AppClock.now(),
        logoSvg: await ReportDocument.logo(),
        insight: insight,
      );

      // Which faces this language and currency need (ReportFonts), loaded
      // from the bundle so an export works with no network.
      final ReportFontSet faces = ReportFonts.forLanguage(lang,
          currencySymbol: s.income.currency.symbol);
      Future<pw.Font> face(String path) async =>
          pw.Font.ttf(await rootBundle.load(path));
      final pw.Font base = await face(faces.base);
      final pw.Font bold = await face(faces.bold);
      final List<pw.Font> fallback = <pw.Font>[
        for (final String path in faces.fallback) await face(path),
      ];
      final Uint8List bytes = await ReportPdfBuilder.build(data,
          base: base, bold: bold, fallback: fallback);
      await Printing.layoutPdf(
        name: 'DGOTIX-Analytics-$year.pdf',
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
