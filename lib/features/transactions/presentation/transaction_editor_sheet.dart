import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Initial values for a NEW transaction, e.g. extracted from a scanned receipt.
class TransactionDraft {
  const TransactionDraft({
    this.amount,
    this.category,
    this.date,
    this.description,
  });

  final double? amount;
  final String? category;
  final DateTime? date;
  final String? description;
}

/// Quick-add / edit sheet for a single transaction (income or expense).
class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({
    super.key,
    required this.type,
    this.existing,
    this.prefill,
    this.initialRepeat,
  });

  final TransactionType type;
  final Transaction? existing;

  /// Pre-selected repeat for a NEW transaction (e.g. from the Recurring page).
  final RecurrenceFrequency? initialRepeat;

  /// Initial values for a NEW transaction (e.g. from a scanned receipt).
  /// Ignored when [existing] is set. All fields stay editable.
  final TransactionDraft? prefill;

  /// Opens the editor as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required TransactionType type,
    Transaction? existing,
    TransactionDraft? prefill,
    RecurrenceFrequency? initialRepeat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => TransactionEditorSheet(
        type: type,
        existing: existing,
        prefill: prefill,
        initialRepeat: initialRepeat,
      ),
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
  RecurrenceFrequency? _repeat;
  String? _walletId;
  String? _initialWallet;
  bool _saving = false;

  bool get _isIncome => widget.type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    final Transaction? e = widget.existing;
    final TransactionDraft? p = e == null ? widget.prefill : null;
    _amount = TextEditingController(
      text: e != null
          ? e.amount.asDouble.toString()
          : (p?.amount != null ? p!.amount.toString() : ''),
    );
    _description =
        TextEditingController(text: e?.description ?? p?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? p?.date ?? AppClock.now();
    _category = e?.category ?? p?.category;
    _paymentMethod = e?.paymentMethod;
    _repeat = e == null ? widget.initialRepeat : null;
    _walletId = e != null
        ? e.walletId ?? Wallet.generalId
        : ref.read(effectiveDefaultWalletProvider);
    _initialWallet = _walletId;
  }

  /// The wallet's currency; an edited transaction keeps its own currency
  /// unless it is moved to another wallet.
  String _currency() {
    final Transaction? e = widget.existing;
    if (e != null && _walletId == _initialWallet) return e.amount.currencyCode;
    return ref.read(walletCurrencyProvider(_walletId));
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
    final String currency = _currency();
    final String base = ref.read(baseCurrencyProvider);
    final Money money = Money.fromDouble(amount, currency);
    final Transaction? old = widget.existing;
    // Keep the rate it was recorded at unless the amount itself changed.
    final Money? baseValue = currency == base
        ? null
        : old != null &&
                old.amount == money &&
                old.baseAmount?.currencyCode == base
            ? old.baseAmount
            : WalletMath.baseValue(money, base, ref.read(ratesProvider));
    final Transaction txn = Transaction(
      id: widget.existing?.id ?? TransactionActions.newId(),
      date: _date,
      type: widget.type,
      category: _category ?? Catalog.categoriesFor(widget.type).last,
      amount: money,
      baseAmount: baseValue,
      description: _description.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      walletId: _walletId == null || _walletId == Wallet.generalId
          ? null
          : _walletId,
      createdAt: widget.existing?.createdAt ?? AppClock.now(),
    );
    final TransactionActions actions = ref.read(transactionActionsProvider);
    if (widget.existing == null && _repeat != null) {
      await ref.read(recurringActionsProvider).startFrom(txn, _repeat!);
    } else if (widget.existing == null) {
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
    ref.watch(walletsProvider);
    final String base = ref.watch(baseCurrencyProvider);
    final Currency cur = Currencies.byCode(_currency());
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
                  if (cur.code != base) ...<Widget>[
                    const SizedBox(height: DsSpacing.xs),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amount,
                      builder: (BuildContext context, TextEditingValue v, _) {
                        final double n = double.tryParse(
                                v.text.trim().replaceAll(',', '.')) ??
                            0;
                        final Money? eq = WalletMath.convert(
                            Money.fromDouble(n, cur.code),
                            base,
                            ref.watch(ratesProvider));
                        return Text(
                          eq == null
                              ? l.walletForeignNoRate(cur.code)
                              : l.walletForeignNote(MoneyFormatter.format(eq)),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: eq == null ? c.warning : c.textMuted),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  _CategoryDropdown(
                    label: l.fieldCategory,
                    hint: l.selectCategory,
                    value: _category,
                    items: ref.watch(categoriesForProvider(widget.type)),
                    onChanged: (String? v) => setState(() => _category = v),
                    validator: (String? v) =>
                        v == null ? l.selectCategory : null,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _DateField(label: l.fieldDate, date: _date, onTap: _pickDate),
                  if (widget.existing == null) ...<Widget>[
                    const SizedBox(height: DsSpacing.lg),
                    _RepeatDropdown(
                      value: _repeat,
                      onChanged: (RecurrenceFrequency? v) =>
                          setState(() => _repeat = v),
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldDescription} (${l.optional})',
                    controller: _description,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  if (ref.watch(hasWalletsProvider)) ...<Widget>[
                    _WalletDropdown(
                      value: _walletId,
                      onChanged: (String? v) => setState(() => _walletId = v),
                    ),

                    const SizedBox(height: DsSpacing.lg),
                  ],
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

/// Label for a repeat choice (null = doesn't repeat).
String repeatLabel(AppLocalizations l, RecurrenceFrequency? f) => switch (f) {
      null => l.repeatNone,
      RecurrenceFrequency.weekly => l.repeatWeekly,
      RecurrenceFrequency.monthly => l.repeatMonthly,
      RecurrenceFrequency.yearly => l.repeatYearly,
    };

class _RepeatDropdown extends StatelessWidget {
  const _RepeatDropdown({required this.value, required this.onChanged});

  final RecurrenceFrequency? value;
  final ValueChanged<RecurrenceFrequency?> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.fieldRepeat, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<RecurrenceFrequency?>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.bgElevated,
          style: t.bodyMedium?.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceMuted,
            prefixIcon: Icon(Icons.event_repeat_outlined,
                size: 18, color: c.textMuted),
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
          items: <RecurrenceFrequency?>[null, ...RecurrenceFrequency.values]
              .map((RecurrenceFrequency? f) =>
                  DropdownMenuItem<RecurrenceFrequency?>(
                      value: f, child: Text(repeatLabel(l, f))))
              .toList(),
          onChanged: onChanged,
        ),
        if (value != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(l.repeatHint,
              style: t.labelSmall?.copyWith(color: c.textFaint)),
        ],
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


class _WalletDropdown extends ConsumerWidget {
  const _WalletDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Wallet> wallets = ref.watch(walletsProvider);
    final Set<String> known = <String>{for (final Wallet w in wallets) w.id};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.fieldWallet, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: WalletMath.resolve(value, known),
          isExpanded: true,
          dropdownColor: c.bgElevated,
          style: t.bodyMedium?.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceMuted,
            prefixIcon: Icon(Icons.wallet_outlined, color: c.textMuted),
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
          items: <DropdownMenuItem<String>>[
            for (final Wallet w in wallets)
              DropdownMenuItem<String>(
                value: w.id,
                child: Row(
                  children: <Widget>[
                    Icon(walletIcon(w), size: 18, color: walletColor(w)),
                    const SizedBox(width: DsSpacing.sm),
                    Flexible(
                        child: Text(walletName(l, w),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
