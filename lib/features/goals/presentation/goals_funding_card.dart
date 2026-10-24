import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_suffix.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/portfolio_planner.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Above the goals, in one sentence: is what the user can save each month
/// enough for all their goals on time? (The funding plan, without its own
/// page: nearest goals are funded first.)
class GoalsFundingCard extends ConsumerWidget {
  const GoalsFundingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final PortfolioPlan plan = ref.watch(portfolioPlanProvider);
    final Money suggested = ref.watch(suggestedCapacityProvider);
    String money(Money m) => MoneyFormatter.format(m);
    final bool unset = plan.capacity.minorUnits == 0;

    final (IconData icon, Color tone, String text) = unset
        ? (
            SbIcons.moneyBox, // never the pig-shaped icon
            c.brand,
            l.goalsFundingAsk,
          )
        : plan.feasible
            ? (
                Icons.check_circle_outline_rounded,
                c.income,
                l.goalsFundingEnough(money(plan.capacity)),
              )
            : (
                Icons.lightbulb_outline_rounded,
                c.warning,
                l.goalsFundingShort(money(plan.totalRequiredMonthly),
                    money(plan.capacity), money(plan.shortfall)),
              );

    return GlassCard(
      accent: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: tone),
              const SizedBox(width: DsSpacing.sm),
              Expanded(child: Text(text, style: t.bodyMedium)),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Wrap(
            spacing: DsSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(unset ? l.goalsFundingSet : l.goalsFundingChange),
                onPressed: () => _edit(context, ref),
              ),
              if (unset && suggested.minorUnits > 0)
                TextButton(
                  onPressed: () => ref
                      .read(portfolioCapacityProvider.notifier)
                      .set(suggested.minorUnits),
                  child: Text(l.useSuggested(money(suggested))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final int current = ref.read(portfolioCapacityProvider);
    final TextEditingController ctrl = TextEditingController(
      text: current == 0 ? '' : Money(current, currency).asDouble.toString(),
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.goalsFundingSet),
        content: TextField(
          inputFormatters: LatinDigitsFormatter.only,
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: l.fieldAmount, suffixIcon: CurrencySuffix(currency)),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok == true) {
      final double n =
          double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
      await ref
          .read(portfolioCapacityProvider.notifier)
          .set(Money.fromDouble(n, currency).minorUnits);
    }
    ctrl.dispose();
  }
}
