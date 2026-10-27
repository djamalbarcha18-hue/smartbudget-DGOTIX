import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
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
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metal_sale.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Selling some or all of a piece: how many grams, what was received, when.
/// What it earned shows as it is typed.
class MetalSaleSheet extends ConsumerStatefulWidget {
  const MetalSaleSheet({super.key, required this.holding});
  final MetalHolding holding;

  static Future<void> show(BuildContext context, MetalHolding h) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) => MetalSaleSheet(holding: h),
      );

  @override
  ConsumerState<MetalSaleSheet> createState() => _MetalSaleSheetState();
}

class _MetalSaleSheetState extends ConsumerState<MetalSaleSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _grams;
  final TextEditingController _received = TextEditingController();
  DateTime _soldOn = AppClock.now();
  bool _asIncome = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // All of it, unless the user says otherwise.
    _grams =
        TextEditingController(text: AmountInput.text(widget.holding.grams));
    _grams.addListener(_refresh);
    _received.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _grams.dispose();
    _received.dispose();
    super.dispose();
  }

  String get _currency => ref.read(baseCurrencyProvider);

  /// What the sale earns, as typed so far (null until it can be said).
  Gain? _preview() {
    final double? grams = AmountInput.parse(_grams.text);
    final double? received = AmountInput.parse(_received.text);
    if (grams == null || grams <= 0 || grams > widget.holding.grams + 1e-9) {
      return null;
    }
    if (received == null || received <= 0) return null;
    final MetalHolding sold = MetalSales.split(widget.holding, grams).sold;
    return MetalSales.gain(
        MetalSale(
          id: '',
          sold: sold,
          received: Money.fromDouble(received, _currency),
          soldOn: _soldOn,
          createdAt: _soldOn,
        ),
        _currency,
        ref.read(ratesProvider));
  }

  Future<void> _save(String title) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final AppLocalizations l = AppLocalizations.of(context);
    await ref.read(metalActionsProvider).sell(
          widget.holding,
          grams: AmountInput.parse(_grams.text)!,
          received:
              Money.fromDouble(AmountInput.parse(_received.text)!, _currency),
          soldOn: _soldOn,
          incomeLabel: _asIncome ? l.metalsSaleIncome(title) : null,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final MetalHolding h = widget.holding;
    final String title =
        h.name.isNotEmpty ? h.name : MetalText.name(l, h.metal);
    final Gain? preview = _preview();

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
                      MetalBar(metal: h.metal, width: 44),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        child:
                            Text(l.metalsSellTitle(title), style: t.titleLarge),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.metalsSellGrams,
                    controller: _grams,
                    suffixText: l.metalsSellOf(MetalText.grams(l, h.grams)),
                    prefixIcon: Icons.scale_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) {
                      final double g = AmountInput.parse(v ?? '') ?? 0;
                      if (g <= 0) return l.valAmountInvalid;
                      return g > h.grams + 1e-9 ? l.metalsSellTooMany : null;
                    },
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.metalsSellReceived,
                    controller: _received,
                    suffixText: _currency,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) =>
                        (AmountInput.parse(v ?? '') ?? 0) > 0
                            ? null
                            : l.valAmountInvalid,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  Text(l.metalsSellDate,
                      style: t.labelMedium?.copyWith(color: c.textMuted)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: DsRadius.brMd,
                    onTap: () async {
                      final DateTime? d = await showDsDatePicker(
                        context,
                        initialDate: _soldOn,
                        firstDate: DateTime(1950),
                        lastDate: AppClock.now(),
                      );
                      if (d != null) setState(() => _soldOn = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: DsRadius.brMd,
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.event_outlined, color: c.textMuted),
                          const SizedBox(width: DsSpacing.md),
                          Text(
                              dayText(Localizations.localeOf(context), _soldOn),
                              style: t.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  // Its own surface, so the tap shows on the sheet.
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      value: _asIncome,
                      onChanged: (bool? v) =>
                          setState(() => _asIncome = v ?? false),
                      title: Text(l.metalsSellAsIncome, style: t.bodyMedium),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  // What it earns, as soon as it can be said.
                  if (preview != null) ...<Widget>[
                    const SizedBox(height: DsSpacing.xs),
                    Text(
                      l.metalsSellPreview(
                          '\u2066${preview.amount.minorUnits >= 0 ? '+' : ''}'
                          '${MoneyFormatter.format(preview.amount)}\u2069'),
                      style: t.titleSmall?.copyWith(
                          color: preview.isGain ? c.income : c.expense,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  DsButton(
                    label: l.metalsSell,
                    expand: true,
                    onPressed: _saving ? null : () => _save(title),
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
