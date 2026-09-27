import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/challenges/application/challenges_controller.dart';
import 'package:smartbudget/features/challenges/domain/challenges.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/share/data/native_share.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

String challengeTitle(AppLocalizations l, ChallengeType t) => switch (t) {
      ChallengeType.noEatingOut7 => l.chNoEatingOut,
      ChallengeType.noShopping7 => l.chNoShopping,
      ChallengeType.noSpend3of7 => l.chNoSpend3,
      ChallengeType.logDaily7 => l.chLogDaily,
      ChallengeType.save10Month => l.chSave(10),
      ChallengeType.save20Month => l.chSave(20),
    };

String _challengeBody(AppLocalizations l, ChallengeType t) => switch (t) {
      ChallengeType.noEatingOut7 => l.chNoEatingOutBody,
      ChallengeType.noShopping7 => l.chNoShoppingBody,
      ChallengeType.noSpend3of7 => l.chNoSpend3Body,
      ChallengeType.logDaily7 => l.chLogDailyBody,
      ChallengeType.save10Month => l.chSaveBody(10),
      ChallengeType.save20Month => l.chSaveBody(20),
    };

IconData _challengeIcon(ChallengeType t) => switch (t) {
      ChallengeType.noEatingOut7 => Icons.no_meals_outlined,
      ChallengeType.noShopping7 => Icons.remove_shopping_cart_outlined,
      ChallengeType.noSpend3of7 => Icons.money_off_rounded,
      ChallengeType.logDaily7 => Icons.edit_calendar_outlined,
      ChallengeType.save10Month => Icons.savings_outlined,
      ChallengeType.save20Month => Icons.savings_rounded,
    };

(IconData, String, String) _badge(AppLocalizations l, BadgeKind b) => switch (b) {
      BadgeKind.firstEntry =>
        (Icons.flag_rounded, l.bFirstEntry, l.bFirstEntryHint),
      BadgeKind.streak7 => (
          Icons.local_fire_department_rounded,
          l.bStreak(7),
          l.bStreakHint(7)
        ),
      BadgeKind.streak30 => (
          Icons.whatshot_rounded,
          l.bStreak(30),
          l.bStreakHint(30)
        ),
      BadgeKind.saver20 => (Icons.savings_rounded, l.bSaver, l.bSaverHint),
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

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final DateTime now = AppClock.now();
    final String currency = ref.watch(baseCurrencyProvider);
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final List<Challenge> mine =
        ref.watch(challengesProvider).valueOrNull ?? const <Challenge>[];

    final Map<Challenge, ChallengeProgress> progress = <Challenge, ChallengeProgress>{
      for (final Challenge ch in mine)
        ch: ChallengeEngine.evaluate(ch, txns, currency, now),
    };
    // Active first, then results from the last 30 days.
    final List<Challenge> shown = mine
        .where((Challenge ch) =>
            progress[ch]!.status == ChallengeStatus.active ||
            now.difference(ch.end).inDays <= 30)
        .toList()
      ..sort((Challenge a, Challenge b) {
        final bool aa = progress[a]!.status == ChallengeStatus.active;
        final bool bb = progress[b]!.status == ChallengeStatus.active;
        if (aa != bb) return aa ? -1 : 1;
        return b.start.compareTo(a.start);
      });
    final Set<ChallengeType> running = <ChallengeType>{
      for (final Challenge ch in mine)
        if (progress[ch]!.status == ChallengeStatus.active) ch.type,
    };

    final Set<BadgeKind> earned = Badges.earned(
      txns: txns,
      currency: currency,
      now: now,
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
              label: l.chStreak,
              value: l.chDays(Streaks.current(txns, now)),
              hint: l.chLongest(Streaks.longest(txns)),
            ),
            _StatTile(
              icon: Icons.spa_outlined,
              color: c.income,
              label: l.chNoSpendDays,
              value: '${Streaks.noSpendDaysThisMonth(txns, now)}',
              hint: l.chNoSpendDaysHint,
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
          if (shown.isNotEmpty) ...<Widget>[
            Text(l.chMine,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DsSpacing.md),
            grid(<Widget>[
              for (final Challenge ch in shown)
                _ChallengeCard(challenge: ch, progress: progress[ch]!),
            ], maxCols: 2),
            const SizedBox(height: DsSpacing.xxl),
          ],
          Text(l.chStart,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DsSpacing.md),
          grid(<Widget>[
            for (final ChallengeType type in ChallengeType.values)
              if (!running.contains(type)) _OfferCard(type: type),
          ]),
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

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.type});
  final ChallengeType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_challengeIcon(type), color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(challengeTitle(l, type),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(_challengeBody(l, type),
              style: t.bodySmall?.copyWith(color: c.textMuted, height: 1.4)),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.chStartIt,
            icon: Icons.play_arrow_rounded,
            variant: DsButtonVariant.secondary,
            onPressed: () => ref.read(challengeActionsProvider).start(type),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge, required this.progress});
  final Challenge challenge;
  final ChallengeProgress progress;

  Future<void> _share(BuildContext context, AppLocalizations l) async {
    final String text = l.chShareText(challengeTitle(l, challenge.type));
    final String url = ShareQr.appUrl();
    final NativeShareResult r = await shareNatively(text: text, url: url);
    if (r != NativeShareResult.unsupported) return;
    await Clipboard.setData(ClipboardData(text: '$text\n$url'));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.shareTextCopied)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ChallengeProgress p = progress;
    final ChallengeActions actions = ref.read(challengeActionsProvider);

    final Color color = switch (p.status) {
      ChallengeStatus.active => c.brand,
      ChallengeStatus.won => c.income,
      ChallengeStatus.lost => c.textMuted,
    };
    final String detail = challenge.type.monthly
        ? l.chSaveProgress(p.current, p.target)
        : l.chProgress(p.current, p.target);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(
                    p.status == ChallengeStatus.won
                        ? Icons.emoji_events_rounded
                        : _challengeIcon(challenge.type),
                    color: color),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(challengeTitle(l, challenge.type),
                        style: t.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      switch (p.status) {
                        ChallengeStatus.active => l.chDaysLeft(p.daysLeft),
                        ChallengeStatus.won => l.chWon,
                        ChallengeStatus.lost => l.chLost,
                      },
                      style: t.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: p.status == ChallengeStatus.active
                    ? l.chGiveUp
                    : l.delete,
                icon: Icon(Icons.close_rounded, size: 18, color: c.textFaint),
                onPressed: () => actions.remove(challenge.id),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p.status == ChallengeStatus.won ? 1 : p.fraction,
              minHeight: 9,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(detail, style: t.labelMedium?.copyWith(color: c.textMuted)),
          if (p.status != ChallengeStatus.active) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
              children: <Widget>[
                if (p.status == ChallengeStatus.won)
                  DsButton(
                    label: l.chShare,
                    icon: Icons.ios_share_rounded,
                    onPressed: () => _share(context, l),
                  ),
                DsButton(
                  label: l.chAgain,
                  icon: Icons.replay_rounded,
                  variant: DsButtonVariant.secondary,
                  onPressed: () => actions.start(challenge.type),
                ),
              ],
            ),
          ],
        ],
      ),
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
