import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/amount_dialog.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/seasons/presentation/season_editor_sheet.dart';
import 'package:smartbudget/features/seasons/presentation/season_text.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class SeasonsPage extends ConsumerWidget {
  const SeasonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<SeasonPlan> plans =
        ref.watch(seasonPlansProvider).valueOrNull ?? const <SeasonPlan>[];
    final DateTime now = AppClock.now();

    // Presets without a plan for their current/next occurrence.
    final List<SeasonKind> suggestions = <SeasonKind>[
      for (final SeasonKind k in SeasonKind.values)
        if (k != SeasonKind.custom &&
            !plans.any((SeasonPlan p) =>
                p.kind == k &&
                SeasonMath.status(p, now) != SeasonStatus.ended))
          k,
    ]..sort((SeasonKind a, SeasonKind b) => SeasonCalendar.next(a, now)
        .start
        .compareTo(SeasonCalendar.next(b, now).start));

    final bool wide = !context.isMobile;
    Widget grid(List<Widget> children) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final int cols = wide && box.maxWidth > 760 ? 2 : 1;
            final double w =
                (box.maxWidth - DsSpacing.lg * (cols - 1)) / cols;
            return Wrap(
              spacing: DsSpacing.lg,
              runSpacing: DsSpacing.lg,
              children: <Widget>[
                for (final Widget ch in children) SizedBox(width: w, child: ch),
              ],
            );
          },
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: DsSpacing.md,
            spacing: DsSpacing.md,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.navSeasons, style: t.headlineSmall),
                  const SizedBox(height: DsSpacing.xs),
                  Text(l.seasonsSubtitle,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
              DsButton(
                label: l.seasonPlanNew,
                icon: Icons.add_rounded,
                onPressed: () => SeasonEditorSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xl),
          if (plans.isNotEmpty) ...<Widget>[
            grid(<Widget>[
              for (final SeasonPlan p in plans) _PlanCard(plan: p),
            ]),
            const SizedBox(height: DsSpacing.xxl),
          ],
          if (suggestions.isNotEmpty) ...<Widget>[
            Text(l.seasonsUpcoming,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DsSpacing.md),
            grid(<Widget>[
              for (final SeasonKind k in suggestions) _SuggestionCard(kind: k),
            ]),
          ],
        ],
      ),
    );
  }
}

String _countdown(AppLocalizations l, int days) =>
    days == 0 ? l.seasonStartsToday : l.seasonInDays(days);

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.kind});
  final SeasonKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final String currency = ref.watch(baseCurrencyProvider);
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final SeasonWindow w = SeasonCalendar.next(kind, now);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final bool active = !today.isBefore(w.start);
    final int days = w.start.difference(today).inDays;
    final Money last =
        SeasonMath.spentIn(SeasonCalendar.previous(kind, now), txns, currency);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(
            kind: kind,
            title: seasonName(l, kind, ''),
            subtitle: '${seasonDateLabel(l, kind, w)} · ${_ymd(w.start)}',
            chip: active ? l.seasonActive : _countdown(l, days),
            chipColor: active ? c.income : c.brand,
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            last.minorUnits > 0
                ? l.seasonLastSpent(MoneyFormatter.format(last))
                : l.seasonNoHistory,
            style: t.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.seasonPlanIt,
            icon: Icons.savings_outlined,
            variant: DsButtonVariant.secondary,
            onPressed: () =>
                SeasonEditorSheet.show(context, kind: kind, window: w),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});
  final SeasonPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final String currency = ref.watch(baseCurrencyProvider);
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final SeasonPlan p = plan;
    final SeasonStatus status = SeasonMath.status(p, now);
    final SeasonWindow w = (start: p.start, end: p.end);

    final String chip = switch (status) {
      SeasonStatus.upcoming => _countdown(l, SeasonMath.daysUntil(p, now)),
      SeasonStatus.active => l.seasonActive,
      SeasonStatus.ended => l.seasonEnded,
    };
    final Color chipColor = switch (status) {
      SeasonStatus.upcoming => c.brand,
      SeasonStatus.active => c.income,
      SeasonStatus.ended => c.textMuted,
    };

    final int budget = p.budget.minorUnits;
    final Money spent = SeasonMath.spent(p, txns, currency);
    final bool funded = p.saved.minorUnits >= budget;

    Widget bar(double value, Color color) => ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: c.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(
            kind: p.kind,
            title: seasonName(l, p.kind, p.name),
            subtitle: p.kind == SeasonKind.custom
                ? '${_ymd(p.start)} – ${_ymd(p.end)}'
                : '${seasonDateLabel(l, p.kind, w)} · ${_ymd(p.start)} – ${_ymd(p.end)}',
            chip: chip,
            chipColor: chipColor,
            menu: PopupMenuButton<String>(
              icon:
                  Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
              color: c.bgElevated,
              onSelected: (String v) async {
                if (v == 'edit') {
                  await SeasonEditorSheet.show(context, existing: p);
                } else if (v == 'delete') {
                  await ref.read(seasonActionsProvider).delete(p.id);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.lg),
          if (status == SeasonStatus.upcoming) ...<Widget>[
            _Line(
              label: l.seasonSaved,
              value:
                  '${MoneyFormatter.format(p.saved)} / ${MoneyFormatter.format(p.budget)}',
            ),
            const SizedBox(height: DsSpacing.sm),
            bar(budget == 0 ? 0 : p.saved.minorUnits / budget,
                funded ? c.income : seasonColor(p.kind)),
            const SizedBox(height: DsSpacing.md),
            Row(
              children: <Widget>[
                Icon(funded ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded,
                    size: 16, color: funded ? c.income : c.warning),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    funded
                        ? l.seasonReady
                        : l.seasonMonthly(MoneyFormatter.format(
                            SeasonMath.monthlyNeeded(p, now))),
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            _Line(
              label: l.seasonSpent,
              value:
                  '${MoneyFormatter.format(spent)} / ${MoneyFormatter.format(p.budget)}',
              valueColor: spent.minorUnits > budget ? c.expense : null,
            ),
            const SizedBox(height: DsSpacing.sm),
            bar(budget == 0 ? 0 : spent.minorUnits / budget,
                spent.minorUnits > budget ? c.expense : c.income),
            const SizedBox(height: DsSpacing.md),
            Text(
              spent.minorUnits > budget
                  ? l.seasonOver(MoneyFormatter.format(Money(
                      spent.minorUnits - budget, p.budget.currencyCode)))
                  : l.seasonUnder(MoneyFormatter.format(Money(
                      budget - spent.minorUnits, p.budget.currencyCode))),
              style: t.bodySmall?.copyWith(
                  color: spent.minorUnits > budget ? c.expense : c.income),
            ),
          ],
          const SizedBox(height: DsSpacing.md),
          if (status == SeasonStatus.ended)
            DsButton(
              label: l.seasonPlanNext,
              icon: Icons.event_repeat_outlined,
              variant: DsButtonVariant.secondary,
              onPressed: p.kind == SeasonKind.custom
                  ? () => SeasonEditorSheet.show(context,
                      kind: SeasonKind.custom)
                  : () => SeasonEditorSheet.show(context,
                      kind: p.kind,
                      window: SeasonCalendar.after(p.kind, w)),
            )
          else if (status == SeasonStatus.upcoming && !funded)
            DsButton(
              label: l.seasonAddSaving,
              icon: Icons.add_rounded,
              variant: DsButtonVariant.secondary,
              onPressed: () async {
                final double? n = await showAmountDialog(context,
                    title: l.seasonAddSaving,
                    currency: p.budget.currencyCode);
                if (n == null) return;
                await ref.read(seasonActionsProvider).contribute(
                    p, Money.fromDouble(n, p.budget.currencyCode));
              },
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.chip,
    required this.chipColor,
    this.menu,
  });

  final SeasonKind kind;
  final String title;
  final String subtitle;
  final String chip;
  final Color chipColor;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Color color = seasonColor(kind);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: DsRadius.brMd,
          ),
          child: Icon(seasonIcon(kind), color: color, size: 22),
        ),
        const SizedBox(width: DsSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(chip,
              style: t.labelSmall
                  ?.copyWith(color: chipColor, fontWeight: FontWeight.w700)),
        ),
        if (menu != null) menu!,
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
            child: Text(label, style: t.bodySmall?.copyWith(color: c.textMuted))),
        Text(value,
            style: t.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

/// A date as yyyy-MM-dd, isolated left-to-right so Arabic text around it
/// can't reorder its parts.
String _ymd(DateTime d) =>
    '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069';
