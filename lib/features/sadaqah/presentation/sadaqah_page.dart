import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/settings/islamic_features.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/sadaqah/application/sadaqah_controller.dart';
import 'package:smartbudget/features/sadaqah/data/sadaqah_notifications.dart';
import 'package:smartbudget/features/sadaqah/domain/sadaqah_commitment.dart';
import 'package:smartbudget/features/sadaqah/presentation/sadaqah_promo_card.dart';
import 'package:smartbudget/features/sadaqah/presentation/sadaqah_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Sadaqah Planner (Giving Planner when the Islamic features are hidden):
/// regular gifts, weekly or monthly, with an optional private reminder.
/// Free on every plan.
class SadaqahPage extends ConsumerStatefulWidget {
  const SadaqahPage({super.key});

  @override
  ConsumerState<SadaqahPage> createState() => _SadaqahPageState();
}

class _SadaqahPageState extends ConsumerState<SadaqahPage> {
  /// The phone refused notifications when the user turned reminders on.
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    // Opened from the menu: the dashboard's introduction isn't needed.
    SadaqahPromo.markOpened();
  }

  Future<void> _toggleReminders(bool on) async {
    HapticFeedback.selectionClick();
    final bool ok = await ref.read(sadaqahProvider.notifier).setReminders(on);
    if (mounted) setState(() => _blocked = on && !ok);
  }

  Future<void> _done(SadaqahCommitment c, SadaqahText s) async {
    HapticFeedback.selectionClick();
    final SadaqahController ctrl = ref.read(sadaqahProvider.notifier);
    final String? txn = await ctrl.markDone(c);
    if (!mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.doneFor(c.frequency)),
        action: SnackBarAction(
          label: l.sadaqahUndo,
          onPressed: () => ctrl.undoDone(c, txn),
        ),
      ));
  }

  Future<void> _delete(SadaqahCommitment c, SadaqahText s) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(s.deleteQuestion),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await ref.read(sadaqahProvider.notifier).delete(c.id);
  }

  Future<void> _edit([SadaqahCommitment? c]) async {
    final String base = ref.read(baseCurrencyProvider);
    final SadaqahCommitment? result =
        await showModalBottomSheet<SadaqahCommitment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _Editor(initial: c, currency: base),
    );
    if (result != null) {
      await ref.read(sadaqahProvider.notifier).save(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final SadaqahState st = ref.watch(sadaqahProvider);
    final SadaqahText s =
        SadaqahText(l, islamic: ref.watch(islamicFeaturesProvider));
    final String lang = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(s.title, style: t.headlineSmall)),
              IconButton(
                tooltip:
                    st.hideAmounts ? l.sadaqahShowAmounts : l.sadaqahHideAmounts,
                icon: Icon(st.hideAmounts
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => ref
                    .read(sadaqahProvider.notifier)
                    .setHideAmounts(!st.hideAmounts),
              ),
              const SizedBox(width: DsSpacing.sm),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.add),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          GlassCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline_rounded, size: 20, color: c.brand),
                const SizedBox(width: DsSpacing.md),
                Expanded(child: Text(s.hint, style: t.bodyMedium)),
              ],
            ),
          ),
          // Phone reminders exist in the Android app only.
          if (SadaqahNotifications.supported) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                        st.remindersOn
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: c.brand),
                    title: Text(s.remindersTitle, style: t.titleSmall),
                    subtitle: Text(l.sadaqahRemindersHint,
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                    value: st.remindersOn,
                    onChanged: _toggleReminders,
                  ),
                  if (_blocked) ...<Widget>[
                    Text(l.reminderPermissionDenied,
                        style: t.bodySmall?.copyWith(color: c.warning)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () =>
                            ReminderNotifications.instance.openSystemSettings(),
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 18),
                        label: Text(l.actionOpenSettings),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: DsSpacing.lg),
          if (st.loaded && st.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.x4l),
              child: Text(s.empty,
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: c.textMuted)),
            ),
          for (final SadaqahCommitment item in st.items)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.md),
              child: _Tile(
                item: item,
                text: s,
                lang: lang,
                hideAmount: st.hideAmounts,
                remindersOn: st.remindersOn,
                onTap: () => _edit(item),
                onDone: () => _done(item, s),
                onDelete: () => _delete(item, s),
                onToggleRemind: () => ref
                    .read(sadaqahProvider.notifier)
                    .save(item.copyWith(remind: !item.remind)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.text,
    required this.lang,
    required this.hideAmount,
    required this.remindersOn,
    required this.onTap,
    required this.onDone,
    required this.onDelete,
    required this.onToggleRemind,
  });

  final SadaqahCommitment item;
  final SadaqahText text;
  final String lang;
  final bool hideAmount;
  final bool remindersOn;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onDelete;
  final VoidCallback onToggleRemind;

  /// Soft rose, the warm family of expense colours (Charity & donations).
  static const Color _tint = Color(0xFFF8C8D4);
  static const Color _ink = Color(0xFF8A2E4A);

  IconData get _icon => switch (item.kind) {
        SadaqahKind.sadaqah => Icons.volunteer_activism_outlined,
        SadaqahKind.family => Icons.family_restroom_outlined,
        SadaqahKind.sponsorship => Icons.child_care_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool paid = item.isPaidFor(DateTime.now());
    final Money? amount = item.amount;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: _tint,
            child: Icon(_icon, size: 20, color: _ink),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        item.note.isNotEmpty ? item.note : text.kind(item.kind),
                        style: t.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (amount != null) ...<Widget>[
                      const SizedBox(width: DsSpacing.sm),
                      Text(
                        hideAmount ? '••••' : MoneyFormatter.format(amount),
                        style: t.bodyMedium?.copyWith(color: c.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DsSpacing.xxs),
                Row(
                  children: <Widget>[
                    if (remindersOn && item.remind) ...<Widget>[
                      Icon(Icons.notifications_none_rounded,
                          size: 14, color: c.textMuted),
                      const SizedBox(width: DsSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        text.schedule(item, lang),
                        style: t.bodySmall?.copyWith(color: c.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: paid
                ? Chip(
                    key: const ValueKey<String>('paid'),
                    avatar: Icon(Icons.check_rounded, size: 16, color: c.income),
                    label: Text(text.doneFor(item.frequency)),
                    visualDensity: VisualDensity.compact,
                  )
                : FilledButton.tonal(
                    key: const ValueKey<String>('todo'),
                    onPressed: onDone,
                    child: Text(l.sadaqahDone),
                  ),
          ),
          PopupMenuButton<int>(
            onSelected: (int v) {
              if (v == 0) {
                onTap();
              } else if (v == 1) {
                onToggleRemind();
              } else {
                onDelete();
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 0, child: Text(l.edit)),
              if (remindersOn)
                CheckedPopupMenuItem<int>(
                    value: 1,
                    checked: item.remind,
                    child: Text(l.sadaqahRemindThis)),
              PopupMenuItem<int>(value: 2, child: Text(l.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor({this.initial, required this.currency});

  final SadaqahCommitment? initial;
  final String currency;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late SadaqahCommitment _c = widget.initial ??
      SadaqahCommitment(
          id: SadaqahController.newId(), createdAt: DateTime.now());
  late final TextEditingController _amount = TextEditingController(
      text: _c.amount == null ? '' : _c.amount!.asDouble.toString());
  late final TextEditingController _note =
      TextEditingController(text: _c.note);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final double? v = AmountInput.parse(_amount.text);
    final String currency = _c.amount?.currencyCode ?? widget.currency;
    Navigator.pop(
      context,
      _c.copyWith(
        note: _note.text.trim(),
        amount: v != null && v > 0 ? Money.fromDouble(v, currency) : null,
        clearAmount: v == null || v <= 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final SadaqahText s =
        SadaqahText(l, islamic: IslamicFeatures.enabled.value);
    final String lang = Localizations.localeOf(context).languageCode;
    final bool weekly = _c.frequency == SadaqahFrequency.weekly;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            DsSpacing.xl, DsSpacing.lg, DsSpacing.xl, DsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.initial == null ? s.add : l.edit,
                style: t.titleLarge),
            const SizedBox(height: DsSpacing.lg),
            Text(l.sadaqahKind, style: t.labelLarge),
            const SizedBox(height: DsSpacing.xs),
            Wrap(
              spacing: DsSpacing.sm,
              children: <Widget>[
                for (final SadaqahKind k in SadaqahKind.values)
                  ChoiceChip(
                    label: Text(s.kind(k)),
                    selected: _c.kind == k,
                    onSelected: (_) => setState(() => _c = _c.copyWith(kind: k)),
                  ),
              ],
            ),
            const SizedBox(height: DsSpacing.lg),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.sadaqahAmount,
                suffixText: _c.amount?.currencyCode ?? widget.currency,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            TextField(
              controller: _note,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: l.sadaqahNote,
                helperText: l.sadaqahNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(l.sadaqahRepeat, style: t.labelLarge),
            const SizedBox(height: DsSpacing.xs),
            SegmentedButton<SadaqahFrequency>(
              segments: <ButtonSegment<SadaqahFrequency>>[
                ButtonSegment<SadaqahFrequency>(
                    value: SadaqahFrequency.weekly,
                    label: Text(l.sadaqahWeekly)),
                ButtonSegment<SadaqahFrequency>(
                    value: SadaqahFrequency.monthly,
                    label: Text(l.sadaqahMonthly)),
              ],
              selected: <SadaqahFrequency>{_c.frequency},
              onSelectionChanged: (Set<SadaqahFrequency> v) =>
                  setState(() => _c = _c.copyWith(frequency: v.first)),
            ),
            const SizedBox(height: DsSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    // Rebuilt when the frequency changes its list.
                    key: ValueKey<SadaqahFrequency>(_c.frequency),
                    initialValue: weekly ? _c.weekday : _c.dayOfMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.sadaqahDay,
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<int>>[
                      for (int i = 1; i <= (weekly ? 7 : 28); i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                              weekly ? SadaqahText.weekday(i, lang) : '$i'),
                        ),
                    ],
                    onChanged: (int? v) {
                      if (v == null) return;
                      setState(() => _c = weekly
                          ? _c.copyWith(weekday: v)
                          : _c.copyWith(dayOfMonth: v));
                    },
                  ),
                ),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(
                      '${_c.hour.toString().padLeft(2, '0')}:${_c.minute.toString().padLeft(2, '0')}',
                      textDirection: TextDirection.ltr,
                    ),
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: _c.hour, minute: _c.minute),
                      );
                      if (picked != null) {
                        setState(() => _c = _c.copyWith(
                            hour: picked.hour, minute: picked.minute));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.sadaqahRecord, style: t.bodyMedium),
              value: _c.recordAsExpense,
              onChanged: (bool v) =>
                  setState(() => _c = _c.copyWith(recordAsExpense: v)),
            ),
            const SizedBox(height: DsSpacing.md),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
