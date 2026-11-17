import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/islamic_features.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/sadaqah/presentation/sadaqah_text.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What the dashboard card shows, at most one at a time.
enum SadaqahPromoKind {
  /// "Show Islamic features?" until the user answers (here or in Settings).
  question,

  /// Ramadan: once each Ramadan (Islamic features shown).
  ramadan,

  /// The planner's introduction: once, ever.
  intro,
}

/// When the dashboard introduces the Sadaqah Planner (kept on the device).
abstract final class SadaqahPromo {
  static const String _introKey = 'sb_sadaqah_intro_done';
  static const String _ramadanKey = 'sb_sadaqah_ramadan_seen';

  /// The planner was opened: no introduction needed any more.
  static Future<void> markOpened() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_introKey, true);
    } catch (_) {
      // Non-fatal.
    }
  }

  static Future<SadaqahPromoKind?> current() async {
    if (!IslamicFeatures.chosen.value) return SadaqahPromoKind.question;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final HijriDate h = HijriDate.fromGregorian(DateTime.now());
      if (IslamicFeatures.enabled.value &&
          h.month == 9 &&
          p.getInt(_ramadanKey) != h.year) {
        return SadaqahPromoKind.ramadan;
      }
      if (!(p.getBool(_introKey) ?? false)) return SadaqahPromoKind.intro;
    } catch (_) {
      // Show nothing.
    }
    return null;
  }

  static Future<void> dismiss(SadaqahPromoKind kind) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (kind == SadaqahPromoKind.ramadan) {
        await p.setInt(
            _ramadanKey, HijriDate.fromGregorian(DateTime.now()).year);
      }
      if (kind != SadaqahPromoKind.question) await p.setBool(_introKey, true);
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// Dashboard card: the one-time "Show Islamic features?" question, then the
/// planner's introduction (once) and a Ramadan note (once a Ramadan). An
/// in-app card, never a notification.
class SadaqahHomeCard extends StatefulWidget {
  const SadaqahHomeCard({super.key});

  @override
  State<SadaqahHomeCard> createState() => _SadaqahHomeCardState();
}

class _SadaqahHomeCardState extends State<SadaqahHomeCard> {
  SadaqahPromoKind? _kind;

  @override
  void initState() {
    super.initState();
    _refresh();
    IslamicFeatures.enabled.addListener(_refresh);
    IslamicFeatures.chosen.addListener(_refresh);
  }

  @override
  void dispose() {
    IslamicFeatures.enabled.removeListener(_refresh);
    IslamicFeatures.chosen.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final SadaqahPromoKind? k = await SadaqahPromo.current();
    if (mounted) setState(() => _kind = k);
  }

  Future<void> _close() async {
    final SadaqahPromoKind? k = _kind;
    if (k == null) return;
    setState(() => _kind = null);
    await SadaqahPromo.dismiss(k);
  }

  Future<void> _open() async {
    await _close();
    if (mounted) context.go('/sadaqah');
  }

  void _answer(bool on) {
    HapticFeedback.selectionClick();
    IslamicFeatures.set(on);
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: _kind == null ? const SizedBox(width: double.infinity) : _card(),
      );

  Widget _card() {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final SadaqahText s =
        SadaqahText(l, islamic: IslamicFeatures.enabled.value);
    final SadaqahPromoKind kind = _kind!;

    final (IconData icon, String title, String body) = switch (kind) {
      SadaqahPromoKind.question => (
          Icons.nightlight_round,
          l.islamicFeaturesQuestion,
          l.islamicFeaturesHint,
        ),
      SadaqahPromoKind.ramadan => (
          Icons.nightlight_round,
          l.sadaqahRamadanTitle,
          l.sadaqahRamadanBody,
        ),
      SadaqahPromoKind.intro => (
          Icons.volunteer_activism_outlined,
          s.promoTitle,
          s.promoBody,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.gridGap),
      child: GlassCard(
        onTap: kind == SadaqahPromoKind.question ? null : _open,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: c.brand),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: t.titleSmall),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(body, style: t.bodySmall?.copyWith(color: c.textMuted)),
                  const SizedBox(height: DsSpacing.sm),
                  if (kind == SadaqahPromoKind.question)
                    Wrap(
                      spacing: DsSpacing.sm,
                      runSpacing: DsSpacing.xs,
                      children: <Widget>[
                        FilledButton(
                          // The suggested answer comes first.
                          onPressed: () => _answer(IslamicFeatures.enabled.value),
                          child: Text(IslamicFeatures.enabled.value
                              ? l.islamicFeaturesYes
                              : l.islamicFeaturesNo),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _answer(!IslamicFeatures.enabled.value),
                          child: Text(IslamicFeatures.enabled.value
                              ? l.islamicFeaturesNo
                              : l.islamicFeaturesYes),
                        ),
                      ],
                    )
                  else
                    Text(l.sadaqahPromoOpen,
                        style: t.labelLarge?.copyWith(color: c.brand)),
                ],
              ),
            ),
            if (kind != SadaqahPromoKind.question)
              IconButton(
                tooltip: l.cancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _close,
              ),
          ],
        ),
      ),
    );
  }
}
