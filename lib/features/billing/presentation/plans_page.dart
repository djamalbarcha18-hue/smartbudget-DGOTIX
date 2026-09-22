import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/data/coupon_service.dart';
import 'package:smartbudget/features/billing/domain/coupon.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
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
              const SizedBox(height: DsSpacing.md),
              const _CouponBox(),
            ],
          ),
        ),
      ),
    );
  }
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
    final bool isCurrent = plan == current;

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
    return DsButton(
      label: l.planUpgradeTo(planName(l, plan)),
      icon: Icons.arrow_upward_rounded,
      expand: true,
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.planBillingSoon)),
      ),
    );
  }
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
