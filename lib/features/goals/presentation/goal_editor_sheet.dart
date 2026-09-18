import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class GoalEditorSheet extends ConsumerStatefulWidget {
  const GoalEditorSheet({super.key, this.existing});
  final Goal? existing;

  static Future<void> show(BuildContext context, {Goal? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => GoalEditorSheet(existing: existing),
    );
  }

  @override
  ConsumerState<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<GoalEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Goal? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(
        text: e == null ? '' : e.target.asDouble.toString());
    _deadline = e?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final String currency = ref.read(baseCurrencyProvider);
    final double target =
        double.tryParse(_target.text.trim().replaceAll(',', '.')) ?? 0;
    final Goal? e = widget.existing;
    final Goal goal = Goal(
      id: e?.id ?? GoalActions.newId(),
      name: _name.text.trim(),
      target: Money.fromDouble(target, currency),
      // Saved is derived (contributions); preserve on edit, start at 0 on create.
      saved: e?.saved ?? Money.zero(currency),
      deadline: _deadline,
      createdAt: e?.createdAt ?? DateTime.now(),
    );
    final GoalActions actions = ref.read(goalActionsProvider);
    if (e == null) {
      await actions.add(goal);
    } else {
      await actions.update(goal);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final Currency cur = Currencies.byCode(ref.watch(baseCurrencyProvider));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                      Expanded(
                        child: Text(
                          widget.existing == null ? l.addGoal : l.editGoal,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: l.fieldGoalName,
                    controller: _name,
                    prefixIcon: Icons.flag_outlined,
                    validator: (String? v) =>
                        (v ?? '').trim().isEmpty ? l.valRequired : null,
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldTarget} (${cur.symbol})',
                    controller: _target,
                    prefixIcon: Icons.tag_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) {
                      final double n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.')) ??
                          0;
                      return n > 0 ? null : l.valAmountInvalid;
                    },
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _DeadlineField(
                    date: _deadline,
                    onPick: () async {
                      final DateTime? p = await showDatePicker(
                        context: context,
                        initialDate: _deadline ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                      );
                      if (p != null) setState(() => _deadline = p);
                    },
                    onClear: () => setState(() => _deadline = null),
                  ),
                  const SizedBox(height: DsSpacing.xl),
                  DsButton(
                      label: l.save,
                      expand: true,
                      onPressed: _saving ? null : _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.date,
    required this.onPick,
    required this.onClear,
  });
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${l.fieldDeadline} (${l.optional})',
            style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
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
                Icon(Icons.event_outlined, size: 18, color: c.textMuted),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Text(
                    date == null ? '—' : DateFormat('yyyy-MM-dd').format(date!),
                    style: t.bodyMedium?.copyWith(color: c.textPrimary),
                  ),
                ),
                if (date != null)
                  InkWell(
                    onTap: onClear,
                    child:
                        Icon(Icons.clear_rounded, size: 16, color: c.textFaint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
