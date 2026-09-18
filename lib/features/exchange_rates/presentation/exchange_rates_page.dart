import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/exchange_rates/domain/exchange_rate_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ExchangeRatesPage extends ConsumerStatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  ConsumerState<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends ConsumerState<ExchangeRatesPage> {
  final TextEditingController _amount = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'SAR';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Map<String, double> rates = ref.watch(ratesProvider);
    final String base = ref.watch(baseCurrencyProvider);

    final double amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;
    final double converted = ExchangeRateCalculator.convert(
      amount: amount,
      from: _from,
      to: _to,
      ratesVsUsd: rates,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.navExchangeRates,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.xl),

          // Base currency.
          GlassCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l.baseCurrency,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(l.baseCurrencyHint,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _CurrencyDropdown(
                  value: base,
                  onChanged: (String v) =>
                      ref.read(baseCurrencyProvider.notifier).set(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.lg),

          // Converter.
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.converter,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DsSpacing.lg),
                DsTextField(
                  label: l.fieldAmount,
                  controller: _amount,
                  prefixIcon: Icons.tag_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => setState(() {}),
                ),
                const SizedBox(height: DsSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _CurrencyDropdown(
                        value: _from,
                        onChanged: (String v) => setState(() => _from = v),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        final String t = _from;
                        _from = _to;
                        _to = t;
                      }),
                      icon: Icon(Icons.swap_horiz_rounded,
                          color: context.dsColors.brand),
                    ),
                    Expanded(
                      child: _CurrencyDropdown(
                        value: _to,
                        onChanged: (String v) => setState(() => _to = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DsSpacing.md),
                  decoration: BoxDecoration(
                    color: context.dsColors.surfaceMuted,
                    borderRadius: DsRadius.brMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l.result,
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        MoneyFormatter.format(Money.fromDouble(converted, _to)),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.lg),

          // Rates list.
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.rateVsUsd,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DsSpacing.xs),
                Text(l.ratesIndicative,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: DsSpacing.md),
                for (final Currency cur in Currencies.all)
                  _RateRow(
                    currency: cur,
                    rate: rates[cur.code] ?? 0,
                    onEdit: cur.code == 'USD'
                        ? null
                        : () => _editRate(context, cur, rates[cur.code] ?? 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRate(
    BuildContext context,
    Currency cur,
    double current,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextEditingController ctrl =
        TextEditingController(text: current.toString());
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${cur.code} · ${l.rateVsUsd}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok == true) {
      final double n = double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
      if (n > 0) await ref.read(ratesProvider.notifier).setRate(cur.code, n);
    }
    ctrl.dispose();
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: c.bgElevated,
        items: <DropdownMenuItem<String>>[
          for (final Currency cur in Currencies.all)
            DropdownMenuItem<String>(
              value: cur.code,
              child: Text('${cur.code} · ${cur.symbol}'),
            ),
        ],
        onChanged: (String? v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.currency, required this.rate, this.onEdit});
  final Currency currency;
  final double rate;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Text(currency.code,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: Text(ar ? currency.nameAr : currency.nameEn,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
          Text(rate.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: c.textPrimary,
                  )),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 16, color: c.brand),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
