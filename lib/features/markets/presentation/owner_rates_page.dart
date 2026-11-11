import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/data/owner_parallel_repository.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Where the app's owner types the day's parallel ("Square") rates of a
/// country. Reached from Settings by admin accounts only; the server refuses
/// anyone else whatever the app shows.
class OwnerRatesPage extends ConsumerStatefulWidget {
  const OwnerRatesPage({super.key, required this.country});

  final CountryMarket country;

  @override
  ConsumerState<OwnerRatesPage> createState() => _OwnerRatesPageState();
}

class _OwnerRatesPageState extends ConsumerState<OwnerRatesPage> {
  final Map<String, TextEditingController> _buy =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _sell =
      <String, TextEditingController>{};

  /// What the server held when the page opened, to save only what changed.
  final Map<String, (double?, double?)> _stored =
      <String, (double?, double?)>{};
  DateTime? _lastSet;
  bool _loading = true;
  bool _saving = false;
  final Set<String> _invalid = <String>{};

  @override
  void initState() {
    super.initState();
    for (final String cur in widget.country.pairs) {
      _buy[cur] = TextEditingController();
      _sell[cur] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final TextEditingController c in _buy.values) {
      c.dispose();
    }
    for (final TextEditingController c in _sell.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    List<FxQuote> quotes = const <FxQuote>[];
    try {
      final List<dynamic> rows = await ref
          .read(ownerRatesServiceProvider)
          .fetch(widget.country.country);
      quotes = OwnerParallelRepository.parse(rows, widget.country, '');
    } catch (_) {
      // Unreachable: the form opens empty and saving will say so.
    }
    if (!mounted) return;
    setState(() {
      for (final FxQuote q in quotes) {
        _stored[q.currency] = (q.buy, q.sell);
        _buy[q.currency]?.text = _show(q.buy);
        _sell[q.currency]?.text = _show(q.sell);
        if (_lastSet == null || q.updatedAt.isAfter(_lastSet!)) {
          _lastSet = q.updatedAt;
        }
      }
      _loading = false;
    });
  }

  static String _show(double? v) {
    if (v == null) return '';
    final String s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  /// Empty reads as "none"; anything else must be a number above zero.
  static (bool ok, double? value) _read(String text) {
    final String t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return (true, null);
    final double? v = double.tryParse(t);
    if (v == null || !v.isFinite || v <= 0 || v >= 1e9) return (false, null);
    return (true, v);
  }

  Future<void> _save() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Map<String, (double?, double?)> next =
        <String, (double?, double?)>{};
    final Set<String> bad = <String>{};
    for (final String cur in widget.country.pairs) {
      final (bool okB, double? b) = _read(_buy[cur]!.text);
      final (bool okS, double? s) = _read(_sell[cur]!.text);
      if (!okB || !okS) {
        bad.add(cur);
      } else {
        next[cur] = (b, s);
      }
    }
    setState(() {
      _invalid
        ..clear()
        ..addAll(bad);
    });
    if (bad.isNotEmpty) return;

    setState(() => _saving = true);
    bool ok = true;
    try {
      for (final MapEntry<String, (double?, double?)> e in next.entries) {
        if (_stored[e.key] == e.value) continue;
        // Nothing stored and nothing typed: nothing to remove.
        if (!_stored.containsKey(e.key) &&
            e.value.$1 == null &&
            e.value.$2 == null) {
          continue;
        }
        await ref.read(ownerRatesServiceProvider).setRate(
            widget.country.country, e.key,
            buy: e.value.$1, sell: e.value.$2);
        if (e.value.$1 == null && e.value.$2 == null) {
          _stored.remove(e.key);
        } else {
          _stored[e.key] = e.value;
        }
      }
    } catch (_) {
      ok = false;
    }
    if (ok) {
      // This device shows the new figures at once, not after the cache ages.
      await ref
          .read(rateCacheProvider)
          .write(OwnerParallelRepository.cacheKey(widget.country.country), null);
      ref.invalidate(parallelQuotesProvider(widget.country.country));
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _lastSet = DateTime.now();
    });
    messenger.showSnackBar(
        SnackBar(content: Text(ok ? l.ownerRatesSaved : l.ownerRatesFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final TextTheme t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.ownerRatesTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(DsSpacing.md),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CurrencyFlag.country(widget.country.country, width: 26),
                      const SizedBox(width: DsSpacing.sm),
                      Text(
                          ar
                              ? widget.country.nameAr
                              : widget.country.nameEn,
                          style: t.titleMedium),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  Text(l.ownerRatesHint,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                  if (_lastSet != null) ...<Widget>[
                    const SizedBox(height: DsSpacing.xs),
                    Text(l.ownerRatesLastSet(_when(_lastSet!)),
                        style: t.labelSmall?.copyWith(color: c.textFaint)),
                  ],
                  const SizedBox(height: DsSpacing.md),
                  GlassCard(
                    child: Column(
                      children: <Widget>[
                        for (final String cur in widget.country.pairs)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: DsSpacing.xs),
                            child: Row(
                              children: <Widget>[
                                CurrencyFlag.code(cur, width: 20),
                                const SizedBox(width: DsSpacing.sm),
                                SizedBox(
                                    width: 44,
                                    child: Text(cur, style: t.titleSmall)),
                                Expanded(
                                    child: _field(
                                        key: ValueKey<String>('buy-$cur'),
                                        controller: _buy[cur]!,
                                        label: l.marketParallelBuy,
                                        bad: _invalid.contains(cur),
                                        error: l.ownerRatesInvalid)),
                                const SizedBox(width: DsSpacing.sm),
                                Expanded(
                                    child: _field(
                                        key: ValueKey<String>('sell-$cur'),
                                        controller: _sell[cur]!,
                                        label: l.marketParallelSell,
                                        bad: _invalid.contains(cur),
                                        error: l.ownerRatesInvalid)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsSpacing.lg),
                  DsButton(
                    label: l.save,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required bool bad,
    required String error,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        const LatinDigitsFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        errorText: bad ? error : null,
      ),
    );
  }

  static String _when(DateTime dt) {
    final DateTime d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
