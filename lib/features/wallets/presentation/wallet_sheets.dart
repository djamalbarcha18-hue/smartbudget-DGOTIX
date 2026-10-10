import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<void> _sheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: child,
      ),
    );

class _Frame extends StatelessWidget {
  const _Frame({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(title,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

String _plain(int minor, String currency) {
  final double v = Money(minor, currency).asDouble;
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

// ---------------------------------------------------------------------------
// Create / edit a wallet.

class WalletEditorSheet extends ConsumerStatefulWidget {
  const WalletEditorSheet({super.key, this.existing});
  final Wallet? existing;

  static Future<void> show(BuildContext context, {Wallet? existing}) async {
    if (existing == null &&
        !PlanLimits.allowAdd(context, Feature.wallets,
            (ProviderContainer c) => c.read(walletsProvider).length)) {
      return;
    }
    return _sheet(context, WalletEditorSheet(existing: existing));
  }

  @override
  ConsumerState<WalletEditorSheet> createState() => _WalletEditorSheetState();
}

class _WalletEditorSheetState extends ConsumerState<WalletEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _opening = TextEditingController(
      text: widget.existing == null || widget.existing!.opening.minorUnits == 0
          ? ''
          : _plain(widget.existing!.opening.minorUnits,
              widget.existing!.opening.currencyCode));
  late WalletType _type = widget.existing?.type ?? WalletType.cash;
  late String? _currency = widget.existing?.currency;
  bool _makeDefault = false;
  String? _error;

  bool get _general => widget.existing?.isGeneral ?? false;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    if (!_general && _name.text.trim().isEmpty) {
      setState(() => _error = l.valRequired);
      return;
    }
    final String currency = _general
        ? ref.read(baseCurrencyProvider)
        : _currency ?? ref.read(baseCurrencyProvider);
    final String raw = _opening.text.trim();
    final double opening = raw.isEmpty
        ? 0
        : double.tryParse(raw.replaceAll(' ', '').replaceAll(',', '.')) ??
            double.nan;
    if (opening.isNaN) {
      setState(() => _error = l.valAmountInvalid);
      return;
    }
    final Wallet? e = widget.existing;
    final Wallet w = Wallet(
      id: e?.id ?? WalletActions.newWalletId(),
      name: _general ? '' : _name.text.trim(),
      type: _general ? WalletType.other : _type,
      opening: Money.fromDouble(opening, currency),
      createdAt: e?.createdAt ?? AppClock.now(),
    );
    await ref.read(walletActionsProvider).save(w);
    if (_makeDefault) await ref.read(defaultWalletProvider.notifier).set(w.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String base = ref.watch(baseCurrencyProvider);
    final String currency = _general ? base : _currency ?? base;
    final List<(WalletType, String)> suggestions =
        WalletSuggestions.forCurrency(base);

    return _Frame(
      icon: Icons.wallet_outlined,
      title: widget.existing == null
          ? l.walletNew
          : l.walletEdit(walletName(l, widget.existing!)),
      children: <Widget>[
        if (!_general) ...<Widget>[
          if (widget.existing == null && suggestions.isNotEmpty) ...<Widget>[
            Text(l.walletSuggested,
                style: t.labelMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.xs),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
              children: <Widget>[
                for (final (WalletType type, String name) in suggestions)
                  ActionChip(
                    label: Text(name),
                    onPressed: () => setState(() {
                      _name.text = name;
                      _type = type;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: DsSpacing.md),
          ],
          TextField(
            controller: _name,
            decoration: InputDecoration(
                labelText: l.walletName, hintText: l.walletNameHint),
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final WalletType type in WalletType.values)
                ChoiceChip(
                  label: Text(walletTypeName(l, type)),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          DropdownButtonFormField<String>(
            // Rebuilt when the choice is put back to the base currency.
            key: ValueKey<String>(currency),
            initialValue: currency,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.walletCurrency,
              helperText: widget.existing == null
                  ? l.walletCurrencyHint
                  : l.walletCurrencyLocked,
              helperMaxLines: 2,
            ),
            items: <DropdownMenuItem<String>>[
              for (final Currency cur in Currencies.all)
                DropdownMenuItem<String>(
                  value: cur.code,
                  child: Row(
                    children: <Widget>[
                      CurrencyFlag(cur, width: 20),
                      const SizedBox(width: DsSpacing.sm),
                      Text('${cur.code} · ${cur.symbol}'),
                    ],
                  ),
                ),
            ],
            onChanged: widget.existing != null
                ? null
                : (String? v) {
                    // Another currency than the base one is a paid feature;
                    // the field goes back to the base currency.
                    if (v != null &&
                        v != base &&
                        !PlanLimits.allow(context, Feature.multiCurrency)) {
                      setState(() => _currency = base);
                      return;
                    }
                    setState(() => _currency = v);
                  },
          ),
          const SizedBox(height: DsSpacing.md),
        ],
        TextField(
          controller: _opening,
          inputFormatters: LatinDigitsFormatter.only,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: '${l.walletOpening} ($currency)',
            helperText: l.walletOpeningHint,
            helperMaxLines: 3,
          ),
        ),
        if (!_general && widget.existing == null) ...<Widget>[
          const SizedBox(height: DsSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _makeDefault,
            onChanged: (bool v) => setState(() => _makeDefault = v),
            title: Text(l.walletMakeDefault, style: t.bodyMedium),
            subtitle: Text(l.walletDefaultHint,
                style: t.bodySmall?.copyWith(color: c.textMuted)),
          ),
        ],
        if (_error != null) ...<Widget>[
          const SizedBox(height: DsSpacing.sm),
          Text(_error!, style: t.bodySmall?.copyWith(color: c.expense)),
        ],
        const SizedBox(height: DsSpacing.lg),
        DsButton(
          label: l.save,
          icon: Icons.check_rounded,
          expand: true,
          onPressed: () => _save(l),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Move money between two wallets.

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key, this.fromId});
  final String? fromId;

  static Future<void> show(BuildContext context, {String? fromId}) =>
      _sheet(context, TransferSheet(fromId: fromId));

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _received = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _receivedEdited = false;
  String? _from;
  String? _to;
  DateTime _date = AppClock.now();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _received.dispose();
    _note.dispose();
    super.dispose();
  }

  String _cur(String? id) => ref.read(walletCurrencyProvider(id));

  /// Keeps "received" in step with the amount at the app's rate until the
  /// user types the real figure themselves.
  void _syncReceived() {
    if (_receivedEdited) return;
    final double? a = parseAmount(_amount.text);
    final String fc = _cur(_from);
    final String tc = _cur(_to);
    if (a == null || fc == tc) {
      _received.text = '';
      return;
    }
    final Money? conv = WalletMath.convert(
        Money.fromDouble(a, fc), tc, ref.read(ratesProvider));
    _received.text = conv == null ? '' : _plain(conv.minorUnits, tc);
  }

  Future<void> _save(AppLocalizations l) async {
    final double? amount = parseAmount(_amount.text);
    if (_from == null || _to == null || _from == _to) {
      setState(() => _error = l.walletTransferSame);
      return;
    }
    if (amount == null) {
      setState(() => _error = l.valAmountInvalid);
      return;
    }
    final String fc = _cur(_from);
    final String tc = _cur(_to);
    final double? received = fc == tc ? null : parseAmount(_received.text);
    if (fc != tc && received == null) {
      setState(() => _error = l.walletReceivedRequired);
      return;
    }
    await ref.read(walletActionsProvider).transfer(
          fromId: _from!,
          toId: _to!,
          amount: Money.fromDouble(amount, fc),
          toAmount: received == null ? null : Money.fromDouble(received, tc),
          date: _date,
          note: _note.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  /// "1 EUR = 245.50 DZD", from what the user typed.
  String? _rateLine(AppLocalizations l) {
    final double? a = parseAmount(_amount.text);
    final double? r = parseAmount(_received.text);
    if (a == null || r == null) return null;
    final double rate = r / a;
    final String shown = rate >= 100
        ? rate.toStringAsFixed(2)
        : rate >= 1
            ? rate.toStringAsFixed(4)
            : rate.toStringAsFixed(6);
    // Isolated left-to-right so "1 USD = 134.50 DZD" never flips in Arabic.
    return '\u2066${l.walletRateLine(_cur(_from), shown, _cur(_to))}\u2069';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<Wallet> wallets = ref.watch(walletsProvider);
    final Map<String, int> balances = ref.watch(walletBalancesProvider);
    _from ??= widget.fromId ?? wallets.first.id;
    _to ??= wallets.firstWhere((Wallet w) => w.id != _from,
        orElse: () => wallets.first).id;

    Widget picker(String label, String? value, ValueChanged<String?> onChanged) =>
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: <DropdownMenuItem<String>>[
            for (final Wallet w in wallets)
              DropdownMenuItem<String>(
                value: w.id,
                child: Text(
                    '${walletName(l, w)} · ${MoneyFormatter.format(Money(balances[w.id] ?? 0, w.currency))}',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        );

    return _Frame(
      icon: Icons.swap_horiz_rounded,
      title: l.walletTransfer,
      children: <Widget>[
        Text(l.walletTransferHint,
            style: t.bodySmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.md),
        picker(l.walletFrom, _from, (String? v) => setState(() {
              _from = v;
              _syncReceived();
            })),
        const SizedBox(height: DsSpacing.md),
        picker(l.walletTo, _to, (String? v) => setState(() {
              _to = v;
              _syncReceived();
            })),
        const SizedBox(height: DsSpacing.md),
        TextField(
          controller: _amount,
          inputFormatters: LatinDigitsFormatter.only,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(_syncReceived),
          decoration:
              InputDecoration(labelText: '${l.walletSent} (${_cur(_from)})'),
        ),
        if (_cur(_from) != _cur(_to)) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          TextField(
            controller: _received,
            inputFormatters: LatinDigitsFormatter.only,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _receivedEdited = true),
            decoration: InputDecoration(
              labelText: '${l.walletReceivedLabel} (${_cur(_to)})',
              helperText: l.walletReceivedHint,
              helperMaxLines: 3,
            ),
          ),
          if (_rateLine(l) != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(_rateLine(l)!,
                style: t.labelMedium?.copyWith(color: c.brand)),
          ],
        ],
        const SizedBox(height: DsSpacing.md),
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: '${l.fieldNotes} (${l.optional})'),
        ),
        const SizedBox(height: DsSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
                '${l.fieldDate}: \u2066${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}\u2069'),
            onPressed: () async {
              final DateTime? d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2015),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        if (_error != null)
          Text(_error!, style: t.bodySmall?.copyWith(color: c.expense)),
        const SizedBox(height: DsSpacing.lg),
        DsButton(
          label: l.walletTransferDo,
          icon: Icons.swap_horiz_rounded,
          expand: true,
          onPressed: () => _save(l),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compare the app's balance with the real one and fix the difference.

class ReconcileSheet extends ConsumerStatefulWidget {
  const ReconcileSheet({super.key, required this.wallet});
  final Wallet wallet;

  static Future<void> show(BuildContext context, Wallet wallet) =>
      _sheet(context, ReconcileSheet(wallet: wallet));

  @override
  ConsumerState<ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends ConsumerState<ReconcileSheet> {
  final TextEditingController _actual = TextEditingController();

  @override
  void dispose() {
    _actual.dispose();
    super.dispose();
  }

  int? get _actualMinor {
    final String raw = _actual.text.trim();
    if (raw.isEmpty) return null;
    final double? v =
        double.tryParse(raw.replaceAll(' ', '').replaceAll(',', '.'));
    return v == null
        ? null
        : Money.fromDouble(v, widget.wallet.currency).minorUnits;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = widget.wallet.currency;
    final int app = ref.watch(walletBalancesProvider)[widget.wallet.id] ?? 0;
    final int? actual = _actualMinor;
    final int? diff = actual == null ? null : actual - app;
    final WalletActions actions = ref.read(walletActionsProvider);

    return _Frame(
      icon: Icons.price_check_rounded,
      title: l.walletReconcileTitle(walletName(l, widget.wallet)),
      children: <Widget>[
        Text(l.walletReconcileHint,
            style: t.bodySmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.md),
        Container(
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Text(l.walletAppBalance,
                      style: t.bodyMedium?.copyWith(color: c.textMuted))),
              Text(MoneyFormatter.format(Money(app, currency)),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: DsSpacing.md),
        TextField(
          controller: _actual,
          autofocus: true,
          inputFormatters: LatinDigitsFormatter.only,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              labelText: '${l.walletActualBalance} ($currency)'),
        ),
        const SizedBox(height: DsSpacing.md),
        if (diff != null && diff == 0)
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: c.income, size: 18),
              const SizedBox(width: DsSpacing.sm),
              Text(l.walletMatches, style: t.bodyMedium),
            ],
          )
        else if (diff != null) ...<Widget>[
          Text(
            diff < 0
                ? l.walletMissing(MoneyFormatter.format(Money(-diff, currency)))
                : l.walletExtra(MoneyFormatter.format(Money(diff, currency))),
            style: t.bodyMedium?.copyWith(
                color: diff < 0 ? c.expense : c.income,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: diff < 0 ? l.walletRecordExpense : l.walletRecordIncome,
            icon: Icons.receipt_long_outlined,
            expand: true,
            onPressed: () async {
              await actions.recordDifference(widget.wallet.id,
                  Money(diff, currency), l.walletUnrecorded);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton(
            label: l.walletJustCorrect,
            icon: Icons.tune_rounded,
            variant: DsButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              await actions.adjust(widget.wallet.id, Money(diff, currency));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.walletCorrectHint,
              style: t.labelSmall?.copyWith(color: c.textFaint)),
        ],
      ],
    );
  }
}
