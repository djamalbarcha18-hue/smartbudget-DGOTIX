import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_date_picker.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/card_suggestions.dart';
import 'package:smartbudget/features/subscriptions/domain/service_catalog.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Adds or edits a subscription: the service, what it costs and how often,
/// the next charge (or the end of a free trial), the card, the reminders.
class SubscriptionEditorSheet extends ConsumerStatefulWidget {
  const SubscriptionEditorSheet({super.key, this.existing});
  final SubscriptionItem? existing;

  static Future<void> show(BuildContext context,
      {SubscriptionItem? existing}) async {
    if (existing == null &&
        !PlanLimits.allowAdd(
            context,
            Feature.subscriptions,
            (ProviderContainer c) =>
                c.read(subscriptionsProvider).valueOrNull?.length ?? 0)) {
      return;
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) =>
          SubscriptionEditorSheet(existing: existing),
    );
  }

  @override
  ConsumerState<SubscriptionEditorSheet> createState() =>
      _SubscriptionEditorSheetState();
}

class _SubscriptionEditorSheetState
    extends ConsumerState<SubscriptionEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _card;
  String? _catalogId;
  String? _currency;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime? _date;
  bool _trial = false;
  bool _autoRenew = true;
  bool _remindersOn = true;
  List<int> _days = const <int>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Subscription? s = widget.existing?.sub;
    final RecurringRule? r = widget.existing?.rule;
    _name = TextEditingController(text: s?.provider ?? '')
      ..addListener(_refresh);
    _card = TextEditingController(text: s?.cardName ?? '')
      ..addListener(_refresh);
    _amount = TextEditingController(
        text: r == null ? '' : AmountInput.text(r.amount.asDouble));
    _catalogId = s?.catalogId;
    _currency = r?.amount.currencyCode;
    _frequency = r?.frequency ?? RecurrenceFrequency.monthly;
    _date = r == null
        ? null
        : SubscriptionSchedule.nextCharge(r, AppClock.now());
    _trial = s?.isTrial ?? false;
    _autoRenew = s?.autoRenew ?? true;
    _remindersOn = s?.remindersOn ?? true;
    _days = s == null
        ? SubscriptionReminders.defaultsFor(_frequency)
        : SubscriptionReminders.daysFor(s, _frequency);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _card.dispose();
    super.dispose();
  }

  DateTime get _today {
    final DateTime n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// The country the suggestions are for: the device's region, else the
  /// base currency's country.
  String? _country(String base) {
    final String? device =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (device != null && device.isNotEmpty) return device;
    return Currencies.byCode(base).country.toUpperCase();
  }

  void _pickService(CatalogService s) {
    setState(() {
      _catalogId = s.id;
      _name.text = s.name;
      if (widget.existing == null) {
        _frequency = s.frequency;
        _days = SubscriptionReminders.defaultsFor(_frequency);
      }
    });
  }

  void _setFrequency(RecurrenceFrequency f) {
    setState(() {
      _frequency = f;
      final List<int> allowed = SubscriptionReminders.choicesFor(f);
      final List<int> kept = _days.where(allowed.contains).toList();
      _days = kept.isEmpty ? SubscriptionReminders.defaultsFor(f) : kept;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? p = await showDsDatePicker(
      context,
      initialDate: _date ?? _today,
      firstDate: _today,
      lastDate: DateTime(_today.year + 5, 12, 31),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final DateTime? date = _date;
    if (date == null) return; // the date field says so
    setState(() => _saving = true);
    final String base = ref.read(baseCurrencyProvider);
    final String currency = _currency ?? base;
    final double amount = AmountInput.parse(_amount.text) ?? 0;
    final String provider = _name.text.trim();
    final CatalogService? fromCatalog = ServiceCatalog.byId(_catalogId);
    // A catalog pick whose name was then changed is the user's own service.
    final String? catalogId =
        fromCatalog != null && fromCatalog.name == provider
            ? fromCatalog.id
            : null;
    final Subscription? old = widget.existing?.sub;
    final DateTime now = AppClock.now();
    final SubscriptionStatus status = _trial
        ? SubscriptionStatus.trial
        : (old == null || old.status == SubscriptionStatus.trial
            ? SubscriptionStatus.active
            : old.status);
    final String id = old?.id ?? SubscriptionActions.newId();
    final Subscription s = Subscription(
      id: id,
      ruleId: old?.ruleId ?? id,
      kind: catalogId != null
          ? ServiceCatalog.byId(catalogId)!.kind
          : (old?.kind ?? SubscriptionKind.digital),
      provider: provider,
      catalogId: catalogId,
      planName: old?.planName,
      mobileType: old?.mobileType,
      country: old?.country ?? ServiceCatalog.byId(catalogId)?.country,
      autoRenew: _autoRenew,
      trialEndsAt: _trial ? date : null,
      billedVia: old?.billedVia ?? BilledVia.direct,
      cardName: CardName.clean(_card.text),
      manageUrl: old?.manageUrl ?? ServiceCatalog.byId(catalogId)?.manageUrl,
      notes: old?.notes,
      remindersOn: _remindersOn,
      reminderDays: _days,
      reminderMinutes: old?.reminderMinutes,
      keptUntil: old?.keptUntil,
      status: status,
      cancelRequestedAt: old?.cancelRequestedAt,
      paidUntil: old?.paidUntil,
      endedAt: old?.endedAt,
      payments: old?.payments ?? const <String, String>{},
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(subscriptionActionsProvider).save(
          s,
          amount: Money.fromDouble(amount, currency),
          frequency: _frequency,
          nextCharge: date,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final SubscriptionItem? e = widget.existing;
    if (e == null) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.subDeleteTitle),
        content: Text(l.subDeleteBody),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await ref.read(subscriptionActionsProvider).delete(e.sub);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final Locale locale = Localizations.localeOf(context);
    final String base = ref.watch(baseCurrencyProvider);
    final Currency cur = Currencies.byCode(_currency ?? base);
    final String? country = _country(base);

    final List<CatalogService> services = _catalogId != null &&
            ServiceCatalog.byId(_catalogId)?.name == _name.text.trim()
        ? const <CatalogService>[]
        : ServiceCatalog.search(country, _name.text).take(8).toList();
    final List<String> cards = CardSuggestions.matching(country, _card.text)
        .where((String n) => n != _card.text.trim())
        .take(6)
        .toList();

    final DateTime? date = _date;
    final RecurringRule? preview = date == null
        ? null
        : SubscriptionSchedule.ruleFor(
            id: 'preview',
            provider: '',
            amount: Money(0, cur.code),
            frequency: _frequency,
            nextCharge: date,
            createdAt: AppClock.now(),
          );
    final List<DateTime> upcoming = preview == null
        ? const <DateTime>[]
        : SubscriptionSchedule.upcoming(preview, AppClock.now());
    final List<DateTime> reminders = preview == null
        ? const <DateTime>[]
        : SubscriptionSchedule.reminderDays(
            Subscription(
              id: 'preview',
              ruleId: 'preview',
              kind: SubscriptionKind.digital,
              provider: '',
              trialEndsAt: _trial ? date : null,
              status: _trial
                  ? SubscriptionStatus.trial
                  : SubscriptionStatus.active,
              remindersOn: _remindersOn,
              reminderDays: _days,
              createdAt: AppClock.now(),
              updatedAt: AppClock.now(),
            ),
            preview,
            AppClock.now());
    final String comma =
        const <String>{'ar', 'fa', 'ur'}.contains(locale.languageCode)
            ? '، '
            : ', ';
    String days(List<DateTime> ds) =>
        ds.map((DateTime d) => dayText(locale, d)).join(comma);

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: t.labelMedium?.copyWith(color: c.textMuted)),
        );

    final InputDecoration fieldLook = InputDecoration(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(DsSpacing.xl),
        // The switch rows paint their ink on a Material, not on this box.
        child: Material(
          type: MaterialType.transparency,
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
                          widget.existing == null ? l.subAdd : l.subEditTitle,
                          style: t.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip:
                            MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  // The service: picked from the list or typed.
                  DsTextField(
                    label: l.subService,
                    hintText: l.subServiceHint,
                    controller: _name,
                    prefixIcon: Icons.subscriptions_outlined,
                    validator: (String? v) =>
                        (v ?? '').trim().isEmpty ? l.valRequired : null,
                  ),
                  if (services.isNotEmpty) ...<Widget>[
                    const SizedBox(height: DsSpacing.sm),
                    Wrap(
                      spacing: DsSpacing.xs,
                      runSpacing: DsSpacing.xs,
                      children: <Widget>[
                        for (final CatalogService s in services)
                          ActionChip(
                            label: Text(s.name),
                            onPressed: () => _pickService(s),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  // What it costs: the user's own figure (no prices built in).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: DsTextField(
                          label: l.fieldAmount,
                          suffixText: cur.code,
                          controller: _amount,
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (String? v) {
                            final double n = AmountInput.parse(v ?? '') ?? 0;
                            return n > 0 ? null : l.valAmountInvalid;
                          },
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            label(l.currency),
                            DropdownButtonFormField<String>(
                              key: ValueKey<String>(cur.code),
                              initialValue: cur.code,
                              isExpanded: true,
                              decoration: fieldLook,
                              items: <DropdownMenuItem<String>>[
                                for (final Currency o in Currencies.all)
                                  DropdownMenuItem<String>(
                                    value: o.code,
                                    child: Row(
                                      children: <Widget>[
                                        CurrencyFlag(o, width: 18),
                                        const SizedBox(width: 6),
                                        Text(o.code),
                                      ],
                                    ),
                                  ),
                              ],
                              // Any currency: a service abroad charges in its
                              // own, and the reminder must say the real
                              // amount. Nothing is recorded without asking.
                              onChanged: (String? v) =>
                                  setState(() => _currency = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  label(l.subCycle),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    initialValue: _frequency,
                    isExpanded: true,
                    decoration: fieldLook,
                    items: <DropdownMenuItem<RecurrenceFrequency>>[
                      for (final RecurrenceFrequency f
                          in RecurrenceFrequency.values)
                        DropdownMenuItem<RecurrenceFrequency>(
                          value: f,
                          child: Text(repeatLabel(l, f)),
                        ),
                    ],
                    onChanged: (RecurrenceFrequency? f) {
                      if (f != null) _setFrequency(f);
                    },
                  ),
                  const SizedBox(height: DsSpacing.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.subTrial),
                    subtitle: Text(l.subTrialHelp,
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                    value: _trial,
                    onChanged: (bool v) => setState(() => _trial = v),
                  ),
                  if (_trial) ...<Widget>[
                    Wrap(
                      spacing: DsSpacing.xs,
                      children: <Widget>[
                        for (final int n in <int>[7, 14])
                          ActionChip(
                            label: Text(l.subInDays(n)),
                            onPressed: () => setState(() => _date =
                                DateTime(_today.year, _today.month,
                                    _today.day + n)),
                          ),
                        ActionChip(
                          label: Text(l.subOneMonth),
                          onPressed: () => setState(() => _date = DateTime(
                              _today.year, _today.month + 1, _today.day)),
                        ),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.sm),
                  ],
                  // The date that matters most: when the money leaves.
                  label(_trial ? l.subTrialEnds : l.subNextCharge),
                  FormField<DateTime>(
                    key: ValueKey<Object?>(date),
                    initialValue: date,
                    validator: (_) {
                      if (date == null) return l.valRequired;
                      return SubscriptionSchedule.validNextCharge(
                              date, AppClock.now())
                          ? null
                          : l.subDateFromToday;
                    },
                    builder: (FormFieldState<DateTime> f) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: DsRadius.brMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: DsRadius.brMd,
                              border: Border.all(
                                  color: f.hasError ? c.expense : c.border),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.event_outlined,
                                    size: 18, color: c.textMuted),
                                const SizedBox(width: DsSpacing.md),
                                Expanded(
                                  child: Text(
                                    date == null ? '—' : dayText(locale, date),
                                    style: t.bodyMedium
                                        ?.copyWith(color: c.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.errorText ?? l.subNextChargeHelp,
                          style: t.bodySmall?.copyWith(
                              color: f.hasError ? c.expense : c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.subAutoRenew),
                    value: _autoRenew,
                    onChanged: (bool v) => setState(() => _autoRenew = v),
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  // The card: a name only, suggested for the user's country.
                  DsTextField(
                    label: '${l.subCardName} (${l.optional})',
                    hintText: l.subCardNameHelp,
                    controller: _card,
                    prefixIcon: Icons.credit_card_rounded,
                    validator: (String? v) => (v ?? '').trim().isEmpty ||
                            CardName.isSafe(v!.trim())
                        ? null
                        : l.subCardNumberRefused,
                  ),
                  if (cards.isNotEmpty) ...<Widget>[
                    const SizedBox(height: DsSpacing.sm),
                    Wrap(
                      spacing: DsSpacing.xs,
                      runSpacing: DsSpacing.xs,
                      children: <Widget>[
                        for (final String n in cards)
                          ActionChip(
                            label: Text(n),
                            onPressed: () => setState(() => _card.text = n),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DsSpacing.lg),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.subReminders),
                    value: _remindersOn,
                    onChanged: (bool v) => setState(() => _remindersOn = v),
                  ),
                  if (_remindersOn && !_trial)
                    Wrap(
                      spacing: DsSpacing.xs,
                      runSpacing: DsSpacing.xs,
                      children: <Widget>[
                        for (final int n
                            in SubscriptionReminders.choicesFor(_frequency))
                          FilterChip(
                            label: Text(
                                n == 0 ? l.subRemindOnDay : l.subRemindBefore(n)),
                            selected: _days.contains(n),
                            onSelected: (bool on) => setState(() {
                              final List<int> next = <int>[
                                ..._days.where((int d) => d != n),
                                if (on) n,
                              ]..sort((int a, int b) => b.compareTo(a));
                              // At least one reminder while they are on.
                              if (next.isNotEmpty) _days = next;
                            }),
                          ),
                      ],
                    ),
                  if (upcoming.isNotEmpty) ...<Widget>[
                    const SizedBox(height: DsSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(DsSpacing.md),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: DsRadius.brMd,
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.subUpcoming(days(upcoming)),
                              style: t.bodySmall),
                          if (reminders.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(l.subRemindersOn(days(reminders)),
                                style: t.bodySmall
                                    ?.copyWith(color: c.textMuted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DsSpacing.xl),
                  DsButton(
                      label: l.save,
                      expand: true,
                      onPressed: _saving ? null : _save),
                  if (widget.existing != null) ...<Widget>[
                    const SizedBox(height: DsSpacing.sm),
                    DsButton(
                      label: l.delete,
                      icon: Icons.delete_outline_rounded,
                      variant: DsButtonVariant.ghost,
                      expand: true,
                      onPressed: _saving ? null : _delete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
