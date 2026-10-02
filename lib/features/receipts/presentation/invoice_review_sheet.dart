import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What the invoice reader found, checked: header, items and totals, with
/// "Verified" or "Needs review". Only the useful fields are shown, never the
/// raw text. Lines that don't add up are highlighted and can be corrected.
class InvoiceReviewSheet extends StatefulWidget {
  const InvoiceReviewSheet({
    super.key,
    required this.reading,
    required this.timings,
    this.duplicate = false,
    this.walletCurrency,
  });

  final InvoiceReading reading;
  final ScanTimings timings;
  final bool duplicate;

  /// The currency new expenses go to, to warn when the invoice differs.
  final String? walletCurrency;

  /// The reading, corrected by the user, when they choose to add it as an
  /// expense; null when they close the sheet.
  static Future<InvoiceReading?> show(
    BuildContext context, {
    required InvoiceReading reading,
    required ScanTimings timings,
    bool duplicate = false,
    String? walletCurrency,
  }) {
    return showModalBottomSheet<InvoiceReading>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => InvoiceReviewSheet(
        reading: reading,
        timings: timings,
        duplicate: duplicate,
        walletCurrency: walletCurrency,
      ),
    );
  }

  @override
  State<InvoiceReviewSheet> createState() => _InvoiceReviewSheetState();
}

class _InvoiceReviewSheetState extends State<InvoiceReviewSheet> {
  late InvoiceReading _r = widget.reading;
  bool _showTimings = false;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final ReviewLevel level = _r.level();
    final bool verified = level == ReviewLevel.verified;
    final Color tone = switch (level) {
      ReviewLevel.verified => c.income,
      ReviewLevel.warning => c.warning,
      ReviewLevel.review => c.expense,
    };
    final List<String> issues = _issueMessages(l);
    final String? foreign = _r.currency != null &&
            widget.walletCurrency != null &&
            _r.currency != widget.walletCurrency
        ? _r.currency
        : null;

    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DsSpacing.xl, DsSpacing.lg, DsSpacing.sm, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(l.invoiceReady, style: t.titleLarge)),
                    _StatusChip(
                      label: verified ? l.invoiceVerified : l.invoiceNeedsReview,
                      icon: verified
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: tone,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      DsSpacing.xl, DsSpacing.sm, DsSpacing.xl, DsSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _timingLine(c, l, t),
                      if (widget.duplicate)
                        _Notice(
                            text: l.invoiceDuplicate,
                            icon: Icons.content_copy_rounded,
                            color: c.warning),
                      for (final String m in issues)
                        _Notice(
                            text: m,
                            icon: Icons.info_outline_rounded,
                            color: level == ReviewLevel.review
                                ? c.expense
                                : c.warning),
                      if (foreign != null)
                        _Notice(
                            text: l.invoiceForeignCurrency(foreign),
                            icon: Icons.currency_exchange_rounded,
                            color: c.brand),
                      const SizedBox(height: DsSpacing.sm),
                      _header(c, l, t),
                      const SizedBox(height: DsSpacing.lg),
                      Text(l.invoiceItemsTitle(_r.items.length),
                          style: t.titleSmall),
                      const SizedBox(height: DsSpacing.xs),
                      if (_r.items.isEmpty)
                        Text(l.invoiceNoItems,
                            style: t.bodySmall?.copyWith(color: c.textMuted))
                      else
                        for (int i = 0; i < _r.items.length; i++)
                          _itemRow(i, c, t),
                      const SizedBox(height: DsSpacing.md),
                      _summary(c, l, t),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DsSpacing.xl, 0, DsSpacing.xl, DsSpacing.lg),
                child: DsButton(
                  label: l.invoiceAddExpense,
                  icon: Icons.north_east_rounded,
                  onPressed: () => Navigator.of(context).pop(_r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- parts ----

  Widget _timingLine(DsColors c, AppLocalizations l, TextTheme t) {
    final ScanTimings tm = widget.timings;
    final String main = tm.fromCache
        ? l.invoiceFromMemory
        : l.invoiceReadIn((tm.total / 1000).toStringAsFixed(1));
    return InkWell(
      borderRadius: DsRadius.brSm,
      onTap: () => setState(() => _showTimings = !_showTimings),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
        child: Text(
          _showTimings
              ? '$main\n${l.invoiceTimings(tm.prepare, tm.reading, tm.model, tm.checks)}'
              : main,
          style: t.labelSmall?.copyWith(color: c.textFaint),
        ),
      ),
    );
  }

  Widget _header(DsColors c, AppLocalizations l, TextTheme t) {
    final List<(String, String)> rows = <(String, String)>[
      if (_r.invoiceNumber != null) (l.invoiceNumberLabel, _r.invoiceNumber!),
      (l.invoiceDateLabel, _r.date == null ? '—' : _ymd(_r.date!)),
      if (_r.supplier != null) (l.invoiceSupplierLabel, _r.supplier!),
      (l.invoiceCurrencyLabel, _r.currency ?? '—'),
    ];
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
      ),
      child: Column(
        children: <Widget>[
          for (final (String, String) r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Text(r.$1, style: t.bodySmall?.copyWith(color: c.textMuted)),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(int index, DsColors c, TextTheme t) {
    final InvoiceItem item = _r.items[index];
    final bool flagged = item.mismatch ||
        item.confidence < ReviewPolicy.standard.warn;
    final String? detail = item.quantity != null && item.unitPrice != null
        ? '${_qty(item.quantity!)} × ${_money(item.unitPrice!)}'
        : (item.quantity != null ? '× ${_qty(item.quantity!)}' : null);
    return InkWell(
      borderRadius: DsRadius.brSm,
      onTap: () => _editLine(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm, vertical: DsSpacing.sm),
        decoration: BoxDecoration(
          color: flagged ? c.expense.withValues(alpha: 0.08) : null,
          borderRadius: DsRadius.brSm,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: <Widget>[
            if (flagged) ...<Widget>[
              Icon(Icons.warning_amber_rounded, size: 16, color: c.expense),
              const SizedBox(width: DsSpacing.xs),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.name.isEmpty ? '—' : item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium),
                  if (detail != null)
                    Text(detail,
                        textDirection: TextDirection.ltr,
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Text(
              item.lineTotal == null ? '—' : _money(item.lineTotal!),
              textDirection: TextDirection.ltr,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(DsColors c, AppLocalizations l, TextTheme t) {
    Widget row(String label, double? v,
        {bool strong = false, String? note, bool minus = false}) {
      if (v == null) return const SizedBox.shrink();
      final TextStyle? s = strong
          ? t.titleMedium?.copyWith(fontWeight: FontWeight.w700)
          : t.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                note == null ? label : '$label ($note)',
                overflow: TextOverflow.ellipsis,
                style: strong ? s : s?.copyWith(color: c.textMuted),
              ),
            ),
            const SizedBox(width: DsSpacing.md),
            Text(
              '${minus ? '−' : ''}${_money(v)}',
              textDirection: TextDirection.ltr,
              style: s,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
      ),
      child: Column(
        children: <Widget>[
          row(l.invoiceSubtotal, _r.subtotal),
          row(l.invoiceDiscount, _r.discount, minus: true),
          row(l.invoiceTax, _r.tax),
          if (_r.subtotal != null || _r.discount != null || _r.tax != null)
            Divider(color: c.border, height: DsSpacing.lg),
          row(l.invoiceTotal, _r.total,
              strong: true,
              note: _r.totalComputed ? l.invoiceCalculated : null),
          if (_r.total == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.invoiceIssueTotalMissing,
                  style: t.bodySmall?.copyWith(color: c.expense)),
            ),
        ],
      ),
    );
  }

  List<String> _issueMessages(AppLocalizations l) {
    final List<String> out = <String>[];
    for (final InvoiceIssue i in _r.checks.issues) {
      final String? m = switch (i) {
        InvoiceIssue.lineMismatch => l.invoiceIssueLineMismatch,
        InvoiceIssue.itemsVsSubtotal => l.invoiceIssueItemsVsSubtotal,
        InvoiceIssue.summaryMismatch => l.invoiceIssueSummary,
        InvoiceIssue.totalComputed => l.invoiceIssueTotalComputed,
        // Shown under the total instead.
        InvoiceIssue.totalMissing => null,
        InvoiceIssue.dueMismatch => l.invoiceIssueDue,
        InvoiceIssue.currencyUnknown => l.invoiceIssueCurrencyUnknown,
        InvoiceIssue.currencyConflict => l.invoiceIssueCurrencyConflict,
        InvoiceIssue.dateMissing => l.invoiceIssueDateMissing,
        InvoiceIssue.dateSuspicious => l.invoiceIssueDateOdd,
        InvoiceIssue.amountResolvedByContext => l.invoiceIssueResolved,
      };
      if (m != null) out.add(m);
    }
    return out;
  }

  // ---- editing a line ----

  Future<void> _editLine(int index) async {
    final InvoiceItem? edited = await showDialog<InvoiceItem>(
      context: context,
      builder: (_) => _LineEditor(item: _r.items[index]),
    );
    if (edited == null || !mounted) return;
    final List<InvoiceItem> items = <InvoiceItem>[..._r.items]..[index] = edited;
    setState(() {
      _r = InvoiceAnalyzer.revalidate(_r, items, today: AppClock.now());
    });
  }

  // ---- formatting ----

  String _money(double v) {
    final String? code = _r.currency;
    if (code != null) {
      return MoneyFormatter.format(Money.fromDouble(v, code))
          .replaceAll('‎', '');
    }
    return intl.NumberFormat.decimalPatternDigits(
            locale: 'en', decimalDigits: _r.currencyDecimals)
        .format(v);
  }

  static String _qty(double q) => q == q.roundToDouble()
      ? q.toStringAsFixed(0)
      : q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

  static String _ymd(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: DsSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: DsRadius.brSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}

/// Corrects one line: name, quantity, unit price, line total.
class _LineEditor extends StatefulWidget {
  const _LineEditor({required this.item});
  final InvoiceItem item;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item.name);
  late final TextEditingController _q =
      TextEditingController(text: _text(widget.item.quantity));
  late final TextEditingController _u =
      TextEditingController(text: _text(widget.item.unitPrice));
  late final TextEditingController _t =
      TextEditingController(text: _text(widget.item.lineTotal));

  static String _text(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
  }

  static double? _parse(String s) {
    final String v = s.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    return v.isEmpty ? null : double.tryParse(v);
  }

  @override
  void dispose() {
    _name.dispose();
    _q.dispose();
    _u.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<TextInputFormatter> number = <TextInputFormatter>[
      const LatinDigitsFormatter(),
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
    ];
    const TextInputType numeric =
        TextInputType.numberWithOptions(decimal: true, signed: true);
    return AlertDialog(
      backgroundColor: context.dsColors.bgElevated,
      title: Text(l.invoiceEditLine),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DsTextField(label: l.invoiceItemName, controller: _name),
            const SizedBox(height: DsSpacing.md),
            DsTextField(
                label: l.invoiceQuantity,
                controller: _q,
                keyboardType: numeric,
                inputFormatters: number),
            const SizedBox(height: DsSpacing.md),
            DsTextField(
                label: l.invoiceUnitPrice,
                controller: _u,
                keyboardType: numeric,
                inputFormatters: number),
            const SizedBox(height: DsSpacing.md),
            DsTextField(
                label: l.invoiceLineTotal,
                controller: _t,
                keyboardType: numeric,
                inputFormatters: number),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final double? q = _parse(_q.text);
            final double? u = _parse(_u.text);
            final double? t = _parse(_t.text);
            Navigator.of(context).pop(widget.item.copyWith(
              name: _name.text.trim(),
              quantity: q,
              unitPrice: u,
              lineTotal: t,
              clearQuantity: q == null,
              clearUnitPrice: u == null,
              clearLineTotal: t == null,
              editedByUser: true,
            ));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
