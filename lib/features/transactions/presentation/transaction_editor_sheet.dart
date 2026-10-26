import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/currency.dart';
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
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/features/privacy/application/privacy_controller.dart';

/// Initial values for a NEW transaction, e.g. extracted from a scanned receipt.
class TransactionDraft {
  const TransactionDraft({
    this.amount,
    this.category,
    this.date,
    this.description,
    this.notes,
    this.walletId,
    this.tripId,
  });

  final double? amount;
  final String? category;
  final DateTime? date;
  final String? description;
  final String? notes;

  /// The wallet to start on; null = the default wallet.
  final String? walletId;

  /// The trip to tag it with (SmartTrip's "Add expense").
  final String? tripId;
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
    // Figures on the screen behind stay hidden while the entry is open.
    return PrivacyController.whileEntering(
      context,
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) => TransactionEditorSheet(
          type: type,
          existing: existing,
          prefill: prefill,
          initialRepeat: initialRepeat,
        ),
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

  /// A repeating item whose amount changes each time (a bonus…).
  bool _variable = false;
  String? _walletId;
  String? _initialWallet;
  bool _saving = false;

  /// The trip picked by hand; until then a new expense follows the trip
  /// under way on its date.
  String? _tripChoice;
  bool _tripTouched = false;

  /// A receipt split across categories: the other categories and their
  /// amounts. The first category ([_category]) takes what's left of the
  /// total. Null when not split.
  List<_SplitLine>? _split;

  /// A new expense, once only, can be split.
  bool get _canSplit =>
      widget.existing == null && !_isIncome && _repeat == null;

  bool get _isIncome => widget.type == TransactionType.income;

  /// The linked trip's kind (its items: flights and stay, or a package).
  TripKind _tripKind() {
    final List<Trip> trips =
        ref.read(tripsProvider).valueOrNull ?? const <Trip>[];
    final String? id = _tripId(trips);
    return trips.where((Trip t) => t.id == id).firstOrNull?.kind ??
        TripKind.independent;
  }

  String? _tripId(List<Trip> trips) {
    if (_isIncome) return null;
    if (_tripTouched) return _tripChoice;
    final Transaction? e = widget.existing;
    if (e != null || !AppEnv.smartTrip) return e?.tripId;
    return TripMath.activeOn(trips, _date)?.id;
  }

  @override
  void initState() {
    super.initState();
    final Transaction? e = widget.existing;
    final TransactionDraft? p = e == null ? widget.prefill : null;
    _amount = TextEditingController(
      text: e != null
          ? AmountInput.text(e.amount.asDouble)
          : (p?.amount != null ? p!.amount.toString() : ''),
    );
    _description =
        TextEditingController(text: e?.description ?? p?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? p?.notes ?? '');
    _date = e?.date ?? p?.date ?? AppClock.now();
    _category = e?.category ?? p?.category;
    _paymentMethod = e?.paymentMethod;
    _repeat = e == null ? widget.initialRepeat : null;
    _walletId = e != null
        ? e.walletId ?? Wallet.generalId
        : p?.walletId ?? ref.read(effectiveDefaultWalletProvider);
    if (p?.tripId != null) {
      _tripTouched = true;
      _tripChoice = p!.tripId;
    }
    _initialWallet = _walletId;
    // The rest of a split follows the total.
    _amount.addListener(_splitChanged);
  }

  void _splitChanged() {
    if (_split != null && mounted) setState(() {});
  }

  void _addSplitLine() {
    final _SplitLine line = _SplitLine()..amount.addListener(_splitChanged);
    setState(() => (_split ??= <_SplitLine>[]).add(line));
  }

  void _removeSplitLine(_SplitLine line) {
    setState(() {
      _split!.remove(line);
      if (_split!.isEmpty) _split = null;
    });
    line.amount.dispose();
  }

  /// What the first category keeps: the total less the other lines.
  Money _splitRest(String currency) {
    final Money total =
        Money.fromDouble(AmountInput.parse(_amount.text) ?? 0, currency);
    return (_split ?? const <_SplitLine>[]).fold<Money>(
        total,
        (Money m, _SplitLine line) => m -
            Money.fromDouble(AmountInput.parse(line.amount.text) ?? 0,
                currency));
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
    for (final _SplitLine line in _split ?? const <_SplitLine>[]) {
      line.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDsDatePicker(
      context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return; // a second tap while saving
    if (!_formKey.currentState!.validate()) return;
    final double amount =
        AmountInput.parse(_amount.text) ?? 0;
    final List<_SplitLine>? split = _split;
    if (split != null && _splitRest(_currency()).minorUnits <= 0) return;

    setState(() => _saving = true);
    if (split != null) {
      await _saveSplit(split);
      return;
    }
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
      walletId:
          _walletId == null || _walletId == Wallet.generalId ? null : _walletId,
      tripId: _tripId(ref.read(tripsProvider).valueOrNull ?? const <Trip>[]),
      createdAt: widget.existing?.createdAt ?? AppClock.now(),
    );
    final TransactionActions actions = ref.read(transactionActionsProvider);
    if (widget.existing == null && _repeat != null) {
      await ref
          .read(recurringActionsProvider)
          .startFrom(txn, _repeat!, variableAmount: _variable);
    } else if (widget.existing == null) {
      await actions.add(txn);
    } else {
      await actions.update(txn);
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Saves a split receipt as one expense per category, sharing a
  /// [Transaction.splitId], the day, wallet, description and notes.
  Future<void> _saveSplit(List<_SplitLine> split) async {
    final String currency = _currency();
    final String base = ref.read(baseCurrencyProvider);
    final Map<String, double> rates = ref.read(ratesProvider);
    final String group = TransactionActions.newId();
    final String? tripId =
        _tripId(ref.read(tripsProvider).valueOrNull ?? const <Trip>[]);
    final List<(String, Money)> parts = <(String, Money)>[
      (
        _category ?? Catalog.categoriesFor(widget.type).last,
        _splitRest(currency)
      ),
      for (final _SplitLine line in split)
        (
          line.category!,
          Money.fromDouble(AmountInput.parse(line.amount.text) ?? 0, currency)
        ),
    ];
    final TransactionActions actions = ref.read(transactionActionsProvider);
    final DateTime now = AppClock.now();
    for (int i = 0; i < parts.length; i++) {
      final (String category, Money money) = parts[i];
      await actions.add(Transaction(
        id: '$group-$i',
        date: _date,
        type: widget.type,
        category: category,
        amount: money,
        baseAmount: WalletMath.baseValue(money, base, rates),
        description: _description.text.trim(),
        paymentMethod: _paymentMethod,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        walletId: _walletId == null || _walletId == Wallet.generalId
            ? null
            : _walletId,
        tripId: tripId,
        splitId: group,
        createdAt: now,
      ));
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
                  if (widget.existing?.splitId != null) ...<Widget>[
                    const SizedBox(height: DsSpacing.sm),
                    Row(
                      children: <Widget>[
                        Icon(Icons.call_split_rounded,
                            size: 16, color: c.textMuted),
                        const SizedBox(width: DsSpacing.xs),
                        Expanded(
                          child: Text(
                            l.splitPartOf((ref
                                        .watch(transactionsProvider)
                                        .valueOrNull ??
                                    const <Transaction>[])
                                .where((Transaction t) =>
                                    t.splitId == widget.existing!.splitId)
                                .length),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: c.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.fieldAmount,
                    suffixText: cur.code,
                    controller: _amount,
                    prefixIcon: Icons.tag_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (String? v) {
                      final double n = AmountInput.parse((v ?? '')) ??
                          0;
                      return n > 0 ? null : l.valAmountInvalid;
                    },
                  ),
                  if (cur.code != base) ...<Widget>[
                    const SizedBox(height: DsSpacing.xs),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amount,
                      builder: (BuildContext context, TextEditingValue v, _) {
                        final double n = AmountInput.parse(v.text) ??
                            0;
                        final Money? eq = WalletMath.convert(
                            Money.fromDouble(n, cur.code),
                            base,
                            ref.watch(ratesProvider));
                        return Text(
                          eq == null
                              ? l.walletForeignNoRate(cur.code)
                              : l.walletForeignNote(MoneyFormatter.format(eq)),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: eq == null ? c.warning : c.textMuted),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  // For a trip: its items first (flights, stay…), each saved
                  // under a category so the month's budget still counts it.
                  if (AppEnv.smartTrip &&
                      !_isIncome &&
                      _tripId(ref.watch(tripsProvider).valueOrNull ??
                              const <Trip>[]) !=
                          null) ...<Widget>[
                    _TripItemChips(
                      kind: _tripKind(),
                      selected: _category == null
                          ? null
                          : TripItems.of(_category!, _tripKind()),
                      onPick: (TripItem i) =>
                          setState(() => _category = TripItems.categoryOf(i)),
                    ),
                    const SizedBox(height: DsSpacing.md),
                  ],
                  _CategoryDropdown(
                    label: l.fieldCategory,
                    hint: l.selectCategory,
                    value: _category,
                    items: ref.watch(categoriesForProvider(widget.type)),
                    onChanged: (String? v) => setState(() => _category = v),
                    validator: (String? v) =>
                        v == null ? l.selectCategory : null,
                  ),
                  if (_split != null)
                    _SplitSection(
                      lines: _split!,
                      rest: _splitRest(cur.code),
                      categories: ref.watch(categoriesForProvider(widget.type)),
                      onAdd: _addSplitLine,
                      onRemove: _removeSplitLine,
                      onCategory: (_SplitLine line, String? v) =>
                          setState(() => line.category = v),
                      onCancel: () {
                        for (final _SplitLine line in _split!) {
                          line.amount.dispose();
                        }
                        setState(() => _split = null);
                      },
                    )
                  else if (_canSplit)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _addSplitLine,
                        icon: const Icon(Icons.call_split_rounded, size: 18),
                        label: Text(l.splitAction),
                      ),
                    ),
                  const SizedBox(height: DsSpacing.lg),
                  _DateField(label: l.fieldDate, date: _date, onTap: _pickDate),
                  _DateShortcuts(
                      date: _date,
                      onPick: (DateTime d) => setState(() => _date = d)),
                  if (widget.existing == null && _split == null) ...<Widget>[
                    const SizedBox(height: DsSpacing.lg),
                    _RepeatDropdown(
                      value: _repeat,
                      showHint: !_variable,
                      onChanged: (RecurrenceFrequency? v) {
                        if (v != null &&
                            _repeat == null &&
                            !_canAddRecurring(context)) {
                          return;
                        }
                        setState(() => _repeat = v);
                      },
                    ),
                    if (_repeat != null)
                      _VariableAmountSwitch(
                        value: _variable,
                        onChanged: (bool v) => setState(() => _variable = v),
                      ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldDescription} (${l.optional})',
                    controller: _description,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  // Free notes; a scanned invoice puts its products here.
                  DsTextField(
                    label: '${l.fieldNotes} (${l.optional})',
                    controller: _notes,
                    prefixIcon: Icons.receipt_long_outlined,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 6,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  if (AppEnv.smartTrip && !_isIncome) ...<Widget>[
                    _TripDropdown(
                      value: _tripId(ref.watch(tripsProvider).valueOrNull ??
                          const <Trip>[]),
                      onChanged: (String? v) => setState(() {
                        _tripTouched = true;
                        _tripChoice = v;
                      }),
                    ),
                  ],
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

/// Today and Yesterday, the two days most entries are for.
class _DateShortcuts extends StatelessWidget {
  const _DateShortcuts({required this.date, required this.onPick});
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DateTime now = AppClock.now();
    final DateTime today = DateUtils.dateOnly(now);
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    final DateTime day = DateUtils.dateOnly(date);
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: Wrap(
        spacing: DsSpacing.sm,
        children: <Widget>[
          ChoiceChip(
            label: Text(l.quickToday),
            selected: day == today,
            onSelected: (_) => onPick(now),
          ),
          ChoiceChip(
            label: Text(l.quickYesterday),
            selected: day == yesterday,
            onSelected: (_) => onPick(yesterday),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.date, required this.onTap});
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
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: c.textMuted),
                const SizedBox(width: DsSpacing.md),
                Text(
                  dayText(Localizations.localeOf(context), date),
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
/// Whether one more recurring rule may be made; shows the upgrade sheet when
/// the plan's limit is reached.
bool _canAddRecurring(BuildContext context) => PlanLimits.allowAdd(
    context,
    Feature.recurringRules,
    (ProviderContainer c) =>
        c.read(recurringRulesProvider).valueOrNull?.length ?? 0);

String repeatLabel(AppLocalizations l, RecurrenceFrequency? f) => switch (f) {
      null => l.repeatNone,
      RecurrenceFrequency.weekly => l.repeatWeekly,
      RecurrenceFrequency.monthly => l.repeatMonthly,
      RecurrenceFrequency.quarterly => l.repeatQuarterly,
      RecurrenceFrequency.halfYearly => l.repeatHalfYearly,
      RecurrenceFrequency.yearly => l.repeatYearly,
    };

/// "The amount changes each time": later occurrences wait for the real
/// amount instead of being added on their own.
class _VariableAmountSwitch extends StatelessWidget {
  const _VariableAmountSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        title: Text(l.repeatVariable, style: t.bodyMedium),
        subtitle: Text(l.repeatVariableHint,
            style: t.labelSmall?.copyWith(color: c.textFaint)),
      ),
    );
  }
}

class _RepeatDropdown extends StatelessWidget {
  const _RepeatDropdown({
    required this.value,
    required this.onChanged,
    this.showHint = true,
  });

  final RecurrenceFrequency? value;
  final ValueChanged<RecurrenceFrequency?> onChanged;

  /// The "added automatically" note (off for a variable amount).
  final bool showHint;

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
            prefixIcon:
                Icon(Icons.event_repeat_outlined, size: 18, color: c.textMuted),
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
        if (value != null && showHint) ...<Widget>[
          const SizedBox(height: 6),
          Text(l.repeatHint, style: t.labelSmall?.copyWith(color: c.textFaint)),
        ],
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  /// Shown above; none inside a split line.
  final String? label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang = appLangOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: t.labelMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<String>(
          // Follows a value set from outside (a trip item).
          key: ValueKey<String?>(value),
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
                  value: e, child: Text(Catalog.label(e, lang: lang))))
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

/// "Part of a trip" (SmartTrip): none, or one of the user's trips, those
/// under way and coming first. Shown only once there is a trip.
class _TripDropdown extends ConsumerWidget {
  const _TripDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Trip> trips =
        ref.watch(tripsProvider).valueOrNull ?? const <Trip>[];
    if (trips.isEmpty) return const SizedBox.shrink();
    final DateTime now = AppClock.now();
    final List<Trip> ordered = <Trip>[
      ...TripMath.current(trips, now),
      ...TripMath.past(trips, now),
    ];
    final String? selected =
        ordered.any((Trip x) => x.id == value) ? value : null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${l.fieldTrip} (${l.optional})',
              style: t.labelMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            // Follows the date until the user picks one.
            key: ValueKey<String?>(selected),
            initialValue: selected,
            isExpanded: true,
            dropdownColor: c.bgElevated,
            style: t.bodyMedium?.copyWith(color: c.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: c.surfaceMuted,
              prefixIcon: Icon(Icons.flight_takeoff_outlined,
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
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(value: null, child: Text(l.tripNone)),
              for (final Trip x in ordered)
                DropdownMenuItem<String?>(
                  value: x.id,
                  child: Text(x.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The trip's items as chips (flights, stay…), above the category.
class _TripItemChips extends StatelessWidget {
  const _TripItemChips(
      {required this.kind, required this.selected, required this.onPick});
  final TripKind kind;
  final TripItem? selected;
  final ValueChanged<TripItem> onPick;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.tripItemPick, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: DsSpacing.xs,
          runSpacing: DsSpacing.xs,
          children: <Widget>[
            for (final TripItem i in TripItems.plannedFor(kind))
              ChoiceChip(
                avatar: Icon(tripItemIcon(i),
                    size: 16,
                    color: selected == i ? c.onBrand : tripItemColor(i)),
                label: Text(tripItemLabel(l, i)),
                selected: selected == i,
                showCheckmark: false,
                selectedColor: c.brand,
                labelStyle: t.bodySmall?.copyWith(
                    color: selected == i ? c.onBrand : c.textPrimary),
                onSelected: (_) => onPick(i),
              ),
          ],
        ),
      ],
    );
  }
}

/// One more category of a split receipt and its amount.
class _SplitLine {
  String? category;
  final TextEditingController amount = TextEditingController();
}

/// The other categories of a split receipt, what's left for the first
/// one, and adding or removing a category.
class _SplitSection extends StatelessWidget {
  const _SplitSection({
    required this.lines,
    required this.rest,
    required this.categories,
    required this.onAdd,
    required this.onRemove,
    required this.onCategory,
    required this.onCancel,
  });

  final List<_SplitLine> lines;
  final Money rest;
  final List<String> categories;
  final VoidCallback onAdd;
  final ValueChanged<_SplitLine> onRemove;
  final void Function(_SplitLine line, String? category) onCategory;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool over = rest.minorUnits <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: DsSpacing.xs),
        // What the first category keeps.
        Row(
          children: <Widget>[
            Icon(Icons.subdirectory_arrow_right_rounded,
                size: 16, color: over ? c.expense : c.textMuted),
            const SizedBox(width: DsSpacing.xs),
            Expanded(
              child: Text(l.splitRest,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
            ),
            Text(MoneyFormatter.format(rest),
                style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: over ? c.expense : c.textPrimary)),
          ],
        ),
        if (over)
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xs),
            child: Text(l.splitTooMuch,
                style: t.labelSmall?.copyWith(color: c.expense)),
          ),
        const SizedBox(height: DsSpacing.md),
        for (final _SplitLine line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: _CategoryDropdown(
                    hint: l.selectCategory,
                    value: line.category,
                    items: categories,
                    onChanged: (String? v) => onCategory(line, v),
                    validator: (String? v) =>
                        v == null ? l.selectCategory : null,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: line.amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: t.bodyMedium?.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: l.fieldAmount,
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
                          horizontal: 14, vertical: 14),
                    ),
                    validator: (String? v) =>
                        (AmountInput.parse(v ?? '') ?? 0) > 0
                            ? null
                            : l.valAmountInvalid,
                  ),
                ),
                IconButton(
                  tooltip: l.delete,
                  onPressed: () => onRemove(line),
                  icon: Icon(Icons.close_rounded, color: c.textMuted),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: DsSpacing.sm,
          children: <Widget>[
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.splitAddLine),
            ),
            TextButton(onPressed: onCancel, child: Text(l.splitCancel)),
          ],
        ),
      ],
    );
  }
}
