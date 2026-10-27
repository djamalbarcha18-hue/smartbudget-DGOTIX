import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_alert.dart';
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metal_editor_sheet.dart';
import 'package:smartbudget/features/metals/presentation/metal_history_chart.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/features/sync/application/data_loading.dart';
import 'package:smartbudget/features/sync/presentation/page_skeleton.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Gold, silver, platinum and palladium kept as savings: each piece or bar, what it is
/// worth at today's price, and the price per gram used.
class MetalsPage extends ConsumerWidget {
  const MetalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AsyncValue<List<MetalHolding>> holdingsAsync =
        ref.watch(metalHoldingsProvider);
    final List<MetalHolding> holdings =
        holdingsAsync.valueOrNull ?? const <MetalHolding>[];
    final bool waiting = awaitingData(holdingsAsync,
        cloudPending: ref.watch(firstCloudCopyPendingProvider));
    final MetalsSummary summary = ref.watch(metalsSummaryProvider);
    final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);
    ref.watch(metalHistoryRecorderProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.metalsTitle, style: t.headlineSmall),
          const SizedBox(height: DsSpacing.xs),
          Text(l.metalsHint, style: t.bodyMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.lg),
          DsButton(
            label: l.metalsAdd,
            icon: Icons.add_rounded,
            onPressed: () => MetalEditorSheet.show(context),
          ),
          const SizedBox(height: DsSpacing.lg),
          if (waiting)
            const PageSkeleton(
              child: DsSkeletonCards(count: 2, lines: 2),
            )
          else if (holdings.isEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MetalBar(metal: Metal.silver, width: 80),
                SizedBox(width: DsSpacing.sm),
                MetalBar(metal: Metal.gold, width: 96),
              ],
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(l.metalsEmptyTitle,
                style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: DsSpacing.xs),
            Text(l.metalsEmptyMessage,
                style: t.bodyMedium?.copyWith(color: c.textMuted),
                textAlign: TextAlign.center),
          ] else ...<Widget>[
            _SummaryCard(summary: summary),
            const SizedBox(height: DsSpacing.lg),
            for (final MetalHolding h in holdings)
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                child: _HoldingTile(holding: h, price: prices[h.metal]),
              ),
            const _YearsCard(),
          ],
          const SizedBox(height: DsSpacing.lg),
          if (holdings.isNotEmpty) ...<Widget>[
            const MetalHistoryCard(),
            const SizedBox(height: DsSpacing.lg),
          ],
          const _PricesCard(),
          const SizedBox(height: DsSpacing.md),
          Text(l.metalsEstimate,
              style: t.bodySmall?.copyWith(color: c.textFaint)),
          const SizedBox(height: DsSpacing.xl),
        ],
      ),
    );
  }
}

/// [m], or the privacy mask while amounts are hidden.
String _money(BuildContext context, Money m) =>
    (MoneyPrivacy.maybeOf(context)?.masked ?? false)
        ? MoneyPrivacy.mask
        : MoneyFormatter.format(m);

/// [m] kept in one piece inside a sentence (any writing direction).
String _inline(Money m) => '\u2066${MoneyFormatter.format(m)}\u2069';

bool _masked(BuildContext context) =>
    MoneyPrivacy.maybeOf(context)?.masked ?? false;

String _percent(double r) {
  final String s = (r * 100).toStringAsFixed(1);
  return '\u2066${r >= 0 ? '+' : ''}$s%\u2069';
}

/// A gain or loss in its colour: [text] gets the signed amount and share
/// (both hidden while amounts are).
class _GainText extends StatelessWidget {
  const _GainText(this.gain, this.text, {this.style});
  final Gain gain;
  final String Function(String amount, String percent) text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool masked = _masked(context);
    final Money a = gain.amount;
    final String amount = masked
        ? MoneyPrivacy.mask
        : '\u2066${a.minorUnits >= 0 ? '+' : ''}${MoneyFormatter.format(a)}\u2069';
    final String percent =
        masked || gain.ratio == null ? '' : _percent(gain.ratio!);
    return Text(
      text(amount, percent),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(
          color: masked
              ? c.textMuted
              : gain.isGain
                  ? c.income
                  : c.expense,
          fontWeight: FontWeight.w700),
    );
  }
}

/// The purchases grouped by the year they were made: what was paid then,
/// what it is worth now. Shown once there are two years or more.
class _YearsCard extends ConsumerWidget {
  const _YearsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<YearGain> years = ref.watch(metalYearGainsProvider);
    if (years.length < 2) return const SizedBox.shrink();
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: GlassCard(
        hoverable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DsSectionHeader(
                title: l.metalsByYear, icon: Icons.calendar_month_rounded),
            const SizedBox(height: DsSpacing.sm),
            for (final YearGain y in years)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 52,
                      child: Text('${y.year}',
                          style: t.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: Text(
                        _masked(context)
                            ? l.metalsYearPaid(
                                MoneyPrivacy.mask, MoneyPrivacy.mask)
                            : l.metalsYearPaid(
                                _inline(y.gain.paid), _inline(y.gain.value)),
                        style: t.labelMedium?.copyWith(color: c.textMuted),
                      ),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    _GainText(y.gain, (String amount, String percent) =>
                        percent.isEmpty ? amount : percent,
                        style: t.labelLarge),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.summary});
  final MetalsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ({Money paid, Money value})? paid = summary.paidTotal;
    final Map<Metal, MetalAverage> averages = ref.watch(metalAveragesProvider);
    final int withoutCost = MetalGains.withoutCost(
        ref.watch(metalHoldingsProvider).valueOrNull ??
            const <MetalHolding>[]);
    return GlassCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(l.metalsWorthToday,
                    style: t.labelLarge?.copyWith(color: c.textMuted)),
              ),
              PrivacyEyeButton.of(context),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(_money(context, summary.total),
              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (paid != null &&
              paid.paid.minorUnits > 0 &&
              !_masked(context)) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            _GainText(
              Gain(paid: paid.paid, value: paid.value),
              (String amount, String percent) =>
                  l.metalsGainSince(amount, percent),
              style: t.labelLarge,
            ),
            if (withoutCost > 0)
              Text(l.metalsNoCostNote(withoutCost),
                  style: t.bodySmall?.copyWith(color: c.textFaint)),
          ],
          const SizedBox(height: DsSpacing.md),
          for (final Metal m in Metal.values)
            if (summary.pureGrams.containsKey(m))
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                child: MetalPlate(
                  metal: m,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          MetalBar(metal: m, width: 72),
                          const SizedBox(width: DsSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(MetalText.name(l, m),
                                    style: t.titleMedium?.copyWith(
                                        color: MetalPalette.of(m).ink,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                  l.metalsPure(
                                      MetalText.grams(l, summary.pureGrams[m]!)),
                                  style: t.labelMedium?.copyWith(
                                      color: MetalPalette.of(m)
                                          .ink
                                          .withValues(alpha: 0.75)),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              summary.byMetal[m] == null
                                  ? '—'
                                  : _money(context, summary.byMetal[m]!),
                              textAlign: TextAlign.end,
                              style: t.titleMedium?.copyWith(
                                  color: MetalPalette.of(m).ink,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      // What a pure gram cost on average, against today's.
                      if (averages[m] != null && !_masked(context)) ...<Widget>[
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          l.metalsAvgVsNow(_inline(averages[m]!.paidPerGram),
                              _inline(averages[m]!.todayPerGram)),
                          style: t.labelMedium?.copyWith(
                              color: MetalPalette.of(m).ink,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          if (summary.unpriced.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(l.metalsNoPrice,
                style: t.bodySmall?.copyWith(color: c.warning)),
          ],
        ],
      ),
    );
  }
}

class _HoldingTile extends ConsumerWidget {
  const _HoldingTile({required this.holding, required this.price});
  final MetalHolding holding;
  final MetalPrice? price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final MetalHolding h = holding;
    final Money? value =
        price == null ? null : MetalsValuation.value(h, price!);
    final Gain? gain =
        MetalGains.ofHolding(h, price, ref.watch(ratesProvider));
    final String title =
        h.name.isNotEmpty ? h.name : MetalText.name(l, h.metal);
    final String bought =
        monthText(Localizations.localeOf(context), MetalGains.boughtOn(h));
    return Material(
      color: c.surface,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => MetalEditorSheet.show(context, existing: h),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Row(
            children: <Widget>[
              MetalBar(metal: h.metal, width: 52),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall),
                    Text(
                      <String>[
                        if (h.name.isNotEmpty) MetalText.name(l, h.metal),
                        MetalText.grams(l, h.grams),
                        MetalText.purity(l, h.metal, h.purity),
                      ].join(' · '),
                      style: t.labelSmall,
                    ),
                    if (gain != null)
                      _GainText(
                          gain,
                          (String amount, String percent) => percent.isEmpty
                              ? bought
                              : '$bought · $percent',
                          style: t.labelSmall)
                    else
                      Text(
                          h.paid == null
                              ? '$bought · ${l.metalsNoCost}'
                              : bought,
                          style: t.labelSmall?.copyWith(color: c.textFaint)),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(value == null ? '—' : _money(context, value),
                        textAlign: TextAlign.end,
                        style: t.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (gain != null)
                      _GainText(gain, (String amount, String _) => amount,
                          style: t.labelSmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await MetalEditorSheet.show(context, existing: h);
                  } else if (v == 'delete') {
                    final bool? ok = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                        title: Text(l.metalsDeleteTitle),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(l.cancel)),
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(l.delete)),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(metalActionsProvider).delete(h.id);
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's price per gram of each pure metal, where it comes from, and the
/// user's own local price.
class _PricesCard extends ConsumerWidget {
  const _PricesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);
    final String currency = ref.watch(baseCurrencyProvider);
    final Map<Metal, MetalAlert> alerts = <Metal, MetalAlert>{
      for (final MetalAlert a in ref.watch(metalAlertsProvider))
        if (a.currency == currency) a.metal: a,
    };
    final List<MetalHolding> holdings =
        ref.watch(metalHoldingsProvider).valueOrNull ?? const <MetalHolding>[];
    return GlassCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(
              title: l.metalsPrices, icon: Icons.show_chart_rounded),
          const SizedBox(height: DsSpacing.sm),
          for (final Metal m in _precious)
            _plate(context, ref, m, prices, alerts),
          _IndustrialFold(
            open: _industrial.any((Metal m) =>
                alerts.containsKey(m) ||
                holdings.any((MetalHolding h) => h.metal == m)),
            children: <Widget>[
              for (final Metal m in _industrial)
                _plate(context, ref, m, prices, alerts),
            ],
          ),
        ],
      ),
    );
  }

  /// Gold and silver, shown first; platinum and palladium are industrial
  /// metals, folded under their own heading.
  static const List<Metal> _precious = <Metal>[Metal.gold, Metal.silver];
  static const List<Metal> _industrial = <Metal>[
    Metal.platinum,
    Metal.palladium,
  ];

  Widget _plate(BuildContext context, WidgetRef ref, Metal m,
      Map<Metal, MetalPrice> prices, Map<Metal, MetalAlert> alerts) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final Locale locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: MetalPlate(
        metal: m,
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.sm),
        onTap: () => _setPrice(context, ref, m, prices[m]),
        child: Row(
          children: <Widget>[
            MetalBar(metal: m, width: 60),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      '${MetalText.name(l, m)} · ${MetalText.purity(l, m, m == Metal.gold ? 24 : 999)}',
                      style: t.titleSmall?.copyWith(
                          color: MetalPalette.of(m).ink,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    prices[m] == null
                        ? '—'
                        : l.metalsPerGram(MoneyFormatter.format(
                            Money.fromDouble(
                                prices[m]!.perGram, prices[m]!.currency))),
                    style: t.titleMedium?.copyWith(
                        color: MetalPalette.of(m).ink,
                        fontWeight: FontWeight.w900),
                  ),
                  Text(
                    switch (prices[m]?.source) {
                      null => l.metalsNoPriceShort,
                      MetalPriceSource.mine => l.metalsSourceMine,
                      MetalPriceSource.market => l.metalsSourceMarket(prices[m]!
                                  .updatedAt ==
                              null
                          ? '—'
                          : '${dayText(locale, prices[m]!.updatedAt!.toLocal())} '
                              '${_hm(prices[m]!.updatedAt!.toLocal())}'),
                    },
                    style: t.labelSmall?.copyWith(
                        color: MetalPalette.of(m).ink.withValues(alpha: 0.75),
                        fontWeight: prices[m]?.source == MetalPriceSource.mine
                            ? FontWeight.w800
                            : null),
                  ),
                  if (alerts[m] case final MetalAlert a) ...<Widget>[
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Icon(
                            a.above
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: MetalPalette.of(m).ink),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            (a.above ? l.metalsAlertAbove : l.metalsAlertBelow)(
                                MoneyFormatter.format(
                                    Money.fromDouble(a.target, a.currency))),
                            style: t.labelSmall?.copyWith(
                                color: MetalPalette.of(m).ink,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: l.metalsAlert,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      _setAlert(context, ref, m, prices[m], alerts[m]),
                  icon: Icon(
                      alerts[m] == null
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      size: 20,
                      color: MetalPalette.of(m)
                          .ink
                          .withValues(alpha: alerts[m] == null ? 0.7 : 1)),
                ),
                IconButton(
                  tooltip: l.metalsSetPrice,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _setPrice(context, ref, m, prices[m]),
                  icon: Icon(Icons.edit_outlined,
                      size: 18,
                      color: MetalPalette.of(m).ink.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _hm(DateTime d) =>
      '\u2066${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}\u2069';

  Future<void> _setAlert(BuildContext context, WidgetRef ref, Metal m,
      MetalPrice? now, MetalAlert? existing) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final (String, String)? result = await showDialog<(String, String)>(
      context: context,
      builder: (BuildContext ctx) => _AmountDialog(
        title: l.metalsAlert,
        hint: l.metalsAlertHint(MetalText.name(l, m)),
        label:
            '${MetalText.name(l, m)} · ${MetalText.purity(l, m, m == Metal.gold ? 24 : 999)}',
        helper: now == null
            ? null
            : l.metalsPerGram(MoneyFormatter.format(
                Money.fromDouble(now.perGram, now.currency))),
        note: l.metalsAlertNote,
        currency: currency,
        initial: existing == null ? '' : AmountInput.text(existing.target),
        actions: <(String, String)>[
          if (existing != null) ('remove', l.metalsAlertRemove),
          ('save', l.save),
        ],
      ),
    );
    switch (result) {
      case ('remove', _):
        await ref.read(metalAlertsProvider.notifier).set(m, null, currency);
      case ('save', final String text):
        final double? target = AmountInput.parse(text);
        if (target != null && target > 0) {
          await ref.read(metalAlertsProvider.notifier).set(m, target, currency,
              current: now?.currency == currency ? now!.perGram : null);
        }
      default:
    }
  }

  Future<void> _setPrice(
      BuildContext context, WidgetRef ref, Metal m, MetalPrice? now) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final (String, String)? result = await showDialog<(String, String)>(
      context: context,
      builder: (BuildContext ctx) => _AmountDialog(
        title: l.metalsSetPrice,
        hint: l.metalsSetPriceHint(MetalText.name(l, m)),
        label:
            '${MetalText.name(l, m)} · ${MetalText.purity(l, m, m == Metal.gold ? 24 : 999)}',
        currency: currency,
        initial: now?.source == MetalPriceSource.mine
            ? AmountInput.text(now!.perGram)
            : '',
        actions: <(String, String)>[
          ('market', l.metalsUseMarket),
          ('save', l.save),
        ],
      ),
    );
    switch (result) {
      case ('market', _):
        await ref.read(myMetalPricesProvider.notifier).set(m, null, currency);
      case ('save', final String text):
        await ref
            .read(myMetalPricesProvider.notifier)
            .set(m, AmountInput.parse(text), currency);
      default:
    }
  }
}

/// Asks for an amount per gram. Pops with the chosen action and the text
/// typed; the text box lives and dies with the dialog.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.hint,
    required this.label,
    required this.currency,
    required this.initial,
    required this.actions,
    this.helper,
    this.note,
  });

  final String title;
  final String hint;
  final String label;
  final String currency;
  final String initial;
  final List<(String, String)> actions;
  final String? helper;
  final String? note;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.hint),
          const SizedBox(height: DsSpacing.md),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: widget.helper,
              suffixText: widget.currency,
            ),
          ),
          if (widget.note != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Text(widget.note!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textFaint)),
          ],
        ],
      ),
      actions: <Widget>[
        for (final (String key, String label) in widget.actions)
          TextButton(
              onPressed: () => Navigator.of(context).pop((key, _ctrl.text)),
              child: Text(label)),
      ],
    );
  }
}

/// Platinum and palladium: industrial metals, folded under their heading so
/// gold and silver stay in front. Open when the user keeps some or watches
/// their price.
class _IndustrialFold extends StatefulWidget {
  const _IndustrialFold({required this.open, required this.children});
  final bool open;
  final List<Widget> children;

  @override
  State<_IndustrialFold> createState() => _IndustrialFoldState();
}

class _IndustrialFoldState extends State<_IndustrialFold> {
  late bool _open = widget.open;

  @override
  void didUpdateWidget(_IndustrialFold old) {
    super.didUpdateWidget(old);
    // Holdings and alerts load a moment after the page: open then too.
    if (widget.open && !old.open) _open = true;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: c.surfaceMuted,
          borderRadius: DsRadius.brMd,
          child: InkWell(
            borderRadius: DsRadius.brMd,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.md, vertical: DsSpacing.sm),
              child: Row(
                children: <Widget>[
                  const MetalBar(metal: Metal.platinum, width: 34),
                  const SizedBox(width: 2),
                  const MetalBar(metal: Metal.palladium, width: 34),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.tabIndustrialMetals, style: t.titleSmall),
                        Text(
                          '${MetalText.name(l, Metal.platinum)} · ${MetalText.name(l, Metal.palladium)}',
                          style: t.labelSmall?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: DsSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
