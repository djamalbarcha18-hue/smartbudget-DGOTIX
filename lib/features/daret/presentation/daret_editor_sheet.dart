import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class DaretEditorSheet extends ConsumerStatefulWidget {
  const DaretEditorSheet({super.key, this.existing});
  final Daret? existing;

  static Future<void> show(BuildContext context, {Daret? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DaretEditorSheet(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<DaretEditorSheet> createState() => _DaretEditorSheetState();
}

class _DaretEditorSheetState extends ConsumerState<DaretEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.existing == null ? '' : _plain(widget.existing!.contribution));
  final TextEditingController _member = TextEditingController();
  late DaretFrequency _freq =
      widget.existing?.frequency ?? DaretFrequency.monthly;
  late DateTime _start = widget.existing?.start ?? _today;
  late final List<String> _members =
      List<String>.of(widget.existing?.members ?? const <String>[]);
  late int _me = widget.existing?.meIndex ?? 0;
  String? _error;
  bool _seededMe = false;

  static DateTime get _today {
    final DateTime n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _plain(Money m) {
    final double v = m.asDouble;
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seededMe && _members.isEmpty) {
      _members.add(AppLocalizations.of(context).daretMe);
      _me = 0;
    }
    _seededMe = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _member.dispose();
    super.dispose();
  }

  void _addMember() {
    final String n = _member.text.trim();
    if (n.isEmpty) return;
    setState(() {
      _members.add(n);
      _member.clear();
      _error = null;
    });
  }

  void _move(int i, int delta) {
    final int j = i + delta;
    if (j < 0 || j >= _members.length) return;
    setState(() {
      final String a = _members[i];
      _members[i] = _members[j];
      _members[j] = a;
      if (_me == i) {
        _me = j;
      } else if (_me == j) {
        _me = i;
      }
    });
  }

  void _remove(int i) {
    setState(() {
      _members.removeAt(i);
      if (_me == i) {
        _me = 0;
      } else if (_me > i) {
        _me--;
      }
    });
  }

  /// "Qur'a": draw the turn order at random, keeping track of the user.
  void _shuffle() {
    final String me = _members[_me];
    setState(() {
      _members.shuffle(Random.secure());
      _me = _members.indexOf(me);
    });
  }

  Future<void> _save(AppLocalizations l) async {
    final double? amount = parseAmount(_amount.text);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l.valRequired);
      return;
    }
    if (amount == null) {
      setState(() => _error = l.valAmountInvalid);
      return;
    }
    if (_members.length < 2) {
      setState(() => _error = l.daretNeedMembers);
      return;
    }
    final String currency = ref.read(baseCurrencyProvider);
    final Daret? e = widget.existing;
    final Daret d = Daret(
      id: e?.id ?? DaretActions.newId(),
      name: _name.text.trim(),
      contribution: Money.fromDouble(amount, currency),
      frequency: _freq,
      start: _start,
      members: List<String>.of(_members),
      meIndex: _me.clamp(0, _members.length - 1),
      paidRounds: (e?.paidRounds ?? const <int>{})
          .where((int r) => r < _members.length)
          .toSet(),
      payoutReceived: e?.payoutReceived ?? false,
      createdAt: e?.createdAt ?? AppClock.now(),
    );
    await ref.read(daretActionsProvider).save(d);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = ref.watch(baseCurrencyProvider);

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
                  Icon(Icons.groups_2_outlined, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(
                        widget.existing == null ? l.daretNew : l.daretEdit,
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
              TextField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: l.daretName, hintText: l.daretNameHint),
              ),
              const SizedBox(height: DsSpacing.md),
              TextField(
                controller: _amount,
                inputFormatters: LatinDigitsFormatter.only,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: '${l.daretContribution} ($currency)'),
              ),
              const SizedBox(height: DsSpacing.md),
              Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(l.daretMonthly),
                    selected: _freq == DaretFrequency.monthly,
                    onSelected: (_) =>
                        setState(() => _freq = DaretFrequency.monthly),
                  ),
                  ChoiceChip(
                    label: Text(l.daretWeekly),
                    selected: _freq == DaretFrequency.weekly,
                    onSelected: (_) =>
                        setState(() => _freq = DaretFrequency.weekly),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                        '${l.daretStart}: \u2066${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}\u2069'),
                    onPressed: () async {
                      final DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: _today.subtract(const Duration(days: 730)),
                        lastDate: _today.add(const Duration(days: 730)),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(l.daretMembersTitle,
                        style: t.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (_members.length > 1)
                    TextButton.icon(
                      icon: const Icon(Icons.casino_outlined, size: 18),
                      label: Text(l.daretShuffle),
                      onPressed: _shuffle,
                    ),
                ],
              ),
              Text(l.daretMembersHint,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.sm),
              for (int i = 0; i < _members.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: DsSpacing.xs),
                  padding: const EdgeInsetsDirectional.only(
                      start: DsSpacing.sm, end: DsSpacing.xs),
                  decoration: BoxDecoration(
                    color: i == _me
                        ? c.brand.withValues(alpha: 0.10)
                        : c.surfaceMuted,
                    borderRadius: DsRadius.brMd,
                    border: Border.all(
                        color: i == _me
                            ? c.brand.withValues(alpha: 0.4)
                            : c.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: c.brand.withValues(alpha: 0.15),
                        child: Text('${i + 1}',
                            style: t.labelSmall?.copyWith(color: c.brand)),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(child: Text(_members[i], style: t.bodyMedium)),
                      IconButton(
                        tooltip: l.daretThisIsMe,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                            i == _me
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            size: 20,
                            color: i == _me ? c.brand : c.textFaint),
                        onPressed: () => setState(() => _me = i),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        onPressed: i == 0 ? null : () => _move(i, -1),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon:
                            const Icon(Icons.arrow_downward_rounded, size: 18),
                        onPressed: i == _members.length - 1
                            ? null
                            : () => _move(i, 1),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: c.textMuted),
                        onPressed: _members.length <= 1 ? null : () => _remove(i),
                      ),
                    ],
                  ),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _member,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addMember(),
                      decoration:
                          InputDecoration(hintText: l.daretAddMemberHint),
                    ),
                  ),
                  IconButton(
                    tooltip: l.daretAddMember,
                    icon: Icon(Icons.person_add_alt_1_rounded, color: c.brand),
                    onPressed: _addMember,
                  ),
                ],
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
