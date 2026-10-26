import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_date_picker.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Adds or edits one piece or bar of gold, silver or platinum.
class MetalEditorSheet extends ConsumerStatefulWidget {
  const MetalEditorSheet({super.key, this.existing});
  final MetalHolding? existing;

  static Future<void> show(BuildContext context, {MetalHolding? existing}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) => MetalEditorSheet(existing: existing),
      );

  @override
  ConsumerState<MetalEditorSheet> createState() => _MetalEditorSheetState();
}

class _MetalEditorSheetState extends ConsumerState<MetalEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _grams;
  late final TextEditingController _name;
  late final TextEditingController _paid;
  late Metal _metal;
  late int _purity;
  DateTime? _boughtOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final MetalHolding? e = widget.existing;
    _metal = e?.metal ?? Metal.gold;
    _purity = e?.purity ?? _metal.defaultPurity;
    _grams =
        TextEditingController(text: e == null ? '' : AmountInput.text(e.grams));
    _name = TextEditingController(text: e?.name ?? '');
    _paid = TextEditingController(
        text: e?.paid == null ? '' : AmountInput.text(e!.paid!.asDouble));
    _boughtOn = e?.boughtOn;
  }

  @override
  void dispose() {
    _grams.dispose();
    _name.dispose();
    _paid.dispose();
    super.dispose();
  }

  /// What was paid is kept in its own currency when editing.
  String get _paidCurrency =>
      widget.existing?.paid?.currencyCode ?? ref.read(baseCurrencyProvider);

  Future<void> _save() async {
    if (_saving) return; // a second tap while saving
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final double grams = AmountInput.parse(_grams.text) ?? 0;
    final double? paid = AmountInput.parse(_paid.text);
    final MetalHolding? e = widget.existing;
    await ref.read(metalActionsProvider).save(MetalHolding(
          id: e?.id ?? MetalActions.newId(),
          metal: _metal,
          grams: grams,
          purity: _purity,
          name: _name.text.trim(),
          paid: paid == null || paid <= 0
              ? null
              : Money.fromDouble(paid, _paidCurrency),
          boughtOn: _boughtOn,
          createdAt: e?.createdAt ?? AppClock.now(),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;

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
                          widget.existing == null
                              ? l.metalsAddTitle
                              : l.metalsEditTitle,
                          style: t.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  Row(
                    children: <Widget>[
                      for (final Metal m in Metal.values) ...<Widget>[
                        if (m != Metal.values.first)
                          const SizedBox(width: DsSpacing.sm),
                        Expanded(
                          child: _MetalChoice(
                            metal: m,
                            selected: m == _metal,
                            onTap: () => setState(() {
                              _metal = m;
                              if (!m.purities.contains(_purity)) {
                                _purity = m.defaultPurity;
                              }
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.metalsFieldWeight,
                    controller: _grams,
                    prefixIcon: Icons.scale_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) =>
                        (AmountInput.parse(v ?? '') ?? 0) > 0
                            ? null
                            : l.valAmountInvalid,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  Text(
                      _metal == Metal.gold
                          ? l.metalsFieldKarat
                          : l.metalsFieldFineness,
                      style: t.labelMedium?.copyWith(color: c.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: DsSpacing.sm,
                    runSpacing: DsSpacing.sm,
                    children: <Widget>[
                      for (final int p in _metal.purities)
                        ChoiceChip(
                          label: Text(MetalText.purity(l, _metal, p)),
                          selected: p == _purity,
                          onSelected: (_) => setState(() => _purity = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.metalsFieldName} (${l.optional})',
                    hintText: l.metalsFieldNameHint,
                    controller: _name,
                    prefixIcon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.metalsFieldPaid} (${l.optional})',
                    suffixText: _paidCurrency,
                    controller: _paid,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  Text('${l.metalsFieldBoughtOn} (${l.optional})',
                      style: t.labelMedium?.copyWith(color: c.textMuted)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: DsRadius.brMd,
                    onTap: () async {
                      final DateTime? d = await showDsDatePicker(
                        context,
                        initialDate: _boughtOn ?? AppClock.now(),
                        firstDate: DateTime(1950),
                        lastDate: AppClock.now(),
                      );
                      if (d != null) setState(() => _boughtOn = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: DsRadius.brMd,
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.event_outlined, color: c.textMuted),
                          const SizedBox(width: DsSpacing.md),
                          Expanded(
                            child: Text(
                              _boughtOn == null
                                  ? '—'
                                  : dayText(Localizations.localeOf(context),
                                      _boughtOn!),
                              style: t.bodyMedium,
                            ),
                          ),
                          if (_boughtOn == null)
                            const SizedBox(height: 40)
                          else
                            IconButton(
                              icon:
                                  Icon(Icons.close_rounded, color: c.textMuted),
                              onPressed: () => setState(() => _boughtOn = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xl),
                  DsButton(
                    label: l.save,
                    expand: true,
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

class _MetalChoice extends StatelessWidget {
  const _MetalChoice(
      {required this.metal, required this.selected, required this.onTap});
  final Metal metal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final MetalPalette p = MetalPalette.of(metal);
    return InkWell(
      onTap: onTap,
      borderRadius: DsRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? null : c.surfaceMuted,
          gradient: selected ? p.polish : null,
          borderRadius: DsRadius.brMd,
          border: Border.all(
              color: selected ? p.edge : c.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: <Widget>[
            Opacity(
              opacity: selected ? 1 : 0.6,
              child: MetalBar(metal: metal, width: 44),
            ),
            const SizedBox(height: 4),
            Text(
              MetalText.name(AppLocalizations.of(context), metal),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? p.ink : c.textMuted,
                  fontWeight: selected ? FontWeight.w800 : null),
            ),
          ],
        ),
      ),
    );
  }
}
