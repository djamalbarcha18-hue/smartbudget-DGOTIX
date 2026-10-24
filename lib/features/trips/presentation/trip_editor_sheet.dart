import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/currency_suffix.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/offers/domain/partner_offer.dart';
import 'package:smartbudget/features/offers/presentation/partner_offer_card.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/destination_picker.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Create or edit a trip: where, when, and an optional budget.
class TripEditorSheet extends ConsumerStatefulWidget {
  const TripEditorSheet({super.key, this.existing});

  final Trip? existing;

  static Future<void> show(BuildContext context, {Trip? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TripEditorSheet(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<TripEditorSheet> createState() => _TripEditorSheetState();
}

class _TripEditorSheetState extends ConsumerState<TripEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _budget = TextEditingController(
      text: widget.existing?.plannedBudget == null
          ? ''
          : _plain(widget.existing!.plannedBudget!));
  late String? _destination = widget.existing?.destination;
  late DateTime _start = widget.existing?.start ?? _today;

  /// How many days (the last day follows from the first).
  late int _days =
      widget.existing == null ? 7 : TripDays.total(widget.existing!);
  late TripLevel? _level = widget.existing?.level;

  /// Independent or organized; a new trip to Mecca or Medina starts as
  /// organized (usually with an agency) until the user picks.
  late TripKind _kind = widget.existing?.kind ?? TripKind.independent;
  bool _kindTouched = false;
  late final TextEditingController _agency =
      TextEditingController(text: widget.existing?.agency ?? '');
  late final TextEditingController _airline =
      TextEditingController(text: widget.existing?.airline ?? '');
  late final TextEditingController _hotel =
      TextEditingController(text: widget.existing?.hotel ?? '');
  DateTime get _end => _start.add(Duration(days: _days - 1));

  /// The slider goes to 30 days, further for a longer trip being edited.
  late final int _maxDays = _days > 30 ? _days : 30;
  late int _travelers = widget.existing?.travelers ?? 1;
  bool _needPlace = false;

  /// The user's own split; null follows the suggestion, which then keeps
  /// up with the level and the number of days.
  late Map<TripItem, int>? _split = widget.existing?.split;
  Map<TripItem, int> get _effectiveSplit =>
      _split ?? TripItems.suggested(_level, _days, _kind);

  void _setKind(TripKind k) {
    if (k == _kind) return;
    _kind = k;
    _split = null; // other items: back to the suggested split
  }

  static String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  static DateTime get _today {
    final DateTime n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _plain(Money m) {
    final double v = m.asDouble;
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _agency.dispose();
    _airline.dispose();
    _hotel.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: _today.subtract(const Duration(days: 365 * 5)),
      lastDate: _today.add(const Duration(days: 365 * 3)),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _save(AppLocalizations l, DestinationCatalog catalog) async {
    final String? place = _destination;
    if (place == null || place.trim().isEmpty) {
      setState(() => _needPlace = true);
      return;
    }
    final Money? old = widget.existing?.plannedBudget;
    final String currency = old?.currencyCode ?? ref.read(baseCurrencyProvider);
    final double? budget = parseAmount(_budget.text);
    final String name = _name.text.trim().isNotEmpty
        ? _name.text.trim()
        : l.tripDefaultName(catalog.display(place, appLangOf(context)));
    await ref.read(tripActionsProvider).save(Trip(
          id: widget.existing?.id ?? TripActions.newId(),
          name: name,
          destination: place,
          start: _start,
          end: _end,
          plannedBudget:
              budget == null ? null : Money.fromDouble(budget, currency),
          createdAt: widget.existing?.createdAt ?? AppClock.now(),
          goalId: widget.existing?.goalId,
          travelers: _travelers,
          sharedAt: widget.existing?.sharedAt,
          level: _level,
          split: _split,
          kind: _kind,
          agency: _kind == TripKind.organized ? _text(_agency) : null,
          airline: _text(_airline),
          hotel: _text(_hotel),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang = appLangOf(context);
    final String locale = Localizations.localeOf(context).toString();
    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final List<Trip> trips =
        ref.watch(tripsProvider).valueOrNull ?? const <Trip>[];
    final String currency = widget.existing?.plannedBudget?.currencyCode ??
        ref.watch(baseCurrencyProvider);
    final DateFormat day = DateFormat.yMMMd(locale);
    final String? place = _destination;

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
                  Icon(SbIcons.tripTakeoff, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(
                        widget.existing != null ? l.tripEdit : l.tripNew,
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
              DestinationPicker(
                value: place,
                catalog: catalog,
                past: TripMath.pastDestinations(
                    trips
                        .where((Trip x) => x.id != widget.existing?.id)
                        .toList(),
                    catalog: catalog),
                errorText: _needPlace ? l.tripNeedPlace : null,
                onChanged: (String? v) => setState(() {
                  _destination = v;
                  // Umrah and Hajj usually go with an agency.
                  if (!_kindTouched && widget.existing == null) {
                    _setKind(<String>{'mecca', 'medina'}
                            .contains(catalog.byText(v ?? '')?.id)
                        ? TripKind.organized
                        : TripKind.independent);
                  }
                  if (v != null) _needPlace = false;
                }),
              ),
              const SizedBox(height: DsSpacing.lg),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '${l.tripName} (${l.optional})',
                  hintText: place == null
                      ? null
                      : l.tripDefaultName(catalog.display(place, lang)),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text('${l.tripFrom} ${day.format(_start)}'),
                onPressed: _pickStart,
              ),
              const SizedBox(height: DsSpacing.md),
              // The number of days (the last day follows), and travellers.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      // Stretch: the slider takes the whole half.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(l.tripDaysLabel(_days),
                            style: t.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Slider(
                          value: _days.toDouble(),
                          min: 1,
                          max: _maxDays.toDouble(),
                          divisions: _maxDays - 1,
                          label: '$_days',
                          activeColor: c.brand,
                          inactiveColor: c.border,
                          onChanged: (double v) =>
                              setState(() => _days = v.round()),
                        ),
                        Text('${l.tripTo} ${day.format(_end)}',
                            style: t.bodySmall?.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Column(
                    children: <Widget>[
                      Text(l.tripTravelers,
                          style: t.bodyMedium?.copyWith(color: c.textMuted)),
                      const SizedBox(height: DsSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton.outlined(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: _travelers > 1
                                ? () => setState(() => _travelers--)
                                : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text('$_travelers',
                                textAlign: TextAlign.center,
                                style: t.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          IconButton.outlined(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: _travelers < 99
                                ? () => setState(() => _travelers++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Text(l.tripKind,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.xs),
              SegmentedButton<TripKind>(
                showSelectedIcon: false,
                segments: <ButtonSegment<TripKind>>[
                  for (final TripKind k in TripKind.values)
                    ButtonSegment<TripKind>(
                      value: k,
                      icon: Icon(
                          k == TripKind.organized
                              ? SbIcons.tripPackage
                              : SbIcons.tripTakeoff,
                          size: 18),
                      label: Text(tripKindLabel(l, k)),
                    ),
                ],
                selected: <TripKind>{_kind},
                onSelectionChanged: (Set<TripKind> v) => setState(() {
                  _kindTouched = true;
                  _setKind(v.first);
                }),
              ),
              // Who with: typed for now; partners can be offered here later.
              if (_kind == TripKind.organized) ...<Widget>[
                const SizedBox(height: DsSpacing.xs),
                Text(l.tripKindOrganizedHint,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                const SizedBox(height: DsSpacing.xs),
                TextField(
                  controller: _agency,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: '${l.tripAgency} (${l.optional})',
                    prefixIcon: const Icon(SbIcons.tripPackage, size: 18),
                  ),
                ),
              ],
              TextField(
                controller: _airline,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: '${l.tripAirline} (${l.optional})',
                  prefixIcon: const Icon(SbIcons.tripFlights, size: 18),
                ),
              ),
              TextField(
                controller: _hotel,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: '${l.tripHotel} (${l.optional})',
                  prefixIcon: const Icon(SbIcons.tripStay, size: 18),
                ),
              ),
              // Under who the trip is with: one partner suggestion at most.
              if (place != null)
                PartnerOfferSlot(
                  slot: OfferSlot.tripEditor,
                  trip: Trip(
                    id: widget.existing?.id ?? 'draft',
                    name: '',
                    destination: place,
                    start: _start,
                    end: _end,
                    createdAt: AppClock.now(),
                    kind: _kind,
                  ),
                ),
              const SizedBox(height: DsSpacing.md),
              Text('${l.tripLevel} (${l.optional})',
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.xs),
              SegmentedButton<TripLevel>(
                showSelectedIcon: false,
                emptySelectionAllowed: true,
                segments: <ButtonSegment<TripLevel>>[
                  for (final TripLevel v in TripLevel.values)
                    ButtonSegment<TripLevel>(
                        value: v, label: Text(tripLevelLabel(l, v))),
                ],
                selected: <TripLevel>{if (_level != null) _level!},
                onSelectionChanged: (Set<TripLevel> v) =>
                    setState(() => _level = v.isEmpty ? null : v.first),
              ),
              const SizedBox(height: DsSpacing.md),
              TextField(
                controller: _budget,
                inputFormatters: LatinDigitsFormatter.only,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l.tripBudget} (${l.optional})',
                  suffixIcon: CurrencySuffix(currency),
                ),
              ),
              _BudgetAdvice(budget: _budget, currency: currency, start: _start),
              _SplitEditor(
                budget: _budget,
                currency: currency,
                split: _effectiveSplit,
                custom: _split != null,
                onChanged: (Map<TripItem, int> s) =>
                    setState(() => _split = s),
                onReset: () => setState(() => _split = null),
              ),
              const SizedBox(height: DsSpacing.lg),
              DsButton(
                label: l.save,
                icon: Icons.check_rounded,
                expand: true,
                onPressed: () => _save(l, catalog),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the budget: the usual monthly surplus, what it could put aside by
/// the trip, whether the typed budget fits, and "Suggest a budget". Only a
/// hint, worked out on the device; nothing when there is no history yet.
class _BudgetAdvice extends ConsumerWidget {
  const _BudgetAdvice(
      {required this.budget, required this.currency, required this.start});
  final TextEditingController budget;
  final String currency;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final TripBudgetAdvice? advice =
        TripBudgetAdvice.of(txns, currency, AppClock.now(), start);
    if (advice == null) return const SizedBox.shrink();
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final TextStyle line = (t.bodySmall ?? const TextStyle());

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: budget,
      builder: (BuildContext context, TextEditingValue v, _) {
        final double? typed = parseAmount(v.text);
        final Money? planned =
            typed == null ? null : Money.fromDouble(typed, currency);
        final bool? fits = planned == null ? null : advice.fits(planned);
        final Money? need =
            planned == null ? null : advice.neededPerMonth(planned);
        final Money? suggestion = advice.suggestedBudget;
        return Container(
          margin: const EdgeInsetsDirectional.only(top: DsSpacing.sm),
          padding: const EdgeInsetsDirectional.fromSTEB(
              DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.xs),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: c.brand),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(
                      advice.hasSurplus
                          ? l.tripAvgSurplus(
                              MoneyFormatter.format(advice.monthlySurplus))
                          : l.tripNoSurplus,
                      style: line,
                    ),
                  ),
                ],
              ),
              if (advice.canSave != null) ...<Widget>[
                const SizedBox(height: DsSpacing.xs),
                Text(l.tripCanSave(MoneyFormatter.format(advice.canSave!)),
                    style: line.copyWith(color: c.textMuted)),
              ],
              if (fits != null &&
                  need != null &&
                  advice.hasSurplus) ...<Widget>[
                const SizedBox(height: DsSpacing.xs),
                Text(
                  fits
                      ? l.tripWithinSurplus(MoneyFormatter.format(need))
                      : l.tripNeedMore(MoneyFormatter.format(need)),
                  style: line.copyWith(
                      color: fits ? c.income : c.warning,
                      fontWeight: FontWeight.w600),
                ),
              ],
              if (suggestion != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                    label: Text(l.tripSuggestBudget),
                    onPressed: () =>
                        budget.text = suggestion.asDouble.toStringAsFixed(0),
                  ),
                )
              else
                const SizedBox(height: DsSpacing.xs),
            ],
          ),
        );
      },
    );
  }
}

/// Under the budget, once there is one: how it splits between the trip's
/// items — a bar and the shares at a glance, then one slider per item on
/// "Adjust" (moving one shares the rest out in proportion).
class _SplitEditor extends StatefulWidget {
  const _SplitEditor({
    required this.budget,
    required this.currency,
    required this.split,
    required this.custom,
    required this.onChanged,
    required this.onReset,
  });
  final TextEditingController budget;
  final String currency;
  final Map<TripItem, int> split;

  /// Set by the user (else the suggested split).
  final bool custom;
  final ValueChanged<Map<TripItem, int>> onChanged;
  final VoidCallback onReset;

  @override
  State<_SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<_SplitEditor> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.budget,
      builder: (BuildContext context, TextEditingValue v, _) {
        final double? typed = parseAmount(v.text);
        if (typed == null || typed <= 0) return const SizedBox.shrink();
        final Money budget = Money.fromDouble(typed, widget.currency);
        final List<TripItem> items = widget.split.keys.toList();
        final List<int> parts = TripItems.shares(budget.minorUnits, <double>[
          for (final TripItem i in items) (widget.split[i] ?? 0).toDouble(),
        ]);
        String amount(TripItem i) => MoneyFormatter.format(
            Money(parts[items.indexOf(i)], widget.currency));

        return Container(
          margin: const EdgeInsetsDirectional.only(top: DsSpacing.sm),
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 18, color: c.brand),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(l.tripSplitTitle,
                        style: t.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _open = !_open),
                    child: Text(_open ? l.tripSplitDone : l.tripSplitEdit),
                  ),
                ],
              ),
              Text(l.tripSplitHint,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.sm),
              // The split at a glance, in the items' colours.
              SizedBox(
                height: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final TripItem i in items)
                      if ((widget.split[i] ?? 0) > 0)
                        Expanded(
                          flex: widget.split[i]!,
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 2),
                            decoration: BoxDecoration(
                              color: tripItemColor(i),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              if (!_open)
                Wrap(
                  spacing: DsSpacing.md,
                  runSpacing: DsSpacing.xs,
                  children: <Widget>[
                    for (final TripItem i in items)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(tripItemIcon(i),
                              size: 14, color: tripItemColor(i)),
                          const SizedBox(width: 4),
                          Text(
                              '${tripItemLabel(l, i)} ${widget.split[i] ?? 0}%',
                              style: t.bodySmall),
                        ],
                      ),
                  ],
                )
              else ...<Widget>[
                for (final TripItem i in items)
                  Padding(
                    padding: const EdgeInsets.only(top: DsSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(tripItemIcon(i),
                                size: 18, color: tripItemColor(i)),
                            const SizedBox(width: DsSpacing.xs),
                            Expanded(
                                child: Text(tripItemLabel(l, i),
                                    style: t.bodyMedium)),
                            Text(amount(i),
                                style: t.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            SizedBox(
                              width: 48,
                              child: Text('${widget.split[i] ?? 0}%',
                                  textAlign: TextAlign.end,
                                  style: t.bodySmall
                                      ?.copyWith(color: c.textMuted)),
                            ),
                          ],
                        ),
                        Slider(
                          value: (widget.split[i] ?? 0).toDouble(),
                          max: 100,
                          divisions: 100,
                          activeColor: tripItemColor(i),
                          inactiveColor: c.border,
                          label: '${widget.split[i] ?? 0}%',
                          semanticFormatterCallback: (double v) =>
                              '${tripItemLabel(l, i)} ${v.round()}%',
                          onChanged: (double v) => widget.onChanged(
                              TripItems.withShare(
                                  widget.split, i, v.round())),
                        ),
                      ],
                    ),
                  ),
                if (widget.custom)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                      label: Text(l.tripSplitReset),
                      onPressed: widget.onReset,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
