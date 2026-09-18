import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Quick-add / edit sheet for a single transaction (income or expense).
class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, required this.type, this.existing});

  final TransactionType type;
  final Transaction? existing;

  /// Opens the editor as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required TransactionType type,
    Transaction? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) =>
          TransactionEditorSheet(type: type, existing: existing),
    );
  }

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late DateTime _date;
  String? _category;
  String? _paymentMethod;
  bool _saving = false;

  bool get _isIncome => widget.type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    final Transaction? e = widget.existing;
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.asDouble.toString(),
    );
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
    _category = e?.category;
    _paymentMethod = e?.paymentMethod;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final double amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;

    setState(() => _saving = true);
    final String currency = ref.read(baseCurrencyProvider);
    final Transaction txn = Transaction(
      id: widget.existing?.id ?? TransactionActions.newId(),
      date: _date,
      type: widget.type,
      category: _category ?? Catalog.categoriesFor(widget.type).last,
      amount: Money.fromDouble(amount, currency),
      description: _description.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    final TransactionActions actions = ref.read(transactionActionsProvider);
    if (widget.existing == null) {
      await actions.add(txn);
    } else {
      await actions.update(txn);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final Currency cur = Currencies.byCode(ref.watch(baseCurrencyProvider));
    final Color accent = _isIncome ? c.income : c.expense;
    final String title = widget.existing != null
        ? (_isIncome ? l.editIncome : l.editExpense)
        : (_isIncome ? l.addIncome : l.addExpense);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isIncome
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        child: Text(title,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldAmount} (${cur.symbol})',
                    controller: _amount,
                    prefixIcon: Icons.tag_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (String? v) {
                      final double n =
                          double.tryParse((v ?? '').trim().replaceAll(',', '.')) ??
                              0;
                      return n > 0 ? null : l.valAmountInvalid;
                    },
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _CategoryDropdown(
                    label: l.fieldCategory,
                    hint: l.selectCategory,
                    value: _category,
                    items: Catalog.categoriesFor(widget.type),
                    onChanged: (String? v) => setState(() => _category = v),
                    validator: (String? v) =>
                        v == null ? l.selectCategory : null,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _DateField(label: l.fieldDate, date: _date, onTap: _pickDate),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldDescription} (${l.optional})',
                    controller: _description,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _CategoryDropdown(
                    label: '${l.fieldPaymentMethod} (${l.optional})',
                    hint: l.fieldPaymentMethod,
                    value: _paymentMethod,
                    items: Catalog.paymentMethods,
                    onChanged: (String? v) =>
                        setState(() => _paymentMethod = v),
                  ),
                  const SizedBox(height: DsSpacing.xl),
                  DsButton(
                    label: l.save,
                    expand: true,
                    variant: DsButtonVariant.primary,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: DsRadius.brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: DsRadius.brMd,
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_today_outlined, size: 18, color: c.textMuted),
                const SizedBox(width: DsSpacing.md),
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: t.bodyMedium?.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.bgElevated,
          hint: Text(hint, style: t.bodyMedium?.copyWith(color: c.textFaint)),
          validator: validator,
          style: t.bodyMedium?.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceMuted,
            enabledBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: c.brand),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: items
              .map((String e) => DropdownMenuItem<String>(
                  value: e, child: Text(Catalog.label(e, ar: ar))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
