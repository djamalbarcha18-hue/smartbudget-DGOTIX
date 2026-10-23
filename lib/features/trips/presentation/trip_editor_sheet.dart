import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/currency_suffix.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/presentation/destination_picker.dart';
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
  late DateTime _end =
      widget.existing?.end ?? _today.add(const Duration(days: 6));
  late int _travelers = widget.existing?.travelers ?? 1;
  bool _needPlace = false;

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
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: _today.subtract(const Duration(days: 365 * 5)),
      lastDate: _today.add(const Duration(days: 365 * 3)),
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _start = d;
        if (_end.isBefore(d)) _end = d;
      } else {
        _end = d.isBefore(_start) ? _start : d;
      }
    });
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
                  Icon(Icons.flight_takeoff_outlined, color: c.brand),
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text('${l.tripFrom} ${day.format(_start)}'),
                      onPressed: () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.event_available_outlined, size: 18),
                      label: Text('${l.tripTo} ${day.format(_end)}'),
                      onPressed: () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Row(
                children: <Widget>[
                  Icon(Icons.group_outlined, size: 18, color: c.textMuted),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.tripTravelers,
                        style: t.bodyMedium?.copyWith(color: c.textMuted)),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    onPressed: _travelers > 1
                        ? () => setState(() => _travelers--)
                        : null,
                  ),
                  SizedBox(
                    width: 36,
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
