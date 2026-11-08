import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/data/checkout_service.dart';
import 'package:smartbudget/features/billing/domain/founding_offer.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/domain/pro_highlights.dart';
import 'package:smartbudget/features/billing/presentation/checkout_flow.dart';
import 'package:smartbudget/features/billing/presentation/plans_page.dart'
    show CouponBox;
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Go PRO" without leaving the screen: a card that slides down from the top
/// with the few reasons that matter, the two prices (yearly chosen) and one
/// button that opens the checkout. The full comparison stays on the plans page
/// ("see all features").
abstract final class UpgradePopup {
  /// Opens the pop-up — or, where nothing is on sale (the open beta), the
  /// plans page, as before.
  static Future<void> show(BuildContext context) {
    final ProviderContainer c =
        ProviderScope.containerOf(context, listen: false);
    final bool payTest = c.read(paymentTestModeProvider).valueOrNull ?? false;
    final bool selling = !AppEnv.betaAllAccess || payTest;
    if (!selling) {
      context.go('/plans');
      return Future<void>.value();
    }
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (BuildContext ctx, _, __) => const SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.all(DsSpacing.md),
            child: _PopupCard(),
          ),
        ),
      ),
      transitionBuilder: (BuildContext ctx, Animation<double> a, _, Widget child) {
        final Animation<double> curved =
            CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, -0.12), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _PopupCard extends ConsumerStatefulWidget {
  const _PopupCard();

  @override
  ConsumerState<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends ConsumerState<_PopupCard> {
  BillingPeriod _period = BillingPeriod.yearly;
  bool _busy = false;
  bool _coupon = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? message = await runProCheckout(context, ref,
        plan: Plan.pro, period: _period);
    if (!mounted) return;
    setState(() => _busy = false);
    if (message == null) {
      Navigator.of(context).pop(); // the checkout opened
    } else {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final FoundingOffer? offer = ref.watch(foundingOfferProvider).valueOrNull;
    final double? monthly = Plan.pro.priceUsd(BillingPeriod.monthly);
    final double? yearly = Plan.pro.priceUsd(BillingPeriod.yearly);
    final int? save = _savePercent(monthly, yearly);

    return Material(
      color: c.bgElevated,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header band.
              Container(
                padding: const EdgeInsets.fromLTRB(
                    DsSpacing.lg, DsSpacing.lg, DsSpacing.sm, DsSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: <Color>[
                      c.brand,
                      Color.lerp(c.brand, Colors.black, 0.35)!,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: DsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.upPopTitle,
                              style: t.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(l.upPopSub,
                              style: t.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DsSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final ProHighlight h
                        in ProHighlights.forPopup()) ...<Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(h.icon, size: 20, color: c.brand),
                          const SizedBox(width: DsSpacing.md),
                          Expanded(
                              child: Text(h.text(l), style: t.bodyMedium)),
                        ],
                      ),
                      const SizedBox(height: DsSpacing.sm),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/plans');
                        },
                        child: Text(l.upPopSeeAll),
                      ),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    _PriceOption(
                      selected: _period == BillingPeriod.yearly,
                      title: offer != null
                          ? l.foundingLocked(_ltr(_money(offer.yearlyUsd)),
                              _ltr(_money(yearly)))
                          : l.planPerYear(_money(yearly)),
                      badge: offer != null
                          ? l.foundingBadge
                          : (save != null && save > 0)
                              ? l.planYearlySave(save)
                              : null,
                      badgeColor: offer != null ? c.brand : c.income,
                      onTap: () =>
                          setState(() => _period = BillingPeriod.yearly),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    _PriceOption(
                      selected: _period == BillingPeriod.monthly,
                      title: l.planPerMonth(_money(monthly)),
                      onTap: () =>
                          setState(() => _period = BillingPeriod.monthly),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    DsButton(
                      label: _busy ? l.checkoutOpening : l.upPopStart,
                      icon: Icons.arrow_upward_rounded,
                      expand: true,
                      onPressed: _busy ? null : _start,
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: DsSpacing.sm),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: t.bodySmall?.copyWith(color: c.expense)),
                    ],
                    const SizedBox(height: DsSpacing.xs),
                    if (_coupon)
                      const CouponBox()
                    else
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _coupon = true),
                          child: Text(l.couponHave),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  const _PriceOption({
    required this.selected,
    required this.title,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final bool selected;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: DsRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.md),
        decoration: BoxDecoration(
          borderRadius: DsRadius.brMd,
          color: selected ? c.brand.withValues(alpha: 0.10) : null,
          border: Border.all(
              color: selected ? c.brand : c.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? c.brand : c.textMuted,
            ),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Text(title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? c.income).withValues(alpha: 0.16),
                  borderRadius: DsRadius.brPill,
                ),
                child: Text(badge!,
                    style: t.labelSmall?.copyWith(
                        color: badgeColor ?? c.income,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

int? _savePercent(double? m, double? y) {
  if (m == null || y == null || m <= 0) return null;
  final double full = m * 12;
  return full <= 0 ? null : ((full - y) / full * 100).round();
}

/// A price kept in its own left-to-right order inside a sentence.
String _ltr(String s) => '\u2066$s\u2069';

String _money(double? v) {
  if (v == null) return '—';
  return v == v.roundToDouble()
      ? '\$${v.toInt()}'
      : '\$${v.toStringAsFixed(2)}';
}
