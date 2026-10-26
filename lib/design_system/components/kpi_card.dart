import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Direction of a period-over-period change on a KPI (drives the arrow only).
enum KpiTrend { up, down, flat }

/// Semantic reading of the change for THIS KPI (drives the color). Income up is
/// good; expenses up is bad — never inferred from the arrow direction.
enum KpiTone { good, bad, neutral }

/// A period-over-period delta shown on a KPI card.
class KpiDelta {
  const KpiDelta({
    required this.label,
    required this.trend,
    this.tone = KpiTone.neutral,
    this.comparable = true,
  });

  /// A delta with no valid baseline — shows [label] (e.g. "No comparison") with
  /// no arrow and a neutral color, never a misleading percentage.
  const KpiDelta.noComparison(this.label)
      : trend = KpiTrend.flat,
        tone = KpiTone.neutral,
        comparable = false;

  final String label; // e.g. "+12.5%"
  final KpiTrend trend;
  final KpiTone tone;
  final bool comparable;
}

/// Premium KPI tile: label + big value + optional trend + optional sparkline.
///
/// [value] is nullable ON PURPOSE: with no real SmartBudget data wired yet, the
/// card renders a neutral empty state ("—") rather than a fabricated number.
///
/// Under a [MoneyPrivacy], a small eye button hides every card's figure (and
/// its change) at once; pressing and holding a hidden figure peeks at it until
/// released.
class KpiCard extends StatefulWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconChild,
    this.delta,
    this.accent,
    this.caption,
    this.sparkline,
    this.loading = false,
  });

  final String label;
  final String? value;

  /// The figure is on its way: a shimmering bone of the figure's height
  /// stands in for it (inside a [DsShimmerScope] it sweeps).
  final bool loading;
  final IconData? icon;

  /// A custom glyph (e.g. `Icon(SbIcons.moneyBox)`) rendered inside the icon chip in
  /// place of a Material [icon]. Its colour/size come from the chip's IconTheme.
  final Widget? iconChild;
  final KpiDelta? delta;

  /// The metric's meaning: pass the theme's income or expense color for those
  /// metrics; any other value (or none) renders in the brand blue.
  final Color? accent;
  final String? caption;

  /// Optional chart widget rendered under the value (wired in later phases).
  final Widget? sparkline;

  /// Below this width (two cards side by side on a phone) the card tightens
  /// its padding, icon and figure.
  static const double compactWidth = 220;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _peeking = false;

  String get label => widget.label;
  String? get value => widget.value;
  IconData? get icon => widget.icon;
  Widget? get iconChild => widget.iconChild;
  Color? get accent => widget.accent;
  String? get caption => widget.caption;
  Widget? get sparkline => widget.sparkline;

  void _peek(bool on) {
    if (_peeking != on) setState(() => _peeking = on);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) =>
          _build(context, box.maxWidth < KpiCard.compactWidth));

  Widget _build(BuildContext context, bool compact) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    // Privacy applies only to a real figure — the empty state has nothing
    // to hide.
    final MoneyPrivacy? privacy =
        value == null ? null : MoneyPrivacy.maybeOf(context);
    final bool masked = (privacy?.masked ?? false) && !_peeking;
    final KpiDelta? delta = masked ? null : widget.delta;
    // Universal financial colors, decided in one place for every KPI in the
    // app: green for income, red for expenses, blue (the logo color) for
    // everything else — net, balance, savings rate…
    final Color accentColor = accent == c.income
        ? c.income
        : (accent == c.expense ? c.expense : c.brand);

    return GlassCard(
      accent: accentColor,
      tintBorder: true,
      padding: compact
          ? const EdgeInsets.fromLTRB(
              DsSpacing.md, DsSpacing.md, DsSpacing.md, DsSpacing.md)
          : const EdgeInsets.fromLTRB(
              DsSpacing.lg, DsSpacing.lg, DsSpacing.lg, DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null || iconChild != null) ...<Widget>[
                _IconChip(
                    icon: icon,
                    iconChild: iconChild,
                    color: accentColor,
                    size: compact ? 32 : 40),
                SizedBox(width: compact ? DsSpacing.sm : DsSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: t.titleSmall?.copyWith(
                      color: c.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 12.5 : null),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (privacy != null)
                PrivacyEyeButton(
                  hidden: privacy.masked,
                  tooltip:
                      privacy.masked ? privacy.showLabel : privacy.hideLabel,
                  onTap: privacy.onToggle,
                ),
            ],
          ),
          SizedBox(height: compact ? DsSpacing.sm : DsSpacing.md),
          // The figure is the hero: large, tabular, never clipped (it scales
          // down instead on narrow tiles).
          if (widget.loading)
            Stack(
              alignment: AlignmentDirectional.centerStart,
              children: <Widget>[
                // Invisible text of the figure's style keeps its height.
                Opacity(
                  opacity: 0,
                  child: Text('0',
                      style: DsTypography.mono(
                        t.headlineMedium ?? const TextStyle(),
                      ).copyWith(
                          fontSize: compact ? 22 : 28,
                          fontWeight: FontWeight.w800)),
                ),
                DsBone(width: compact ? 88 : 120, height: compact ? 18 : 22),
              ],
            )
          else
          _maybePeekable(
            privacy,
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  masked ? MoneyPrivacy.mask : (value ?? '—'),
                  key: ValueKey<bool>(masked),
                  maxLines: 1,
                  semanticsLabel: masked ? privacy!.peekHint : null,
                  style: DsTypography.mono(
                    t.headlineMedium ?? const TextStyle(),
                  ).copyWith(
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    color:
                        value == null || masked ? c.textFaint : c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          // Side by side there's no room for both: the comparison goes under
          // the change.
          if (compact && (delta != null || caption != null)) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            if (delta != null) _TrendPill(delta: delta),
            if (caption != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(color: c.textFaint)),
            ],
          ] else if (delta != null || caption != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Row(
              children: <Widget>[
                if (delta != null) ...<Widget>[
                  _TrendPill(delta: delta),
                  const SizedBox(width: DsSpacing.sm),
                ],
                if (caption != null)
                  Flexible(
                    child: Text(caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(color: c.textFaint)),
                  ),
              ],
            ),
          ],
          if (sparkline != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            SizedBox(height: 40, child: sparkline),
          ],
        ],
      ),
    );
  }

  /// While privacy is on, pressing and holding the figure shows it until
  /// the finger (or mouse button) lifts.
  Widget _maybePeekable(MoneyPrivacy? privacy, Widget figure) {
    if (privacy == null || !privacy.masked) return figure;
    return Tooltip(
      message: privacy.peekHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _peek(true),
        onLongPressEnd: (_) => _peek(false),
        onLongPressCancel: () => _peek(false),
        child: figure,
      ),
    );
  }
}

/// The eye that hides or shows money figures (see [MoneyPrivacy]). [color]
/// replaces the theme colours on a coloured surface.
class PrivacyEyeButton extends StatelessWidget {
  const PrivacyEyeButton(
      {super.key,
      required this.hidden,
      required this.tooltip,
      required this.onTap,
      this.color});
  final bool hidden;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  /// The eye for the [MoneyPrivacy] above [context], or nothing without one.
  static Widget of(BuildContext context, {Color? color}) {
    final MoneyPrivacy? p = MoneyPrivacy.maybeOf(context);
    if (p == null) return const SizedBox.shrink();
    return PrivacyEyeButton(
      hidden: p.masked,
      tooltip: p.masked ? p.showLabel : p.hideLabel,
      onTap: p.onToggle,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: hidden,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                key: ValueKey<bool>(hidden),
                size: 16,
                color: color?.withValues(alpha: hidden ? 1 : 0.6) ??
                    (hidden ? c.brand : c.textFaint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip(
      {this.icon, this.iconChild, required this.color, this.size = 40});
  final IconData? icon;
  final Widget? iconChild;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14),
        ],
      ),
      child: iconChild != null
          ? IconTheme.merge(
              data: IconThemeData(color: color, size: size / 2),
              child: iconChild!,
            )
          : Icon(icon, size: size / 2, color: color),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta});
  final KpiDelta delta;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    // Color is driven by the semantic tone, NOT the arrow direction.
    final Color color = switch (delta.tone) {
      KpiTone.good => c.income,
      KpiTone.bad => c.expense,
      KpiTone.neutral => c.textMuted,
    };
    final IconData? icon = !delta.comparable
        ? null
        : switch (delta.trend) {
            KpiTrend.up => Icons.trending_up_rounded,
            KpiTrend.down => Icons.trending_down_rounded,
            KpiTrend.flat => Icons.trending_flat_rounded,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            delta.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
