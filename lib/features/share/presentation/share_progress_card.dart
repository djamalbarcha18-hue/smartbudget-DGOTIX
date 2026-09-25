import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/share/domain/share_highlight.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The shareable "My progress" card. Fixed brand colours (not the theme) so the
/// exported image looks the same everywhere. 4:5 — fits feeds, stories and
/// chats; saved at 1080×1350.
class ShareProgressCard extends StatelessWidget {
  const ShareProgressCard({
    super.key,
    required this.highlight,
    required this.qrSvg,
  });

  final ShareHighlight highlight;
  final String qrSvg;

  static const double width = 300;
  static const double height = 375;

  /// Pixel ratio that exports the card at 1080 px wide.
  static const double exportPixelRatio = 1080 / width;

  static const Color _white = Colors.white;
  static const Color _soft = Color(0xCCFFFFFF);

  static String statusLabel(AppLocalizations l, HealthStatus s) => switch (s) {
        HealthStatus.excellent => l.healthStatusExcellent,
        HealthStatus.veryGood => l.healthStatusVeryGood,
        HealthStatus.good => l.healthStatusGood,
        HealthStatus.fair => l.healthStatusFair,
        HealthStatus.needsWork => l.healthStatusNeedsWork,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final ShareHighlight h = highlight;

    final (IconData icon, String? big, String? unit, String label) =
        switch (h.kind) {
      HighlightKind.goals => (
          Icons.emoji_events_rounded,
          '${h.goalsCompleted}',
          null,
          l.shareCardGoalsLabel(h.goalsCompleted),
        ),
      HighlightKind.health => (
          Icons.monitor_heart_rounded,
          '${h.healthScore}',
          '/100',
          l.shareCardHealthLabel(statusLabel(l, h.healthStatus!)),
        ),
      HighlightKind.savings => (
          Icons.savings_rounded,
          '${h.savingsPct}',
          '%',
          l.shareCardSavingsLabel,
        ),
      HighlightKind.journey => (
          Icons.rocket_launch_rounded,
          null,
          null,
          l.shareCardJourneyLabel,
        ),
    };

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0A1633), Color(0xFF0F4C9E), Color(0xFF1680F7)],
          stops: <double>[0, 0.6, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Brand lockup.
          Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/brand/dgotix-logo-mono.svg',
                height: 14,
                colorFilter: const ColorFilter.mode(_white, BlendMode.srcIn),
              ),
              const Spacer(),
              Text(AppConfig.appName,
                  style: t.labelMedium?.copyWith(
                      color: _white, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _white, size: 24),
          ),
          const SizedBox(height: 12),
          if (big != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(big,
                      style: t.displayMedium?.copyWith(
                          color: _white,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  if (unit != null)
                    Text(unit,
                        style: t.titleLarge?.copyWith(
                            color: _soft, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Text(l.shareCardJourneyTitle,
                style: t.headlineMedium?.copyWith(
                    color: _white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(label,
              style: t.titleSmall?.copyWith(color: _soft, height: 1.3)),
          if (h.extras.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final HighlightKind k in h.extras)
                  _Chip(switch (k) {
                    HighlightKind.health => l.shareChipHealth(h.healthScore!),
                    HighlightKind.savings => l.shareChipSavings(h.savingsPct!),
                    HighlightKind.goals => l.shareChipGoals(h.goalsCompleted),
                    HighlightKind.journey => '',
                  }),
              ],
            ),
          ],
          const Spacer(),
          // Call to action + QR back to the platform.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      h.kind == HighlightKind.health
                          ? l.shareCardCtaHealth
                          : l.shareCardCta,
                      style: t.titleSmall?.copyWith(
                          color: _white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(AppConfig.tagline,
                        style: t.labelSmall?.copyWith(color: _soft)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.string(qrSvg, width: 62, height: 62),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
