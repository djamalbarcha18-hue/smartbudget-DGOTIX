import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_date_picker.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Adds or edits one piece or bar of gold, silver, platinum or palladium.
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
  late final TextEditingController _paidBase;
  late final TextEditingController _making;
  late Metal _metal;
  late int _purity;
  late String _paidCurrency;
  DateTime? _boughtOn;
  bool _saving = false;

  /// The workmanship field, opened from «includes workmanship?».
  bool _showMaking = false;

  /// What the app filled in for [_paidBase]; once the user types something
  /// else, it is left alone.
  String _autoBase = '';
  bool _baseEdited = false;

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
    _paidBase = TextEditingController(
        text: e?.paidBase == null
            ? ''
            : AmountInput.text(e!.paidBase!.asDouble));
    _making = TextEditingController(
        text: e?.making == null ? '' : AmountInput.text(e!.making!.asDouble));
    _showMaking = e?.making != null;
    _baseEdited = e?.paidBase != null;
    // What was paid is kept in its own currency when editing.
    _paidCurrency = e?.paid?.currencyCode ?? ref.read(baseCurrencyProvider);
    _boughtOn = e?.boughtOn;
    _paid.addListener(_fillBase);
    _paidBase.addListener(() {
      if (_paidBase.text != _autoBase) _baseEdited = true;
    });
  }

  @override
  void dispose() {
    _grams.dispose();
    _name.dispose();
    _paid.dispose();
    _paidBase.dispose();
    _making.dispose();
    super.dispose();
  }

  String get _base => ref.read(baseCurrencyProvider);

  /// Paid in another currency: what it comes to in the user's, at today's
  /// rate, until the user enters their own figure.
  void _fillBase() {
    if (_baseEdited || _paidCurrency == _base) return;
    final double? paid = AmountInput.parse(_paid.text);
    final Money? base = paid == null || paid <= 0
        ? null
        : WalletMath.convert(Money.fromDouble(paid, _paidCurrency), _base,
            ref.read(ratesProvider));
    _autoBase = base == null ? '' : AmountInput.text(base.asDouble);
    _paidBase.text = _autoBase;
  }

  Future<void> _save() async {
    if (_saving) return; // a second tap while saving
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final double grams = AmountInput.parse(_grams.text) ?? 0;
    final double? paid = AmountInput.parse(_paid.text);
    final double? paidBase =
        _paidCurrency == _base ? null : AmountInput.parse(_paidBase.text);
    final double? making =
        _showMaking ? AmountInput.parse(_making.text) : null;
    final bool hasPaid = paid != null && paid > 0;
    final MetalHolding? e = widget.existing;
    await ref.read(metalActionsProvider).save(MetalHolding(
          id: e?.id ?? MetalActions.newId(),
          metal: _metal,
          grams: grams,
          purity: _purity,
          name: _name.text.trim(),
          paid: hasPaid ? Money.fromDouble(paid, _paidCurrency) : null,
          paidBase: hasPaid && paidBase != null && paidBase > 0
              ? Money.fromDouble(paidBase, _base)
              : null,
          making: hasPaid && making != null && making > 0
              ? Money.fromDouble(making, _paidCurrency)
              : null,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: DsTextField(
                          label: '${l.metalsFieldPaid} (${l.optional})',
                          controller: _paid,
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      // The currency paid: the user's own unless chosen.
                      SizedBox(
                        width: 104,
                        child: DropdownButtonFormField<String>(
                          initialValue: _paidCurrency,
                          isExpanded: true,
                          dropdownColor: c.bgElevated,
                          menuMaxHeight: 320,
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          items: <DropdownMenuItem<String>>[
                            // The user's own first, then the most used
                            // abroad, then the rest.
                            for (final String code in <String>{
                              _base,
                              _paidCurrency,
                              'USD',
                              'EUR',
                              for (final Currency cur in Currencies.all)
                                cur.code,
                            })
                              DropdownMenuItem<String>(
                                  value: code, child: Text(code)),
                          ],
                          onChanged: (String? v) {
                            if (v == null || v == _paidCurrency) return;
                            setState(() {
                              _paidCurrency = v;
                              _baseEdited = false;
                            });
                            _fillBase();
                          },
                        ),
                      ),
                    ],
                  ),
                  // Paid in another currency: what it came to in the user's.
                  if (_paidCurrency != _base) ...<Widget>[
                    const SizedBox(height: DsSpacing.md),
                    DsTextField(
                      label: l.metalsPaidInBase(_base),
                      suffixText: _base,
                      controller: _paidBase,
                      prefixIcon: Icons.currency_exchange_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 4),
                    Text(l.metalsPaidInBaseHint,
                        style: t.bodySmall?.copyWith(color: c.textFaint)),
                  ],
                  // Jewellery: the part that was workmanship, if wished.
                  if (_showMaking) ...<Widget>[
                    const SizedBox(height: DsSpacing.md),
                    DsTextField(
                      label: l.metalsFieldMaking,
                      suffixText: _paidCurrency,
                      controller: _making,
                      prefixIcon: Icons.handyman_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (String? v) {
                        final double? m = AmountInput.parse(v ?? '');
                        final double paid = AmountInput.parse(_paid.text) ?? 0;
                        return m != null && m > 0 && paid > 0 && m > paid
                            ? l.metalsMakingTooHigh
                            : null;
                      },
                    ),
                  ] else
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showMaking = true),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l.metalsAddMaking),
                      ),
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
