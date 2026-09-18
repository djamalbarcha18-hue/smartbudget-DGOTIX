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
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class DebtEditorSheet extends ConsumerStatefulWidget {
  const DebtEditorSheet({super.key, this.existing});
  final Debt? existing;

  static Future<void> show(BuildContext context, {Debt? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => DebtEditorSheet(existing: existing),
    );
  }

  @override
  ConsumerState<DebtEditorSheet> createState() => _DebtEditorSheetState();
}

class _DebtEditorSheetState extends ConsumerState<DebtEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _party;
  late final TextEditingController _original;
  late final TextEditingController _paid;
  late DebtType _type;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Debt? e = widget.existing;
    _party = TextEditingController(text: e?.party ?? '');
    _original =
        TextEditingController(text: e == null ? '' : e.original.asDouble.toString());
    _paid = TextEditingController(
        text: e == null || e.paid.isZero ? '' : e.paid.asDouble.toString());
    _type = e?.type ?? DebtType.borrowed;
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _party.dispose();
    _original.dispose();
    _paid.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final String currency = ref.read(baseCurrencyProvider);
    final double original =
        double.tryParse(_original.text.trim().replaceAll(',', '.')) ?? 0;
    final double paid =
        double.tryParse(_paid.text.trim().replaceAll(',', '.')) ?? 0;
    final Debt debt = Debt(
      id: widget.existing?.id ?? DebtActions.newId(),
      party: _party.text.trim(),
      type: _type,
      original: Money.fromDouble(original, currency),
      paid: Money.fromDouble(paid, currency),
      date: widget.existing?.date ?? DateTime.now(),
      dueDate: _dueDate,
      notes: widget.existing?.notes,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    final DebtActions actions = ref.read(debtActionsProvider);
    if (widget.existing == null) {
      await actions.add(debt);
    } else {
      await actions.update(debt);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final Currency cur = Currencies.byCode(ref.watch(baseCurrencyProvider));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                      Expanded(
                        child: Text(
                          widget.existing == null ? l.addDebt : l.editDebt,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _TypeSelector(
                    value: _type,
                    onChanged: (DebtType v) => setState(() => _type = v),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.fieldParty,
                    controller: _party,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (String? v) =>
                        (v ?? '').trim().isEmpty ? l.valRequired : null,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldOriginal} (${cur.symbol})',
                    controller: _original,
                    prefixIcon: Icons.tag_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) {
                      final double n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.')) ??
                          0;
                      return n > 0 ? null : l.valAmountInvalid;
                    },
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldPaid} (${cur.symbol}) · ${l.optional}',
                    controller: _paid,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _DueDateField(
                    date: _dueDate,
                    onPick: () async {
                      final DateTime? p = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                      );
                      if (p != null) setState(() => _dueDate = p);
                    },
                    onClear: () => setState(() => _dueDate = null),
                  ),
                  const SizedBox(height: DsSpacing.xl),
                  DsButton(label: l.save, expand: true, onPressed: _saving ? null : _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});
  final DebtType value;
  final ValueChanged<DebtType> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);

    Widget seg(String label, DebtType v, Color color) {
      final bool selected = value == v;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(v),
          borderRadius: DsRadius.brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.16) : c.surfaceMuted,
              borderRadius: DsRadius.brMd,
              border: Border.all(color: selected ? color : c.border),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? color : c.textMuted,
                  ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        seg(l.debtLent, DebtType.lent, c.income),
        const SizedBox(width: DsSpacing.md),
        seg(l.debtBorrowed, DebtType.borrowed, c.expense),
      ],
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.date,
    required this.onPick,
    required this.onClear,
  });
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${l.fieldDueDate} (${l.optional})',
            style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
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
                Icon(Icons.event_outlined, size: 18, color: c.textMuted),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Text(
                    date == null ? '—' : DateFormat('yyyy-MM-dd').format(date!),
                    style: t.bodyMedium?.copyWith(color: c.textPrimary),
                  ),
                ),
                if (date != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.clear_rounded, size: 16, color: c.textFaint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
