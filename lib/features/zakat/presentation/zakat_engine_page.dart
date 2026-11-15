import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_date_picker.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/presentation/metal_text.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/application/zakat_history_controller.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_record.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';
import 'package:smartbudget/features/zakat/domain/zakat_assembler.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_page.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_pattern.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The zakat screen: the country engine where the user's market has a
/// profile (Algeria today), the earlier calculator everywhere else.
class ZakatScreen extends ConsumerWidget {
  const ZakatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ZakatProfile? profile = ref.watch(zakatMarketProvider);
    return ZakatPatternBackground(
      child: profile == null ? const ZakatPage() : const ZakatEnginePage(),
    );
  }
}

/// Three parts, the answer first: the result, what you own, then the nisab
/// and hawl. Everything is read from the app; the user only adds what the
/// app can't know.
class ZakatEnginePage extends ConsumerStatefulWidget {
  const ZakatEnginePage({super.key});

  @override
  ConsumerState<ZakatEnginePage> createState() => _ZakatEnginePageState();
}

class _ZakatEnginePageState extends ConsumerState<ZakatEnginePage> {
  final TextEditingController _gold = TextEditingController();
  final TextEditingController _silver = TextEditingController();
  final TextEditingController _cash = TextEditingController();
  bool _edited = false;

  static const String _cashKey = 'manual:cash';

  @override
  void initState() {
    super.initState();
    _fill(ref.read(zakatSettingsProvider));
  }

  @override
  void dispose() {
    _gold.dispose();
    _silver.dispose();
    _cash.dispose();
    super.dispose();
  }

  String get _currency =>
      ref.read(zakatMarketProvider)?.currency ?? 'DZD';

  void _fill(ZakatSettings s) {
    String text(int? minor, String? cur) => minor == null || cur == null
        ? ''
        : AmountInput.text(Money(minor, cur).asDouble);
    _gold.text = text(s.goldPerPureGramMinor, s.priceCurrency);
    _silver.text = text(s.silverPerPureGramMinor, s.priceCurrency);
    final ZakatManual? cash =
        s.manual.where((ZakatManual m) => m.key == _cashKey).firstOrNull;
    _cash.text = text(cash?.amountMinor, cash?.currency);
  }

  ZakatSettings get _settings => ref.read(zakatSettingsProvider);

  Future<void> _save(ZakatSettings next) =>
      ref.read(zakatSettingsProvider.notifier).update(next);

  int? _minor(TextEditingController c) {
    final double? v = AmountInput.parse(c.text);
    if (v == null || v <= 0) return null;
    return Money.fromDouble(v, _currency).minorUnits;
  }

  Future<void> _savePrices() {
    _edited = true;
    final int? gold = _minor(_gold);
    final int? silver = _minor(_silver);
    return _save(_settings.copyWith(
      goldPerPureGramMinor: gold,
      clearGoldPrice: gold == null,
      silverPerPureGramMinor: silver,
      clearSilverPrice: silver == null,
      priceCurrency: _currency,
      pricesAsOf: AppClock.now(),
    ));
  }

  Future<void> _saveCash() {
    _edited = true;
    final int? cash = _minor(_cash);
    final List<ZakatManual> manual = <ZakatManual>[
      for (final ZakatManual m in _settings.manual)
        if (m.key != _cashKey) m,
      if (cash != null)
        ZakatManual(
            key: _cashKey,
            kind: ManualKind.cash,
            currency: _currency,
            amountMinor: cash),
    ];
    return _save(_settings.copyWith(manual: manual));
  }

  Future<void> _confirm() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState? m = ScaffoldMessenger.maybeOf(context);
    final ZakatRecord? r =
        await ref.read(zakatHistoryProvider.notifier).confirm();
    if (r != null) {
      m?.showSnackBar(SnackBar(content: Text(l.zkConfirmed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    ref.listen<ZakatSettings>(zakatSettingsProvider,
        (ZakatSettings? _, ZakatSettings next) {
      if (!_edited) _fill(next);
    });
    final ZakatAssembly? a = ref.watch(zakatAssemblyProvider);
    final ZakatOutcome? o = ref.watch(zakatOutcomeProvider);
    final ZakatSettings s = ref.watch(zakatSettingsProvider);
    if (a == null || o == null) return const SizedBox.shrink();
    final _Labels names = _Labels.of(ref, l);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.navZakat, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.xs),
          _MethodChip(rules: o.rules),
          const SizedBox(height: DsSpacing.lg),
          if (s.fromLegacy) ...<Widget>[
            _Notice(
              text: l.zkMethodChanged,
              action: l.zkGotIt,
              onAction: () => _save(_settings.copyWith()),
            ),
            const SizedBox(height: DsSpacing.md),
          ],
          _ResultCard(outcome: o, notes: a.notes, onConfirm: _confirm),
          const SizedBox(height: DsSpacing.lg),
          _OwnCard(
            outcome: o,
            settings: s,
            names: names,
            cash: _cash,
            onSaveCash: _saveCash,
            onSave: (ZakatSettings next) {
              _edited = true;
              _save(next);
            },
          ),
          const SizedBox(height: DsSpacing.lg),
          _HawlCard(
            outcome: o,
            settings: s,
            gold: _gold,
            silver: _silver,
            currency: o.currency,
            onSavePrices: _savePrices,
            onSave: (ZakatSettings next) {
              _edited = true;
              _save(next);
            },
          ),
          const SizedBox(height: DsSpacing.lg),
          _HistoryCard(names: names),
          const SizedBox(height: DsSpacing.lg),
          Text(l.zkNotFatwa, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Display names for the engine's keys ("wallet:general" → "General").
class _Labels {
  _Labels(this.l, this._byKey);
  final AppLocalizations l;
  final Map<String, String> _byKey;

  static _Labels of(WidgetRef ref, AppLocalizations l) {
    final Map<String, String> m = <String, String>{};
    for (final Wallet w in ref.watch(walletsProvider)) {
      m['wallet:${w.id}'] = walletName(l, w);
    }
    for (final Goal g in ref.watch(goalsProvider).valueOrNull ?? const <Goal>[]) {
      m['goal:${g.id}'] = g.name;
      m['project:${g.id}'] = g.name;
    }
    for (final MetalHolding h
        in ref.watch(metalHoldingsProvider).valueOrNull ?? const <MetalHolding>[]) {
      final String what =
          '${MetalText.name(l, h.metal)} ${MetalText.purity(l, h.metal, h.purity)} · ${MetalText.grams(l, h.grams)}';
      m['metal:${h.id}'] = h.name.isEmpty ? what : '${h.name} · $what';
    }
    for (final Debt d in ref.watch(debtsProvider).valueOrNull ?? const <Debt>[]) {
      m['debt:${d.id}'] = d.party;
    }
    return _Labels(l, m);
  }

  String of(String key) => switch (key) {
        'acquired-during-hawl' => l.zkNoteAcquired,
        'manual:cash' || 'legacy:cash' => l.zkCashOutside,
        'legacy:metals' => l.zakatMetalsHoldings,
        'legacy:investments' => l.zakatInvestments,
        _ => _byKey[key] ?? key.split(':').last,
      };
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.rules});
  final ZakatRules rules;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String school = switch (rules.school) {
      ZakatSchool.maliki => l.zkSchoolMaliki,
      ZakatSchool.hanafi => l.zkSchoolHanafi,
      ZakatSchool.custom => rules.version,
    };
    return Row(
      children: <Widget>[
        Icon(Icons.menu_book_outlined, size: 16, color: c.brand),
        const SizedBox(width: DsSpacing.xs),
        Flexible(
          child: Text(school,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: c.brand)),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction, this.color});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color tint = color ?? c.saving;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: DsRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(text, style: Theme.of(context).textTheme.bodySmall),
          if (action != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: onAction, child: Text(action!)),
            ),
        ],
      ),
    );
  }
}

String _issueText(AppLocalizations l, ZakatIssue i, AppLang lang) =>
    switch (i.code) {
      ZakatIssueCode.unknownCurrency ||
      ZakatIssueCode.missingRate =>
        l.zkIssueRate(i.ref ?? ''),
      ZakatIssueCode.missingGoldPrice => l.zkIssueGoldPrice,
      ZakatIssueCode.missingSilverPrice => l.zkIssueSilverPrice,
      ZakatIssueCode.missingOfficialNisab => l.zkIssueNisab,
      ZakatIssueCode.rulesNotApproved => l.zkIssueRules,
      ZakatIssueCode.hawlStartMissing => l.zkIssueHawlStart,
      ZakatIssueCode.beforeHawlEnd => l.zkIssueBeforeEnd,
      ZakatIssueCode.historyMissing => l.zkIssueHistory,
      ZakatIssueCode.officialNisabStale => l.zkIssueStale,
      ZakatIssueCode.metalUseUnspecified => l.zkIssueMetalUse,
      ZakatIssueCode.manualMetalMayDuplicate => l.zkIssueManualMetal,
      ZakatIssueCode.retainedSharesFullValue => l.zkIssueShares,
      ZakatIssueCode.investmentKindUnspecified => l.zkIssueInvestmentKind,
      ZakatIssueCode.duplicateSource => l.zkIssueDuplicate,
      ZakatIssueCode.nisabNotMetAtHawlStart => l.zkIssueStartBelow,
      ZakatIssueCode.droppedBelowNisab => l.zkIssueDropped(i.at == null
          ? ''
          : HijriDate.fromGregorian(i.at!).format(lang: lang)),
    };

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.outcome, required this.notes, required this.onConfirm});
  final ZakatOutcome outcome;
  final List<AssemblyNote> notes;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final AppLang lang = appLangOf(context);
    final ZakatOutcome o = outcome;
    final TextTheme t = Theme.of(context).textTheme;
    Money m(int minor) => Money(minor, o.currency);

    final (String, Color) status = o.status == ZakatStatus.incomplete
        ? (l.zkStatusIncomplete, c.warning)
        : o.obligatoryNow
            ? (l.zakatObligatory, c.income)
            : !o.nisabMet
                ? (l.zakatNotDue, c.textMuted)
                : (l.zakatHawlPending, c.saving);
    final ZakatNisab? n = o.nisab;
    final List<ZakatIssue> issues = o.issues
        .where((ZakatIssue i) => i.code != ZakatIssueCode.duplicateSource)
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(status.$1,
                    style: t.titleMedium?.copyWith(color: status.$2)),
              ),
              if (o.status == ZakatStatus.provisional)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.saving.withValues(alpha: 0.14),
                    borderRadius: DsRadius.brMd,
                  ),
                  child: Text(l.zkEstimate,
                      style: t.labelSmall?.copyWith(color: c.saving)),
                ),
            ],
          ),
          if (o.status != ZakatStatus.incomplete) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Text(l.zakatDue, style: t.labelSmall),
            Text(MoneyFormatter.format(m(o.dueMinor)),
                key: const Key('zakat-due'),
                style: t.headlineMedium?.copyWith(
                    color: o.obligatoryNow ? c.income : c.textPrimary,
                    fontWeight: FontWeight.w800)),
          ],
          const Divider(height: DsSpacing.xl),
          _kv(context, l.zakatNetWealth, MoneyFormatter.format(m(o.baseMinor)),
              strong: true),
          if (n != null)
            _kv(
                context,
                n.basis == NisabBasis.official && n.hijriYear != null
                    ? l.zkNisabOfficial('${n.hijriYear}')
                    : l.zakatNisab,
                MoneyFormatter.format(m(n.amountMinor))),
          if (issues.isNotEmpty || notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            for (final ZakatIssue i in issues)
              _bullet(context, _issueText(l, i, lang),
                  i.blocking ? c.warning : c.textMuted),
            for (final AssemblyNote a in notes)
              if (a.code == AssemblyNoteCode.legacyMetalsSuperseded)
                _bullet(context, l.zkLegacyMetals, c.textMuted)
              else if (a.code == AssemblyNoteCode.laterEntriesIgnored)
                _bullet(context, l.zkLaterEntries, c.textMuted),
          ],
          const SizedBox(height: DsSpacing.md),
          FilledButton.icon(
            key: const Key('zakat-confirm'),
            onPressed: o.status == ZakatStatus.incomplete ? null : onConfirm,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: Text(l.zkConfirm),
          ),
        ],
      ),
    );
  }
}

Widget _bullet(BuildContext context, String text, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 14, color: color),
          ),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color)),
          ),
        ],
      ),
    );

Widget _kv(BuildContext context, String k, String v,
    {bool strong = false, String? sub}) {
  final DsColors c = context.dsColors;
  final TextTheme t = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(k,
                  style: strong
                      ? t.titleSmall
                      : t.bodyMedium?.copyWith(color: c.textMuted)),
              if (sub != null)
                Text(sub, style: t.labelSmall?.copyWith(color: c.textFaint)),
            ],
          ),
        ),
        const SizedBox(width: DsSpacing.sm),
        Text(v,
            style: t.titleSmall?.copyWith(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
      ],
    ),
  );
}

String _noteText(AppLocalizations l, LineNote n) => switch (n) {
      LineNote.counted || LineNote.zakatablePart => '',
      LineNote.insideWallets => l.zkNoteInsideWallets,
      LineNote.acquiredDuringHawl => '',
      LineNote.adornmentExempt => l.zkNoteWorn,
      LineNote.notZakatableMetal => l.zkNoteNotZakatable,
      LineNote.fullValueFallback => l.zkIssueShares,
      LineNote.rentalPropertyExcluded => l.zkNoteRental,
      LineNote.doubtfulReceivable => l.zkNoteDoubtful,
      LineNote.untilReceived => l.zkNoteUntilReceived,
      LineNote.notDeducted => l.zkNoteNotDeducted,
      LineNote.duplicate => l.zkIssueDuplicate,
      LineNote.unvalued => l.zkNoteUnvalued,
    };

/// Step 1: what you own, read from the app, with the few choices the app
/// can't make for the user.
class _OwnCard extends StatelessWidget {
  const _OwnCard({
    required this.outcome,
    required this.settings,
    required this.names,
    required this.cash,
    required this.onSaveCash,
    required this.onSave,
  });

  final ZakatOutcome outcome;
  final ZakatSettings settings;
  final _Labels names;
  final TextEditingController cash;
  final VoidCallback onSaveCash;
  final ValueChanged<ZakatSettings> onSave;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;

    String title(ZakatSection s, String key) => switch (s) {
          ZakatSection.cash => key.startsWith('wallet:') ||
                  key == 'acquired-during-hawl'
              ? l.zkSecWallets
              : l.sectionGoals,
          ZakatSection.metal => l.zkSecMetals,
          ZakatSection.investment => l.zakatInvestments,
          ZakatSection.receivable => l.zkSecLent,
          ZakatSection.manual => l.zkSecManual,
          ZakatSection.debt => l.zkSecDebts,
        };

    final Map<String, List<ZakatLine>> groups = <String, List<ZakatLine>>{};
    for (final ZakatLine x in outcome.lines) {
      (groups[title(x.section, x.key)] ??= <ZakatLine>[]).add(x);
    }

    Widget line(ZakatLine x) {
      final String note = _noteText(l, x.note);
      final Money shown = x.counted
          ? Money(x.valueMinor, outcome.currency)
          : Money(x.originalMinor, x.currency);
      final String value = x.section == ZakatSection.debt && x.counted
          ? '− ${MoneyFormatter.format(shown)}'
          : MoneyFormatter.format(shown);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _kv(context, names.of(x.key), value,
              sub: note.isEmpty ? null : note),
          ..._controls(context, l, x),
        ],
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('1 · ${l.zkStepOwn}', style: t.titleMedium),
          for (final MapEntry<String, List<ZakatLine>> g in groups.entries) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            Text(g.key,
                style: t.labelMedium?.copyWith(color: c.textMuted)),
            for (final ZakatLine x in g.value) line(x),
          ],
          const SizedBox(height: DsSpacing.lg),
          DsTextField(
            label: l.zkCashOutside,
            controller: cash,
            suffixText: outcome.currency,
            prefixIcon: Icons.payments_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => onSaveCash(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onSaveCash, child: Text(l.save)),
          ),
        ],
      ),
    );
  }

  List<Widget> _controls(BuildContext context, AppLocalizations l, ZakatLine x) {
    final String id = x.key.split(':').last;
    if (x.key.startsWith('goal:') || x.key.startsWith('project:')) {
      final bool outside = settings.goalsHeldOutside.contains(id);
      return <Widget>[
        SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l.zkHeldOutside,
              style: Theme.of(context).textTheme.bodySmall),
          value: outside,
          onChanged: (bool v) => onSave(settings.copyWith(
              goalsHeldOutside: <String>{
            ...settings.goalsHeldOutside.where((String g) => g != id),
            if (v) id,
          })),
        ),
      ];
    }
    if (x.key.startsWith('metal:')) {
      final MetalUse use = settings.metalUses[id] ?? MetalUse.unspecified;
      ChoiceChip chip(String label, MetalUse u) => ChoiceChip(
            label: Text(label),
            selected: use == u,
            onSelected: (_) => onSave(settings.copyWith(
                metalUses: <String, MetalUse>{...settings.metalUses, id: u})),
          );
      return <Widget>[
        Wrap(spacing: DsSpacing.sm, children: <Widget>[
          chip(l.zkUseSavings, MetalUse.savings),
          chip(l.zkUseWorn, MetalUse.adornment),
          chip(l.zkUseTrade, MetalUse.trade),
        ]),
        const SizedBox(height: DsSpacing.xs),
      ];
    }
    if (x.section == ZakatSection.receivable) {
      final bool doubtful = settings.doubtfulReceivables.contains(id);
      return <Widget>[
        CheckboxListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l.zkDoubtful,
              style: Theme.of(context).textTheme.bodySmall),
          value: doubtful,
          onChanged: (bool? v) => onSave(settings.copyWith(
              doubtfulReceivables: <String>{
            ...settings.doubtfulReceivables.where((String d) => d != id),
            if (v ?? false) id,
          })),
        ),
      ];
    }
    if (x.section == ZakatSection.investment) {
      final ZakatInvestment? inv = settings.investments
          .where((ZakatInvestment i) => i.key == x.key)
          .firstOrNull;
      if (inv == null) return const <Widget>[];
      return <Widget>[
        DropdownButton<InvestmentKind>(
          isExpanded: true,
          value: inv.kind == InvestmentKind.unspecified ? null : inv.kind,
          hint: Text(l.zkIssueInvestmentKind,
              style: Theme.of(context).textTheme.bodySmall),
          items: <DropdownMenuItem<InvestmentKind>>[
            DropdownMenuItem<InvestmentKind>(
                value: InvestmentKind.tradingShares,
                child: Text(l.zkKindTrading)),
            DropdownMenuItem<InvestmentKind>(
                value: InvestmentKind.retainedShares,
                child: Text(l.zkKindRetained)),
            DropdownMenuItem<InvestmentKind>(
                value: InvestmentKind.tradeGoods,
                child: Text(l.zkKindTradeGoods)),
            DropdownMenuItem<InvestmentKind>(
                value: InvestmentKind.rentalProperty,
                child: Text(l.zkKindRental)),
          ],
          onChanged: (InvestmentKind? k) {
            if (k == null) return;
            onSave(settings.copyWith(investments: <ZakatInvestment>[
              for (final ZakatInvestment i in settings.investments)
                i.key == inv.key
                    ? ZakatInvestment(
                        key: i.key,
                        kind: k,
                        currency: i.currency,
                        marketValueMinor: i.marketValueMinor,
                        zakatablePartMinor: i.zakatablePartMinor)
                    : i,
            ]));
          },
        ),
      ];
    }
    if (x.key.startsWith('legacy:') && x.section == ZakatSection.manual) {
      return <Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => onSave(settings.copyWith(manual: <ZakatManual>[
              for (final ZakatManual m in settings.manual)
                if (m.key != x.key) m,
            ])),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(l.delete),
          ),
        ),
      ];
    }
    return const <Widget>[];
  }
}

/// Step 2: the hawl (Hijri year) and the gold and silver prices.
class _HawlCard extends StatelessWidget {
  const _HawlCard({
    required this.outcome,
    required this.settings,
    required this.gold,
    required this.silver,
    required this.currency,
    required this.onSavePrices,
    required this.onSave,
  });

  final ZakatOutcome outcome;
  final ZakatSettings settings;
  final TextEditingController gold;
  final TextEditingController silver;
  final String currency;
  final VoidCallback onSavePrices;
  final ValueChanged<ZakatSettings> onSave;

  Future<void> _pick(BuildContext context) async {
    final DateTime now = AppClock.now();
    final DateTime? picked = await showDsDatePicker(
      context,
      initialDate: settings.hawlStart ?? now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked != null) {
      onSave(settings.copyWith(
          hawlStart: DateTime(picked.year, picked.month, picked.day)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final AppLang lang = appLangOf(context);
    final TextTheme t = Theme.of(context).textTheme;
    final hawl = outcome.hawl;
    String greg(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final DateTime today = AppClock.now();
    final int left = hawl == null
        ? 0
        : DateTime.utc(hawl.end.year, hawl.end.month, hawl.end.day)
            .difference(DateTime.utc(today.year, today.month, today.day))
            .inDays;

    ChoiceChip adjust(String label, int v) => ChoiceChip(
          label: Text(label),
          selected: settings.hawlAdjustDays == v,
          onSelected: (_) => onSave(settings.copyWith(hawlAdjustDays: v)),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('2 · ${l.zkStepHawl}', style: t.titleMedium),
          const SizedBox(height: DsSpacing.xs),
          Text(l.zakatHawlHint, style: t.bodySmall),
          const SizedBox(height: DsSpacing.md),
          if (hawl == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('zakat-hawl-set'),
                onPressed: () => _pick(context),
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(l.zakatHawlSetDate),
              ),
            )
          else ...<Widget>[
            _kv(context, l.zakatHawlStart,
                HijriDate.fromGregorian(hawl.start).format(lang: lang),
                sub: greg(hawl.start)),
            _kv(context, l.zakatHawlDue,
                HijriDate.fromGregorian(hawl.end).format(lang: lang),
                sub: greg(hawl.end)),
            const SizedBox(height: DsSpacing.sm),
            Container(
              padding: const EdgeInsets.all(DsSpacing.sm),
              decoration: BoxDecoration(
                color: (left <= 0 ? c.income : c.saving).withValues(alpha: 0.12),
                borderRadius: DsRadius.brMd,
              ),
              child: Text(
                left <= 0 ? l.zakatHawlComplete : l.zakatHawlRemaining(left),
                style: t.labelLarge
                    ?.copyWith(color: left <= 0 ? c.income : c.saving),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(l.zkMoonAdjust,
                style: t.labelMedium?.copyWith(color: c.textMuted)),
            Wrap(spacing: DsSpacing.sm, children: <Widget>[
              adjust(l.zkDayEarlier, -1),
              adjust(l.zkDaySame, 0),
              adjust(l.zkDayLater, 1),
            ]),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => _pick(context),
                  child: Text(l.zakatHawlSetDate),
                ),
                TextButton(
                  onPressed: () =>
                      onSave(settings.copyWith(clearHawlStart: true)),
                  child: Text(l.delete),
                ),
              ],
            ),
          ],
          const Divider(height: DsSpacing.xl),
          DsTextField(
            label: l.zkGoldPricePure,
            controller: gold,
            suffixText: currency,
            prefixIcon: Icons.circle,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => onSavePrices(),
          ),
          const SizedBox(height: DsSpacing.md),
          DsTextField(
            label: l.zkSilverPricePure,
            controller: silver,
            suffixText: currency,
            prefixIcon: Icons.circle_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => onSavePrices(),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.zkPriceHint, style: t.labelSmall),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onSavePrices, child: Text(l.save)),
          ),
        ],
      ),
    );
  }
}

/// Confirmed calculations, newest first, each shown as it was saved.
class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.names});
  final _Labels names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang lang = appLangOf(context);
    final TextTheme t = Theme.of(context).textTheme;
    final List<ZakatRecord> history = ref.watch(zakatHistoryProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.zkHistory, style: t.titleMedium),
          const SizedBox(height: DsSpacing.xs),
          if (history.isEmpty)
            Text(l.zkHistoryEmpty, style: t.bodySmall)
          else
            for (final ZakatRecord r in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(HijriDate.fromGregorian(r.zakatDate).format(lang: lang)),
                subtitle: Text(l.zkRulesVersion(r.rulesVersion),
                    style: t.labelSmall),
                trailing: Text(
                    MoneyFormatter.format(Money(r.dueMinor, r.currency)),
                    style: t.titleSmall),
                onTap: () => _show(context, r),
              ),
        ],
      ),
    );
  }

  void _show(BuildContext context, ZakatRecord r) {
    final AppLocalizations l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DsSpacing.pageGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l.zkHistory, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: DsSpacing.md),
              for (final ZakatRecordLine x in r.lines)
                if (x.counted)
                  _kv(ctx, names.of(x.key),
                      MoneyFormatter.format(Money(x.valueMinor, r.currency))),
              const Divider(height: DsSpacing.xl),
              _kv(ctx, l.zakatNetWealth,
                  MoneyFormatter.format(Money(r.baseMinor, r.currency)),
                  strong: true),
              _kv(ctx, l.zakatDue,
                  MoneyFormatter.format(Money(r.dueMinor, r.currency)),
                  strong: true),
              _kv(ctx, l.zkRulesVersion(r.rulesVersion), ''),
            ],
          ),
        ),
      ),
    );
  }
}
