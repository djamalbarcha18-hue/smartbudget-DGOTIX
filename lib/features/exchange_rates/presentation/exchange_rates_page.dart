import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
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
    final FxStatus fx = ref.watch(fxStatusProvider);
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(l.rateVsUsd,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (fx.loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: l.fxRefreshRates,
                        onPressed: () =>
                            ref.read(ratesProvider.notifier).refresh(force: true),
                        icon: Icon(Icons.refresh_rounded,
                            size: 20, color: context.dsColors.brand),
                      ),
                  ],
                ),
                const SizedBox(height: DsSpacing.xs),
                _FxStatusLine(status: fx),
                const SizedBox(height: DsSpacing.md),
                for (final Currency cur in Currencies.all)
                  _RateRow(
                    currency: cur,
                    rate: rates[cur.code] ?? 0,
                    tag: _tagFor(cur.code, fx),
                    onEdit: cur.code == 'USD'
                        ? null
                        : () => _editRate(context, cur, rates[cur.code] ?? 0),
                    onReset: fx.manualCodes.contains(cur.code)
                        ? () => ref
                            .read(ratesProvider.notifier)
                            .clearOverride(cur.code)
                        : null,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CurrencyFlag(cur, width: 22),
                  const SizedBox(width: DsSpacing.sm),
                  Text('${cur.code} · ${cur.symbol}'),
                ],
              ),
            ),
        ],
        onChanged: (String? v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

/// How a listed rate is sourced, shown honestly next to each row.
enum _RateTag { none, live, manual, indicative }

_RateTag _tagFor(String code, FxStatus fx) {
  if (code == 'USD') return _RateTag.none;
  if (fx.manualCodes.contains(code)) return _RateTag.manual;
  if (fx.liveCodes.contains(code)) return _RateTag.live;
  return _RateTag.indicative;
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.currency,
    required this.rate,
    this.tag = _RateTag.none,
    this.onEdit,
    this.onReset,
  });
  final Currency currency;
  final double rate;
  final _RateTag tag;
  final VoidCallback? onEdit;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          CurrencyFlag(currency, width: 24),
          const SizedBox(width: DsSpacing.md),
          SizedBox(
            width: 52,
            child: Text(currency.code,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(ar ? currency.nameAr : currency.nameEn,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                if (tag != _RateTag.none) ...<Widget>[
                  const SizedBox(width: DsSpacing.sm),
                  _RateTagChip(tag: tag),
                ],
              ],
            ),
          ),
          Text(rate.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: c.textPrimary,
                  )),
          if (onReset != null)
            IconButton(
              tooltip: l.fxResetToLive,
              onPressed: onReset,
              icon: Icon(Icons.settings_backup_restore_rounded,
                  size: 16, color: c.textMuted),
            ),
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

class _RateTagChip extends StatelessWidget {
  const _RateTagChip({required this.tag});
  final _RateTag tag;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final (String, Color) data = switch (tag) {
      _RateTag.live => (l.fxTagLive, c.income),
      _RateTag.manual => (l.fxTagManual, c.brand),
      _RateTag.indicative => (l.fxTagIndicative, c.textFaint),
      _RateTag.none => ('', c.textFaint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.$1,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: data.$2, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Live-status line under the rates header: live + as-of + source, or an honest
/// "unavailable" note. Never shows a fabricated freshness claim.
class _FxStatusLine extends StatelessWidget {
  const _FxStatusLine({required this.status});
  final FxStatus status;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextStyle? style =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: c.textMuted);

    if (status.loading && !status.live) {
      return Text(l.fxUpdating, style: style);
    }
    if (status.live) {
      final List<String> parts = <String>[l.fxLiveRates];
      if (status.asOf != null) parts.add(l.fxAsOf(_fmtDate(status.asOf!)));
      if (status.source != null && status.source!.isNotEmpty) {
        parts.add(l.fxSource(status.source!));
      }
      return Row(
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: c.income),
          const SizedBox(width: DsSpacing.xs),
          Expanded(child: Text(parts.join(' · '), style: style)),
        ],
      );
    }
    // Not live yet: either still starting up, or the feed failed.
    return Text(
      status.error ? l.fxUnavailableNote : l.ratesIndicative,
      style: style?.copyWith(color: status.error ? c.expense : c.textMuted),
    );
  }

  String _fmtDate(DateTime d) {
    final DateTime local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
