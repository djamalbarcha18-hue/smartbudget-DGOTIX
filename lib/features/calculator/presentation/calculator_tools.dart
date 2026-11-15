import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/money/number_style.dart';
import 'package:smartbudget/core/settings/number_style_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/calculator/domain/calc_tools.dart';
import 'package:smartbudget/features/calculator/domain/calculator_engine.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

enum CalcMode { standard, tax, discount, margin, split }

/// The tools under the keypad, worked on the number shown: tax and discount
/// for everyone; margin, bill split and recording the result as a
/// transaction are PRO once [AppEnv.calculatorProGate] is on.
class CalculatorTools extends ConsumerStatefulWidget {
  const CalculatorTools({super.key, required this.state, required this.onUse});

  final ValueNotifier<CalcState> state;

  /// Puts a tool's figure on the calculator, to go on from it.
  final ValueChanged<CalcNumber> onUse;

  @override
  ConsumerState<CalculatorTools> createState() => _CalculatorToolsState();
}

class _CalculatorToolsState extends ConsumerState<CalculatorTools> {
  /// The last rates used, on this device (a preference, not a calculation).
  static const String _taxKey = 'sb_calc_tax_rate';
  static const String _discountKey = 'sb_calc_discount_rate';
  static const String _marginKey = 'sb_calc_margin_rate';

  CalcMode _mode = CalcMode.standard;
  final TextEditingController _tax = TextEditingController(text: '19');
  final TextEditingController _discount = TextEditingController(text: '10');
  final TextEditingController _margin = TextEditingController(text: '20');
  int _people = 2;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _tax.text = p.getString(_taxKey) ?? _tax.text;
        _discount.text = p.getString(_discountKey) ?? _discount.text;
        _margin.text = p.getString(_marginKey) ?? _margin.text;
      });
    } catch (_) {
      // Defaults stay.
    }
  }

  Future<void> _remember(String key, String value) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(key, value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tax.dispose();
    _discount.dispose();
    _margin.dispose();
    super.dispose();
  }

  static bool _isPro(CalcMode m) => m == CalcMode.margin || m == CalcMode.split;

  /// True when [AppEnv.calculatorProGate] is off or the plan has the tools;
  /// otherwise the upgrade sheet is shown.
  bool _allowed() {
    if (!AppEnv.calculatorProGate) return true;
    final GateDecision d = ref.read(featureGateProvider(Feature.calculatorPro));
    if (d.allowed) return true;
    UpgradeSheet.show(context, d);
    return false;
  }

  bool get _locked =>
      AppEnv.calculatorProGate &&
      !ref.watch(featureGateProvider(Feature.calculatorPro)).allowed;

  void _record(CalcNumber value, TransactionType type) {
    if (!_allowed()) return;
    TransactionEditorSheet.show(
      context,
      type: type,
      prefill: TransactionDraft(amount: double.tryParse(value.abs.plain())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool locked = _locked;

    String label(CalcMode m) => switch (m) {
          CalcMode.standard => l.calcModeStandard,
          CalcMode.tax => l.calcModeTax,
          CalcMode.discount => l.calcModeDiscount,
          CalcMode.margin => l.calcModeMargin,
          CalcMode.split => l.calcModeSplit,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final CalcMode m in CalcMode.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
                  child: ChoiceChip(
                    key: Key('calc-mode-${m.name}'),
                    label: Text(label(m)),
                    avatar: locked && _isPro(m)
                        ? Icon(Icons.lock_outline_rounded,
                            size: 16, color: c.brand)
                        : null,
                    selected: _mode == m,
                    onSelected: (_) {
                      if (_isPro(m) && !_allowed()) return;
                      setState(() => _mode = m);
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_mode != CalcMode.standard) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          GlassCard(
            child: ValueListenableBuilder<CalcState>(
              valueListenable: widget.state,
              builder: (BuildContext context, CalcState s, Widget? _) =>
                  _panel(context, l, s.current ?? CalcNumber.zero),
            ),
          ),
        ],
        const SizedBox(height: DsSpacing.md),
        ValueListenableBuilder<CalcState>(
          valueListenable: widget.state,
          builder: (BuildContext context, CalcState s, Widget? _) {
            final CalcNumber? v = s.current;
            final bool usable = v != null && !v.isZero;
            return Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
              children: <Widget>[
                OutlinedButton.icon(
                  key: const Key('calc-record-expense'),
                  onPressed: usable
                      ? () => _record(v, TransactionType.expense)
                      : null,
                  icon: Icon(
                      locked ? Icons.lock_outline_rounded : Icons.north_east,
                      size: 18),
                  label: Text(l.calcAddExpense),
                ),
                OutlinedButton.icon(
                  key: const Key('calc-record-income'),
                  onPressed: usable
                      ? () => _record(v, TransactionType.income)
                      : null,
                  icon: Icon(
                      locked ? Icons.lock_outline_rounded : Icons.south_west,
                      size: 18),
                  label: Text(l.calcAddIncome),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _panel(BuildContext context, AppLocalizations l, CalcNumber v) {
    final NumberStyle style = ref.watch(numberStyleProvider);
    String fmt(CalcNumber n) => CalcFormat.format(n.plain(decimals: 2),
        group: style.group, decimal: style.decimal);
    Widget row(String name, CalcNumber value, {String? id, String? sub}) =>
        _ToolRow(
          name: name,
          value: fmt(value),
          sub: sub,
          id: id,
          useLabel: l.calcUse,
          onUse: () => widget.onUse(value),
        );

    CalcNumber rate(TextEditingController c) =>
        CalcNumber.parse(c.text.replaceAll(',', '.').trim()) ?? CalcNumber.zero;

    switch (_mode) {
      case CalcMode.standard:
        return const SizedBox.shrink();
      case CalcMode.tax:
        final (CalcNumber tax, CalcNumber total) = CalcTools.addTax(v, rate(_tax));
        final (CalcNumber, CalcNumber)? out = CalcTools.extractTax(v, rate(_tax));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _RateField(
                label: l.calcRate,
                controller: _tax,
                presets: const <String>['9', '19'],
                onChanged: (String t) {
                  setState(() {});
                  _remember(_taxKey, t);
                }),
            _Heading(l.calcAddTax),
            row(l.calcTaxAmount, tax, id: 'tax-amount'),
            row(l.calcTaxTotal, total, id: 'tax-total'),
            if (out != null) ...<Widget>[
              _Heading(l.calcExtractTax),
              row(l.calcTaxNet, out.$1, id: 'tax-net'),
              row(l.calcTaxInside, out.$2, id: 'tax-inside'),
            ],
          ],
        );
      case CalcMode.discount:
        final (CalcNumber saved, CalcNumber after) =
            CalcTools.discount(v, rate(_discount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _RateField(
                label: l.calcRate,
                controller: _discount,
                presets: const <String>['10', '20', '30', '50'],
                onChanged: (String t) {
                  setState(() {});
                  _remember(_discountKey, t);
                }),
            row(l.calcSaved, saved, id: 'discount-saved'),
            row(l.calcAfterDiscount, after, id: 'discount-after'),
          ],
        );
      case CalcMode.margin:
        final (CalcNumber up, CalcNumber upProfit) =
            CalcTools.markup(v, rate(_margin));
        final (CalcNumber, CalcNumber)? on = CalcTools.marginPrice(v, rate(_margin));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.calcCostHint,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: DsSpacing.sm),
            _RateField(
                label: l.calcRate,
                controller: _margin,
                presets: const <String>['10', '20', '30', '50'],
                onChanged: (String t) {
                  setState(() {});
                  _remember(_marginKey, t);
                }),
            row(l.calcMarkupPrice, up,
                id: 'markup-price', sub: '${l.calcProfit}: ${fmt(upProfit)}'),
            if (on != null)
              row(l.calcMarginPrice, on.$1,
                  id: 'margin-price', sub: '${l.calcProfit}: ${fmt(on.$2)}'),
          ],
        );
      case CalcMode.split:
        final CalcNumber? each = CalcTools.split(v, _people);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(l.calcPeople)),
                _StepButton(
                  id: 'calc-people-minus',
                  icon: Icons.remove_rounded,
                  tooltip: l.calcSubtract,
                  onTap: _people > 2 ? () => setState(() => _people--) : null,
                ),
                SizedBox(
                  width: 48,
                  child: Text('$_people',
                      key: const Key('calc-people'),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.dsColors.textPrimary)),
                ),
                _StepButton(
                  id: 'calc-people-plus',
                  icon: Icons.add_rounded,
                  tooltip: l.calcAdd,
                  onTap: _people < 50 ? () => setState(() => _people++) : null,
                ),
              ],
            ),
            if (each != null) row(l.calcEachPays, each, id: 'split-each'),
          ],
        );
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: DsSpacing.md, bottom: DsSpacing.xs),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: context.dsColors.brand)),
      );
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.name,
    required this.value,
    required this.useLabel,
    required this.onUse,
    this.sub,
    this.id,
  });

  final String name;
  final String value;
  final String? sub;
  final String? id;
  final String useLabel;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: t.bodyMedium?.copyWith(color: c.textMuted)),
                if (sub != null)
                  Text(sub!,
                      textDirection: TextDirection.ltr,
                      style: t.labelSmall?.copyWith(color: c.textFaint)),
              ],
            ),
          ),
          Text(value,
              key: id == null ? null : Key('calc-tool-$id'),
              textDirection: TextDirection.ltr,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: DsSpacing.sm),
          // Sends this figure up to the calculator, to go on from it: a
          // clear brand-blue button, visible in every theme.
          Tooltip(
            message: useLabel,
            child: Semantics(
              button: true,
              label: useLabel,
              excludeSemantics: true,
              child: Material(
                color: c.brand.withValues(alpha: 0.16),
                shape: RoundedRectangleBorder(
                  borderRadius: DsRadius.brMd,
                  side: BorderSide(color: c.brand.withValues(alpha: 0.55)),
                ),
                child: InkWell(
                  key: id == null ? null : Key('calc-use-$id'),
                  borderRadius: DsRadius.brMd,
                  onTap: onUse,
                  child: SizedBox(
                    width: 44,
                    height: 40,
                    child: Icon(Icons.arrow_upward_rounded,
                        size: 22, color: c.brand),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateField extends StatelessWidget {
  const _RateField({
    required this.label,
    required this.controller,
    required this.presets,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final List<String> presets;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    // One point down or up (19% → 18% / 20%), never below 0 or past 999.
    void step(int by) {
      final double now =
          double.tryParse(controller.text.replaceAll(',', '.').trim()) ?? 0;
      final double next = (now + by).clamp(0, 999).toDouble();
      final String text = next == next.roundToDouble()
          ? next.toInt().toString()
          : next.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
      controller.text = text;
      onChanged(text);
    }

    Widget stepButton(IconData icon, String tip, int by, String id) =>
        _StepButton(
            id: 'calc-rate-$id', icon: icon, tooltip: tip, onTap: () => step(by));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            stepButton(Icons.remove_rounded, l.calcRateDown, -1, 'down'),
            const SizedBox(width: DsSpacing.sm),
            Expanded(child: _field()),
            const SizedBox(width: DsSpacing.sm),
            stepButton(Icons.add_rounded, l.calcRateUp, 1, 'up'),
          ],
        ),
        const SizedBox(height: DsSpacing.sm),
        Wrap(
          spacing: DsSpacing.xs,
          runSpacing: DsSpacing.xs,
          children: <Widget>[
            for (final String p in presets)
              ActionChip(
                label: Text('$p%'),
                side: BorderSide(color: c.border),
                onPressed: () {
                  controller.text = p;
                  onChanged(p);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _field() => TextField(
        key: const Key('calc-rate-field'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          LengthLimitingTextInputFormatter(6),
        ],
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
          isDense: true,
          border: const OutlineInputBorder(borderRadius: DsRadius.brMd),
        ),
        onChanged: onChanged,
      );
}

/// A − or + button: a fixed 40×40 blue square with a clear sign, the same in
/// every theme; greyed when it can't go further.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.id,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool on = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: on,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: c.brand.withValues(alpha: on ? 0.16 : 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: DsRadius.brMd,
            side: BorderSide(color: c.brand.withValues(alpha: on ? 0.55 : 0.2)),
          ),
          child: InkWell(
            key: Key(id),
            borderRadius: DsRadius.brMd,
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon,
                  size: 22,
                  color: on ? c.brand : c.brand.withValues(alpha: 0.35)),
            ),
          ),
        ),
      ),
    );
  }
}
