import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/challenges/application/challenges_controller.dart';
import 'package:smartbudget/features/challenges/domain/challenges.dart';
import 'package:smartbudget/features/challenges/presentation/challenge_share.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

(IconData, String, String) _badge(AppLocalizations l, BadgeKind b) => switch (b) {
      BadgeKind.firstEntry =>
        (Icons.flag_rounded, l.bFirstEntry, l.bFirstEntryHint),
      BadgeKind.cleanWeek => (
          Icons.local_fire_department_rounded,
          l.bCleanWeek,
          l.bCleanWeekHint
        ),
      BadgeKind.cleanMonth =>
        (Icons.whatshot_rounded, l.bCleanMonth, l.bCleanMonthHint),
      BadgeKind.saver20 => (SbIcons.moneyBoxFilled, l.bSaver, l.bSaverHint),
      BadgeKind.budgetKept =>
        (Icons.verified_rounded, l.bBudgetKept, l.bBudgetKeptHint),
      BadgeKind.goalReached =>
        (Icons.emoji_events_rounded, l.bGoal, l.bGoalHint),
      BadgeKind.challengeWon =>
        (Icons.military_tech_rounded, l.bChallenge, l.bChallengeHint),
      BadgeKind.seasonOnBudget =>
        (Icons.nightlight_round, l.bSeason, l.bSeasonHint),
      BadgeKind.daretComplete =>
        (Icons.groups_2_rounded, l.bDaret, l.bDaretHint),
    };

String _catLabel(BuildContext context, String c) => Catalog.label(c,
    ar: Localizations.localeOf(context).languageCode == 'ar');

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final String currency = ref.watch(baseCurrencyProvider);
    final Set<String> side = ref.watch(sideCategoriesProvider);
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final List<Challenge> mine =
        ref.watch(challengesProvider).valueOrNull ?? const <Challenge>[];

    final Map<Challenge, ChallengeProgress> progress =
        <Challenge, ChallengeProgress>{
      for (final Challenge ch in mine)
        ch: ChallengeEngine.evaluate(ch, txns, currency, now),
    };
    final List<Challenge> newest = List<Challenge>.of(mine)
      ..sort((Challenge a, Challenge b) => b.createdAt.compareTo(a.createdAt));
    final Challenge? active = newest
        .where((Challenge ch) => progress[ch]!.status == ChallengeStatus.active)
        .firstOrNull;
    // Without a running challenge, the latest result (last 7 days) is shown
    // up front, so a win can be shared and a miss retried right away.
    final Challenge? result = active != null
        ? null
        : newest
            .where((Challenge ch) =>
                now.difference(ch.end).inDays <= 7 ||
                progress[ch]!.status == ChallengeStatus.lost &&
                    now.difference(ch.createdAt).inDays <= 7)
            .firstOrNull;
    final List<Challenge> history = newest
        .where((Challenge ch) =>
            ch != active &&
            ch != result &&
            progress[ch]!.status != ChallengeStatus.active &&
            now.difference(ch.end).inDays <= 90)
        .toList();

    final Set<BadgeKind> earned = Badges.earned(
      txns: txns,
      currency: currency,
      now: now,
      sideCategories: side,
      budgets: ref.watch(budgetsProvider).valueOrNull ?? const <BudgetTarget>[],
      goals: ref.watch(goalsProvider).valueOrNull ?? const <Goal>[],
      challenges: mine,
      seasons:
          ref.watch(seasonPlansProvider).valueOrNull ?? const <SeasonPlan>[],
      darets: ref.watch(daretsProvider).valueOrNull ?? const <Daret>[],
    );

    final bool wide = !context.isMobile;
    Widget grid(List<Widget> children, {int maxCols = 3}) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final int cols = !wide
                ? 1
                : box.maxWidth > 1000
                    ? maxCols
                    : 2;
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
          Text(l.navChallenges, style: t.headlineSmall),
          const SizedBox(height: DsSpacing.xs),
          Text(l.chSubtitle, style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.xl),
          grid(<Widget>[
            _StatTile(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF97316),
              label: l.sfStreak,
              value: l.chDays(SideFreeStreaks.current(txns, side, now)),
              hint: l.chLongest(SideFreeStreaks.longest(txns, side, now)),
            ),
            _StatTile(
              icon: Icons.spa_outlined,
              color: c.income,
              label: l.sfMonth,
              value: '${SideFreeStreaks.thisMonth(txns, side, now)}',
              hint: l.sfMonthHint,
            ),
            _StatTile(
              icon: Icons.military_tech_rounded,
              color: c.brand,
              label: l.chBadges,
              value: '${earned.length}/${BadgeKind.values.length}',
              hint: l.chBadgesHint,
            ),
          ]),
          const SizedBox(height: DsSpacing.xxl),
          if (active != null)
            _ActiveCard(challenge: active, progress: progress[active]!)
          else ...<Widget>[
            if (result != null) ...<Widget>[
              _ResultCard(challenge: result, progress: progress[result]!),
              const SizedBox(height: DsSpacing.lg),
            ],
            const _StartCard(),
          ],
          if (history.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xxl),
            Text(l.sfHistory,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DsSpacing.md),
            GlassCard(
              child: Column(
                children: <Widget>[
                  for (final Challenge ch in history)
                    _HistoryRow(challenge: ch, progress: progress[ch]!),
                ],
              ),
            ),
          ],
          const SizedBox(height: DsSpacing.xxl),
          Text(l.chBadges,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              for (final BadgeKind b in BadgeKind.values)
                _BadgeTile(kind: b, earned: earned.contains(b)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: DsRadius.brMd,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: t.labelMedium?.copyWith(color: c.textMuted)),
                Text(value,
                    style:
                        t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text(hint, style: t.labelSmall?.copyWith(color: c.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick a length and what counts as side spending, then start today.
class _StartCard extends ConsumerStatefulWidget {
  const _StartCard();

  @override
  ConsumerState<_StartCard> createState() => _StartCardState();
}

class _StartCardState extends ConsumerState<_StartCard> {
  int _days = 7;

  /// Null until the user changes it: follows their saved choice meanwhile.
  Set<String>? _picked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Set<String> picked = _picked ?? ref.watch(sideCategoriesProvider);
    final List<String> custom =
        ref.watch(customCategoriesProvider).forType(TransactionType.expense);
    final List<String> options = <String>{
      ...SideFree.suggested,
      ...custom,
      ...picked,
    }.toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.14),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(Icons.spa_rounded, color: c.brand),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.sfStartTitle,
                        style: t.labelMedium?.copyWith(color: c.textMuted)),
                    Text(l.sfTitle(_days),
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Text(l.sfHow,
              style: t.bodySmall?.copyWith(color: c.textMuted, height: 1.5)),
          const SizedBox(height: DsSpacing.lg),
          Text(l.sfDuration, style: t.titleSmall),
          const SizedBox(height: DsSpacing.sm),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final int d in SideFree.durations)
                ChoiceChip(
                  label: Text(l.chDays(d)),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.sfSlipsRule(SideFree.allowedSlips(_days)),
              style: t.labelSmall?.copyWith(color: c.textFaint)),
          const SizedBox(height: DsSpacing.lg),
          Text(l.sfWhatCounts, style: t.titleSmall),
          Text(l.sfWhatCountsHint,
              style: t.labelSmall?.copyWith(color: c.textFaint)),
          const SizedBox(height: DsSpacing.sm),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final String cat in options)
                FilterChip(
                  label: Text(_catLabel(context, cat)),
                  selected: picked.contains(cat),
                  onSelected: (bool on) => setState(() {
                    final Set<String> next = Set<String>.of(picked);
                    on ? next.add(cat) : next.remove(cat);
                    _picked = next;
                  }),
                ),
            ],
          ),
          if (picked.isEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(l.sfPickOne, style: t.bodySmall?.copyWith(color: c.expense)),
          ],
          const SizedBox(height: DsSpacing.lg),
          DsButton(
            label: l.sfStart,
            icon: Icons.play_arrow_rounded,
            expand: true,
            onPressed: picked.isEmpty
                ? null
                : () => ref.read(challengeActionsProvider).start(_days, picked),
          ),
        ],
      ),
    );
  }
}

/// The running challenge: its days, today's state and what's left.
class _ActiveCard extends ConsumerWidget {
  const _ActiveCard({required this.challenge, required this.progress});
  final Challenge challenge;
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ChallengeProgress p = progress;
    final int dayIndex = p.days - p.daysLeft + 1;
    final bool slipToday = p.marks.length >= dayIndex &&
        p.marks[dayIndex - 1] == DayMark.slip;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.14),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: c.brand),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.sfTitle(challenge.days),
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                        '${l.sfDayOf(dayIndex, p.days)} · ${l.chDaysLeft(p.daysLeft)}',
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          DayStrip(marks: p.marks),
          const SizedBox(height: DsSpacing.lg),
          _Line(
            icon: slipToday
                ? Icons.sentiment_neutral_rounded
                : Icons.check_circle_rounded,
            color: slipToday ? c.warning : c.income,
            text: slipToday ? l.sfTodaySlip : l.sfTodayClean,
          ),
          const SizedBox(height: DsSpacing.xs),
          _Line(
            icon: Icons.event_available_rounded,
            color: c.textMuted,
            text:
                '${l.sfCleanCount(p.clean, p.days)} · ${l.sfSlipsLeft(p.slipsLeft)}',
          ),
          if (p.saved != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Tooltip(
              message: l.sfSavedHint,
              child: _Line(
                icon: SbIcons.moneyBoxFilled,
                color: c.saving,
                text: l.sfSaved(MoneyFormatter.format(p.saved!)),
              ),
            ),
          ],
          const SizedBox(height: DsSpacing.md),
          _CategoryTags(categories: challenge.categories),
          const SizedBox(height: DsSpacing.lg),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              if (p.clean > 0)
                DsButton(
                  label: l.sfShareProgress,
                  icon: Icons.ios_share_rounded,
                  onPressed: () =>
                      ChallengeShareSheet.show(context, challenge, p),
                ),
              DsButton(
                label: l.chGiveUp,
                icon: Icons.close_rounded,
                variant: DsButtonVariant.ghost,
                onPressed: () =>
                    ref.read(challengeActionsProvider).remove(challenge.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The latest result: a win to share, or a miss to retry (shorter).
class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.challenge, required this.progress});
  final Challenge challenge;
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ChallengeProgress p = progress;
    final bool won = p.status == ChallengeStatus.won;
    final Color color = won ? c.income : c.textMuted;
    // After a miss, suggest the next shorter length.
    final int again = won
        ? challenge.days
        : SideFree.durations.lastWhere((int d) => d < challenge.days,
            orElse: () => challenge.days);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(
                    won
                        ? Icons.emoji_events_rounded
                        : Icons.replay_circle_filled_rounded,
                    color: won ? const Color(0xFFF59E0B) : color),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(won ? l.chWon : l.chLost,
                        style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: won ? c.income : null)),
                    Text(l.sfTitle(challenge.days),
                        style: t.bodySmall?.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Text(won ? l.sfWonBody : l.sfLostBody,
              style: t.bodyMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.md),
          DayStrip(marks: p.marks),
          const SizedBox(height: DsSpacing.md),
          _Line(
            icon: Icons.event_available_rounded,
            color: c.textMuted,
            text: l.sfCleanCount(p.clean, p.days),
          ),
          if (won && p.saved != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            _Line(
              icon: SbIcons.moneyBoxFilled,
              color: c.saving,
              text: l.sfSaved(MoneyFormatter.format(p.saved!)),
            ),
          ],
          const SizedBox(height: DsSpacing.lg),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              if (won)
                DsButton(
                  label: l.chShare,
                  icon: Icons.ios_share_rounded,
                  onPressed: () =>
                      ChallengeShareSheet.show(context, challenge, p),
                ),
              DsButton(
                label: '${l.chAgain} · ${l.chDays(again)}',
                icon: Icons.replay_rounded,
                variant:
                    won ? DsButtonVariant.secondary : DsButtonVariant.primary,
                onPressed: () => ref
                    .read(challengeActionsProvider)
                    .start(again, challenge.categories),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.challenge, required this.progress});
  final Challenge challenge;
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool won = progress.status == ChallengeStatus.won;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(won ? Icons.emoji_events_rounded : Icons.cancel_outlined,
              size: 22,
              color: won ? const Color(0xFFF59E0B) : c.textFaint),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.sfTitle(challenge.days), style: t.titleSmall),
                Text(
                    '${isoDate(challenge.start)} · ${l.sfCleanCount(progress.clean, progress.days)}',
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          if (won)
            IconButton(
              tooltip: l.chShare,
              icon: Icon(Icons.ios_share_rounded, size: 18, color: c.brand),
              onPressed: () =>
                  ChallengeShareSheet.show(context, challenge, progress),
            ),
          IconButton(
            tooltip: l.delete,
            icon: Icon(Icons.close_rounded, size: 18, color: c.textFaint),
            onPressed: () =>
                ref.read(challengeActionsProvider).remove(challenge.id),
          ),
        ],
      ),
    );
  }
}

/// One circle per day: a check when clean, a cross when there was side
/// spending, a ring for today and the day number for the days ahead.
class DayStrip extends StatelessWidget {
  const DayStrip({super.key, required this.marks});
  final List<DayMark> marks;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final double size = marks.length > 14 ? 26 : 34;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (int i = 0; i < marks.length; i++)
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (marks[i]) {
                DayMark.clean => c.income,
                DayMark.slip => c.expense.withValues(alpha: 0.18),
                DayMark.today => c.brand.withValues(alpha: 0.12),
                DayMark.upcoming => c.surfaceMuted,
              },
              border: marks[i] == DayMark.today
                  ? Border.all(color: c.brand, width: 2)
                  : marks[i] == DayMark.slip
                      ? Border.all(color: c.expense)
                      : null,
            ),
            child: switch (marks[i]) {
              DayMark.clean =>
                Icon(Icons.check_rounded, size: size * 0.55, color: Colors.white),
              DayMark.slip =>
                Icon(Icons.close_rounded, size: size * 0.5, color: c.expense),
              _ => Text('${i + 1}',
                  style: t.labelSmall?.copyWith(
                      color: marks[i] == DayMark.today
                          ? c.brand
                          : c.textFaint,
                      fontWeight: FontWeight.w700)),
            },
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: DsSpacing.sm),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.dsColors.textPrimary)),
        ),
      ],
    );
  }
}

/// What this challenge counts as side spending (read-only).
class _CategoryTags extends StatelessWidget {
  const _CategoryTags({required this.categories});
  final Set<String> categories;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final String cat in categories)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.border),
            ),
            child: Text(_catLabel(context, cat),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: c.textMuted)),
          ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.kind, required this.earned});
  final BadgeKind kind;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final (IconData icon, String name, String hint) = _badge(l, kind);
    final Color color = earned ? const Color(0xFFF59E0B) : c.textFaint;
    return Tooltip(
      message: hint,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(DsSpacing.md),
        decoration: BoxDecoration(
          color: earned ? color.withValues(alpha: 0.10) : c.surfaceMuted,
          borderRadius: DsRadius.brMd,
          border: Border.all(
              color: earned ? color.withValues(alpha: 0.45) : c.border),
        ),
        child: Column(
          children: <Widget>[
            Icon(earned ? icon : Icons.lock_outline_rounded,
                color: color, size: 30),
            const SizedBox(height: DsSpacing.sm),
            Text(name,
                textAlign: TextAlign.center,
                style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: earned ? null : c.textMuted)),
            const SizedBox(height: 2),
            Text(hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(color: c.textFaint)),
          ],
        ),
      ),
    );
  }
}
