import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/currency_suffix.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/seasons/presentation/season_text.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Create or edit a season plan. A new plan targets the next occurrence of the
/// chosen season; its budget can start from last season's actual spending.
class SeasonEditorSheet extends ConsumerStatefulWidget {
  const SeasonEditorSheet({super.key, this.existing, this.kind, this.window});

  final SeasonPlan? existing;
  final SeasonKind? kind;

  /// A specific occurrence to plan (e.g. "the one after this").
  final SeasonWindow? window;

  static Future<void> show(BuildContext context,
      {SeasonPlan? existing, SeasonKind? kind, SeasonWindow? window}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SeasonEditorSheet(existing: existing, kind: kind, window: window),
      ),
    );
  }

  @override
  ConsumerState<SeasonEditorSheet> createState() => _SeasonEditorSheetState();
}

class _SeasonEditorSheetState extends ConsumerState<SeasonEditorSheet> {
  late SeasonKind _kind =
      widget.existing?.kind ?? widget.kind ?? SeasonKind.ramadan;
  late final TextEditingController _budget = TextEditingController(
      text: widget.existing == null ? '' : _plain(widget.existing!.budget));
  late final TextEditingController _saved = TextEditingController(
      text: widget.existing == null || widget.existing!.saved.minorUnits == 0
          ? ''
          : _plain(widget.existing!.saved));
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late DateTime _customStart = widget.existing?.start ??
      _today.add(const Duration(days: 30));
  late DateTime _customEnd =
      widget.existing?.end ?? _customStart.add(const Duration(days: 6));
  String? _error;

  static DateTime get _today {
    final DateTime n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _plain(Money m) {
    final double v = m.asDouble;
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  bool get _editing => widget.existing != null;

  SeasonWindow get _window {
    if (_editing) {
      return (start: widget.existing!.start, end: widget.existing!.end);
    }
    if (_kind == SeasonKind.custom) {
      return (start: _customStart, end: _customEnd);
    }
    return widget.window != null && widget.kind == _kind
        ? widget.window!
        : SeasonCalendar.next(_kind, _today);
  }

  @override
  void dispose() {
    _budget.dispose();
    _saved.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: start ? _customStart : _customEnd,
      firstDate: _today.subtract(const Duration(days: 365)),
      lastDate: _today.add(const Duration(days: 365 * 3)),
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _customStart = d;
        if (_customEnd.isBefore(d)) _customEnd = d;
      } else {
        _customEnd = d.isBefore(_customStart) ? _customStart : d;
      }
    });
  }

  Future<void> _save(AppLocalizations l) async {
    final double? budget = parseAmount(_budget.text);
    if (budget == null) {
      setState(() => _error = l.valAmountInvalid);
      return;
    }
    if (_kind == SeasonKind.custom && _name.text.trim().isEmpty) {
      setState(() => _error = l.valRequired);
      return;
    }
    final String currency = ref.read(baseCurrencyProvider);
    final double saved = parseAmount(_saved.text) ?? 0;
    final SeasonWindow w = _window;
    final SeasonPlan p = SeasonPlan(
      id: widget.existing?.id ?? SeasonActions.newId(),
      kind: _kind,
      name: _kind == SeasonKind.custom ? _name.text.trim() : '',
      start: w.start,
      end: w.end,
      budget: Money.fromDouble(budget, currency),
      saved: Money.fromDouble(saved, currency),
      createdAt: widget.existing?.createdAt ?? AppClock.now(),
    );
    await ref.read(seasonActionsProvider).save(p);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = ref.watch(baseCurrencyProvider);
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final SeasonWindow w = _window;

    // Smart start: what the same season cost last time.
    final Money? lastTime = _kind == SeasonKind.custom
        ? null
        : SeasonMath.spentIn(
            SeasonCalendar.previous(_kind, w.start), txns, currency);

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
                  Icon(Icons.celebration_outlined, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(_editing ? l.seasonEdit : l.seasonPlanNew,
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
              if (!_editing) ...<Widget>[
                Wrap(
                  spacing: DsSpacing.sm,
                  runSpacing: DsSpacing.sm,
                  children: <Widget>[
                    for (final SeasonKind k in SeasonKind.values)
                      ChoiceChip(
                        avatar: Icon(seasonIcon(k),
                            size: 16, color: seasonColor(k)),
                        label: Text(seasonName(l, k, '')),
                        selected: _kind == k,
                        onSelected: (_) => setState(() {
                          _kind = k;
                          _error = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: DsSpacing.lg),
              ],
              if (_kind == SeasonKind.custom) ...<Widget>[
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l.seasonName,
                    hintText: l.seasonNameHint,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text('${l.seasonFrom} ${_ymd(_customStart)}'),
                        onPressed: _editing ? null : () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_available_outlined,
                            size: 18),
                        label: Text('${l.seasonTo} ${_ymd(_customEnd)}'),
                        onPressed:
                            _editing ? null : () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(DsSpacing.md),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: DsRadius.brMd,
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(seasonIcon(_kind), color: seasonColor(_kind)),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        child: Text(
                          '${seasonDateLabel(l, _kind, w)}\n${_ymd(w.start)} – ${_ymd(w.end)}',
                          style: t.bodySmall?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: DsSpacing.lg),
              TextField(
                controller: _budget,
                inputFormatters: LatinDigitsFormatter.only,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l.seasonBudget} ($currency)',
                ),
              ),
              if (lastTime != null && lastTime.minorUnits > 0) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionChip(
                    avatar: Icon(Icons.history_rounded,
                        size: 16, color: c.brand),
                    label: Text(l.seasonUseLast(MoneyFormatter.format(lastTime))),
                    onPressed: () =>
                        setState(() => _budget.text = _plain(lastTime)),
                  ),
                ),
              ],
              const SizedBox(height: DsSpacing.md),
              TextField(
                controller: _saved,
                inputFormatters: LatinDigitsFormatter.only,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l.seasonSavedSoFar} (${l.optional})',
                  suffixIcon: CurrencySuffix(currency),
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}

/// A date as yyyy-MM-dd, isolated left-to-right so Arabic text around it
/// can't reorder its parts.
String _ymd(DateTime d) =>
    '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069';

/// "Ramadan 1448 AH" for Hijri seasons, the Gregorian year otherwise.
String seasonDateLabel(AppLocalizations l, SeasonKind k, SeasonWindow w) =>
    SeasonCalendar.isHijri(k)
        ? l.seasonHijriYear(SeasonCalendar.hijriYear(w.start))
        : '${w.start.year}';
