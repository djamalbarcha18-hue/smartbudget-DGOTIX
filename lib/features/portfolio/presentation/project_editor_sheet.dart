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
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/portfolio/presentation/horizon_labels.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ProjectEditorSheet extends ConsumerStatefulWidget {
  const ProjectEditorSheet({super.key, this.existing, this.initialHorizon});
  final Project? existing;
  final ProjectHorizon? initialHorizon;

  static Future<void> show(
    BuildContext context, {
    Project? existing,
    ProjectHorizon? initialHorizon,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) =>
          ProjectEditorSheet(existing: existing, initialHorizon: initialHorizon),
    );
  }

  @override
  ConsumerState<ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends ConsumerState<ProjectEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _note;
  late ProjectHorizon _horizon;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Project? e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(
        text: e == null ? '' : e.target.asDouble.toString());
    _note = TextEditingController(text: e?.note ?? '');
    _horizon = e?.horizon ?? widget.initialHorizon ?? ProjectHorizon.mid;
    _targetDate = e?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final String currency = ref.read(baseCurrencyProvider);
    final double target =
        double.tryParse(_target.text.trim().replaceAll(',', '.')) ?? 0;
    final Project? e = widget.existing;
    final Project project = Project(
      id: e?.id ?? ProjectActions.newId(),
      name: _name.text.trim(),
      target: Money.fromDouble(target, currency),
      saved: e?.saved ?? Money.zero(currency),
      horizon: _horizon,
      targetDate: _targetDate,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: e?.createdAt ?? DateTime.now(),
    );
    final ProjectActions actions = ref.read(projectActionsProvider);
    if (e == null) {
      await actions.add(project);
    } else {
      await actions.update(project);
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
                          widget.existing == null
                              ? l.addProject
                              : l.editProject,
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
                    label: l.fieldProjectName,
                    controller: _name,
                    prefixIcon: Icons.rocket_launch_outlined,
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
                  Text(l.fieldHorizon,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: c.textMuted)),
                  const SizedBox(height: 6),
                  _HorizonPicker(
                    value: _horizon,
                    onChanged: (ProjectHorizon h) =>
                        setState(() => _horizon = h),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  _DateField(
                    date: _targetDate,
                    onPick: () async {
                      final DateTime? p = await showDatePicker(
                        context: context,
                        initialDate: _targetDate ??
                            DateTime.now()
                                .add(Duration(days: 30 * _horizon.defaultMonths)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (p != null) setState(() => _targetDate = p);
                    },
                    onClear: () => setState(() => _targetDate = null),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsTextField(
                    label: '${l.fieldNote} (${l.optional})',
                    controller: _note,
                    prefixIcon: Icons.notes_rounded,
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

class _HorizonPicker extends StatelessWidget {
  const _HorizonPicker({required this.value, required this.onChanged});
  final ProjectHorizon value;
  final ValueChanged<ProjectHorizon> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return Wrap(
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.sm,
      children: <Widget>[
        for (final ProjectHorizon h in ProjectHorizon.values)
          ChoiceChip(
            label: Text(horizonLabel(h, l)),
            selected: value == h,
            onSelected: (_) => onChanged(h),
            backgroundColor: c.surfaceMuted,
            selectedColor: c.brand.withValues(alpha: 0.18),
            side: BorderSide(color: value == h ? c.brand : c.border),
            labelStyle: TextStyle(
                color: value == h ? c.textPrimary : c.textMuted),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
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
        Text('${l.fieldTargetDate} (${l.optional})',
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
                    date == null
                        ? '—'
                        : DateFormat('yyyy-MM-dd').format(date!),
                    style: t.bodyMedium?.copyWith(color: c.textPrimary),
                  ),
                ),
                if (date != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.clear_rounded,
                        size: 16, color: c.textFaint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
