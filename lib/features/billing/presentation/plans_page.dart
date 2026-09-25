import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/data/checkout_service.dart';
import 'package:smartbudget/features/billing/data/coupon_service.dart';
import 'package:smartbudget/features/billing/data/subscription_service.dart';
import 'package:smartbudget/features/billing/domain/coupon.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/domain/user_subscription.dart';
import 'package:smartbudget/features/billing/presentation/plan_labels.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Plans & upgrade screen — a transparent side-by-side of FREE / BASIC / PRO.
///
/// Prices and quotas come from the tiering source of truth ([Plan],
/// [FeatureCatalog]); nothing here is hardcoded twice. Checkout is not wired
/// yet, so the Upgrade CTA is honest: it explains billing is coming rather than
/// faking a purchase. Nothing on this page touches the financial engine.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Plan current = ref.watch(effectivePlanProvider);
    final bool wide = MediaQuery.of(context).size.width >= 900;

    final List<Widget> cards = <Widget>[
      for (final Plan p in Plan.values)
        _PlanCard(plan: p, current: current, highlight: p == Plan.basic),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.workspace_premium_outlined,
                      color: context.dsColors.brand),
                  const SizedBox(width: DsSpacing.sm),
                  BrandedTitle(l.plansTitle,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(l.plansSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: DsSpacing.xl),
              if (AppEnv.betaAllAccess) const _BetaBanner(),
              const _CurrentPlanCard(),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < cards.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: DsSpacing.md),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                )
              else
                for (final Widget card in cards) ...<Widget>[
                  card,
                  const SizedBox(height: DsSpacing.md),
                ],
              if (!AppEnv.betaAllAccess) ...<Widget>[
                const SizedBox(height: DsSpacing.md),
                const _CouponBox(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Beta notice: every feature is free until paid plans launch.
class _BetaBanner extends StatelessWidget {
  const _BetaBanner();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
      child: GlassCard(
        accent: c.brand,
        child: Row(
          children: <Widget>[
            Icon(Icons.science_outlined, size: 20, color: c.brand),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.betaAllUnlocked,
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(l.betaPlansNote,
                      style: t.labelSmall?.copyWith(color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the user's active paid subscription (plan + renewal/cancel date) with
/// a Manage/cancel action that opens the provider's portal. Hidden when there's
/// no active paid subscription.
class _CurrentPlanCard extends ConsumerWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSubscription? sub = ref.watch(subscriptionProvider).valueOrNull;
    if (sub == null || !sub.isPaidActive) return const SizedBox.shrink();

    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String? date = _fmtDate(sub.currentPeriodEnd);

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
      child: GlassCard(
        accent: c.brand,
        child: Row(
          children: <Widget>[
            Icon(Icons.verified_outlined, size: 20, color: c.brand),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.subYoureOn(planName(l, sub.plan)),
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (date != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      sub.cancelAtPeriodEnd
                          ? l.subCancels(date)
                          : l.subRenews(date),
                      style: t.labelSmall?.copyWith(color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            const _ManageButton(),
          ],
        ),
      ),
    );
  }
}

class _ManageButton extends ConsumerStatefulWidget {
  const _ManageButton();

  @override
  ConsumerState<_ManageButton> createState() => _ManageButtonState();
}

class _ManageButtonState extends ConsumerState<_ManageButton> {
  bool _busy = false;

  Future<void> _open() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final String? url =
        await ref.read(subscriptionServiceProvider).manageUrl();
    if (!mounted) return;
    setState(() => _busy = false);
    if (url != null) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l.subManageUnavailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DsButton(
      label: l.subManage,
      variant: DsButtonVariant.secondary,
      onPressed: _busy ? null : _open,
    );
  }
}

String? _fmtDate(DateTime? d) {
  if (d == null) return null;
  final DateTime x = d.toLocal();
  final String m = x.month.toString().padLeft(2, '0');
  final String day = x.day.toString().padLeft(2, '0');
  return '${x.year}-$m-$day';
}

/// "Have a coupon?" — validates a marketing code against the server and shows
/// its effect. Pre-checkout preview only (probe mode): it never redeems the
/// code. A coupon changes price/trial, never feature access.
class _CouponBox extends ConsumerStatefulWidget {
  const _CouponBox();

  @override
  ConsumerState<_CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends ConsumerState<_CouponBox> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  CouponResult? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final String code = _ctrl.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    final CouponResult r = await ref.read(couponServiceProvider).validate(code);
    if (mounted) {
      setState(() {
        _busy = false;
        _result = r;
      });
    }
  }

  String _validMessage(AppLocalizations l, CouponResult r) => switch (r.kind) {
        CouponKind.percent => l.couponValidPercent(r.value.round()),
        CouponKind.fixed => l.couponValidFixed('\$${_trim(r.value)}'),
        CouponKind.trialExtension => l.couponValidTrial(r.trialDays ?? 0),
        CouponKind.unknown => l.couponApply,
      };

  String _invalidMessage(AppLocalizations l, CouponReason reason) =>
      switch (reason) {
        CouponReason.expired => l.couponExpired,
        CouponReason.exhausted => l.couponExhausted,
        CouponReason.alreadyUsed => l.couponAlreadyUsed,
        CouponReason.notApplicable => l.couponNotApplicable,
        CouponReason.network => l.couponSignIn,
        CouponReason.invalid => l.couponInvalid,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final CouponResult? r = _result;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.local_offer_outlined, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Text(l.couponHave,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  inputFormatters: LatinDigitsFormatter.only,
                  controller: _ctrl,
                  enabled: !_busy,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.couponPlaceholder,
                    filled: true,
                    fillColor: c.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.brand),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              DsButton(
                label: _busy ? l.couponChecking : l.couponApply,
                onPressed: _busy ? null : _apply,
              ),
            ],
          ),
          if (r != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  r.valid
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: r.valid ? c.income : c.expense,
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    r.valid
                        ? _validMessage(l, r)
                        : _invalidMessage(l, r.reason ?? CouponReason.invalid),
                    style: t.bodySmall?.copyWith(
                        color: r.valid ? c.income : c.expense),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.highlight,
  });

  final Plan plan;
  final Plan current;
  final bool highlight;

  int _limit(Feature f) => FeatureCatalog.quotaFor(f, plan)?.limit ?? 0;

  List<String> _features(AppLocalizations l) {
    switch (plan) {
      case Plan.free:
        return <String>[
          l.planFeatEngine,
          l.planFeatAiLifetime(_limit(Feature.dgotixAi)),
          l.planFeatOcrLifetime(_limit(Feature.cloudOcr)),
          l.planFeatOnDeviceOcr,
        ];
      case Plan.basic:
        return <String>[
          l.planFeatEverythingIn(l.planFree),
          l.planFeatSalarySplit,
          l.planFeatSmartAlerts,
          l.planFeatAiMonthly(_limit(Feature.dgotixAi)),
          l.planFeatOcrMonthly(_limit(Feature.cloudOcr)),
          l.planFeatAdvancedReports,
          l.planFeatCloudSync,
        ];
      case Plan.pro:
        return <String>[
          l.planFeatEverythingIn(l.planBasic),
          l.planFeatAiMonthly(_limit(Feature.dgotixAi)),
          l.planFeatOcrMonthly(_limit(Feature.cloudOcr)),
          l.planFeatAdvancedReports,
          l.planFeatCloudSync,
          l.planFeatPriority,
        ];
    }
  }

  /// Whole-percent yearly saving vs 12× monthly, or null when not computable.
  int? _yearlySavePercent() {
    final double? m = plan.priceUsd(BillingPeriod.monthly);
    final double? y = plan.priceUsd(BillingPeriod.yearly);
    if (m == null || y == null || m <= 0) return null;
    final double full = m * 12;
    if (full <= 0) return null;
    return ((full - y) / full * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    // During the beta everything is unlocked, so no card is "current".
    final bool isCurrent = !AppEnv.betaAllAccess && plan == current;

    final double? monthly = plan.priceUsd(BillingPeriod.monthly);
    final double? yearly = plan.priceUsd(BillingPeriod.yearly);
    final int? save = _yearlySavePercent();

    return GlassCard(
      accent: highlight ? c.brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(planName(l, plan),
                    style: t.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800, color: c.brand)),
              ),
              if (highlight) _Pill(text: l.planMostPopular, color: c.brand),
              if (isCurrent && !highlight)
                _Pill(text: l.planCurrent, color: c.textMuted),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          // Price
          if (plan == Plan.free)
            Text(l.planPriceFree,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
          else ...<Widget>[
            Text(
              l.planPerMonth(_money(monthly)),
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Text(l.planPerYear(_money(yearly)),
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                if (save != null && save > 0) ...<Widget>[
                  const SizedBox(width: DsSpacing.sm),
                  _Pill(text: l.planYearlySave(save), color: c.income),
                ],
              ],
            ),
          ],
          const SizedBox(height: DsSpacing.lg),
          for (final String f in _features(l)) ...<Widget>[
            _FeatureRow(text: f),
            const SizedBox(height: DsSpacing.sm),
          ],
          const SizedBox(height: DsSpacing.sm),
          _cta(context, l, c, isCurrent),
        ],
      ),
    );
  }

  Widget _cta(
      BuildContext context, AppLocalizations l, DsColors c, bool isCurrent) {
    // Beta: nothing to buy yet.
    if (AppEnv.betaAllAccess) return const SizedBox.shrink();
    if (isCurrent) {
      return DsButton(
        label: l.planCurrent,
        variant: DsButtonVariant.secondary,
        expand: true,
        onPressed: null,
      );
    }
    // Only offer upward moves; a lower tier than the current one shows nothing.
    if (!plan.atLeast(current)) {
      return const SizedBox.shrink();
    }
    return _UpgradeCta(plan: plan);
  }
}

/// The upgrade button for a paid plan: asks monthly vs yearly, then opens the
/// server-created checkout URL. When the provider isn't configured yet it falls
/// back gracefully to the "billing coming soon" note. Upgrade is the only path
/// to more AI: DGOTIX is the sole AI provider and quotas come with the plan.
class _UpgradeCta extends ConsumerStatefulWidget {
  const _UpgradeCta({required this.plan});
  final Plan plan;

  @override
  ConsumerState<_UpgradeCta> createState() => _UpgradeCtaState();
}

class _UpgradeCtaState extends ConsumerState<_UpgradeCta> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DsButton(
      label: _busy ? l.checkoutOpening : l.planUpgradeTo(planName(l, widget.plan)),
      icon: Icons.arrow_upward_rounded,
      expand: true,
      onPressed: _busy ? null : _onTap,
    );
  }

  Future<void> _onTap() async {
    final BillingPeriod? period = await _pickPeriod();
    if (period == null || !mounted) return;

    // Which payment methods are actually configured?
    List<PayProvider> providers;
    try {
      providers = await ref.read(enabledProvidersProvider.future);
    } catch (_) {
      providers = const <PayProvider>[];
    }
    if (!mounted) return;

    final PayProvider provider;
    if (providers.length >= 2) {
      final PayProvider? chosen = await _pickProvider(providers);
      if (chosen == null || !mounted) return;
      provider = chosen;
    } else {
      provider = providers.isNotEmpty ? providers.first : PayProvider.paddle;
    }
    await _start(period, provider);
  }

  Future<PayProvider?> _pickProvider(List<PayProvider> providers) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return showModalBottomSheet<PayProvider>(
      context: context,
      backgroundColor: c.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: DsSpacing.sm),
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Text(l.payChooseMethod,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final PayProvider p in providers)
              ListTile(
                leading: Icon(
                  p == PayProvider.paypal
                      ? Icons.account_balance_wallet_outlined
                      : Icons.credit_card_outlined,
                  color: c.brand,
                ),
                title: Text(
                    p == PayProvider.paypal ? l.payMethodPaypal : l.payMethodCard),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
            const SizedBox(height: DsSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<BillingPeriod?> _pickPeriod() {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final int? save = _yearlySavePercentFor(widget.plan);
    return showModalBottomSheet<BillingPeriod>(
      context: context,
      backgroundColor: c.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: DsSpacing.sm),
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Text(l.planChooseBilling,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: Icon(Icons.calendar_view_month_outlined, color: c.brand),
              title: Text(l.planPerMonth(
                  _money(widget.plan.priceUsd(BillingPeriod.monthly)))),
              onTap: () => Navigator.of(ctx).pop(BillingPeriod.monthly),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: c.brand),
              title: Text(l.planPerYear(
                  _money(widget.plan.priceUsd(BillingPeriod.yearly)))),
              trailing: (save != null && save > 0)
                  ? _Pill(text: l.planYearlySave(save), color: c.income)
                  : null,
              onTap: () => Navigator.of(ctx).pop(BillingPeriod.yearly),
            ),
            const SizedBox(height: DsSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BillingPeriod period, PayProvider provider) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!ref.read(authControllerProvider).isAuthenticated) {
      messenger.showSnackBar(SnackBar(content: Text(l.checkoutSignIn)));
      return;
    }
    setState(() => _busy = true);
    final CheckoutStart r = await ref
        .read(checkoutServiceProvider)
        .start(plan: widget.plan, period: period, provider: provider);
    if (!mounted) return;
    setState(() => _busy = false);

    if (r.ok) {
      await launchUrl(Uri.parse(r.url!),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank');
      // When they return, re-fetch so the new plan shows without a restart.
      if (mounted) ref.invalidate(remoteEntitlementProvider);
    } else if (r.error == CheckoutError.notConfigured) {
      messenger.showSnackBar(SnackBar(content: Text(l.planBillingSoon)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.checkoutError)));
    }
  }
}

/// Whole-percent yearly saving vs 12× monthly for a plan, or null.
int? _yearlySavePercentFor(Plan plan) {
  final double? m = plan.priceUsd(BillingPeriod.monthly);
  final double? y = plan.priceUsd(BillingPeriod.yearly);
  if (m == null || y == null || m <= 0) return null;
  final double full = m * 12;
  if (full <= 0) return null;
  return ((full - y) / full * 100).round();
}

String _money(double? v) {
  if (v == null) return '—';
  return v == v.roundToDouble()
      ? '\$${v.toInt()}'
      : '\$${v.toStringAsFixed(2)}';
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.check_circle_rounded, size: 16, color: c.income),
        const SizedBox(width: DsSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: DsRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
