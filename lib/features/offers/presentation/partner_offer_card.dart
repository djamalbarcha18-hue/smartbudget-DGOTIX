import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/offers/application/offers_controller.dart';
import 'package:smartbudget/features/offers/domain/partner_offer.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

IconData offerIcon(OfferKind k) => switch (k) {
      OfferKind.esim => SbIcons.tripConnectivity,
      OfferKind.hotel => SbIcons.tripStay,
      OfferKind.airline => SbIcons.tripFlights,
      OfferKind.transport => SbIcons.tripTransport,
      OfferKind.restaurant => SbIcons.tripFood,
      OfferKind.insurance => SbIcons.tripEmergency,
      OfferKind.agency => SbIcons.tripPackage,
      OfferKind.activity => SbIcons.tripActivities,
    };

/// The one offer of [slot] for [trip], if any (nothing for a paying Pro
/// subscriber, after the trip, or once hidden).
class PartnerOfferSlot extends ConsumerWidget {
  const PartnerOfferSlot(
      {super.key, required this.slot, required this.trip, this.report});
  final OfferSlot slot;
  final Trip trip;
  final TripReport? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(offersOnProvider)) return const SizedBox.shrink();
    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final bool pro = ref.watch(paidProProvider);
    final PartnerOffer? offer = OfferMatcher.pick(
      offers: ref.watch(partnerOffersProvider).valueOrNull ??
          const <PartnerOffer>[],
      slot: slot,
      trip: trip,
      place: catalog.byText(trip.destination),
      now: AppClock.now(),
      hidden: ref.watch(hiddenOffersProvider),
      report: report,
      pro: pro,
      home: ref.watch(homeCountryProvider),
    );
    if (offer == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.md),
      child: PartnerOfferCard(
        offer: offer,
        pro: pro,
        place: catalog.display(trip.destination, appLangOf(context)),
        onHide: () => ref.read(hiddenOffersProvider.notifier).hide(offer.id),
      ),
    );
  }
}

/// A partner's offer, quiet and clearly marked as one: what, for which
/// trip, a link, and a way to hide it.
class PartnerOfferCard extends StatelessWidget {
  const PartnerOfferCard(
      {super.key,
      required this.offer,
      required this.place,
      required this.onHide,
      this.pro = false});
  final PartnerOffer offer;

  /// A Pro subscriber's booking suggestion (with its perk), not an ad.
  final bool pro;
  final String place;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String lang = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DsSpacing.md, DsSpacing.sm, DsSpacing.xs, DsSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Icon(offerIcon(offer.kind), size: 22, color: c.brand),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Always said: this is a partner's offer, and why it's here.
                Text(
                    '${pro ? l.offerProPick : l.offerSponsored} · ${l.offerFor(place)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
                const SizedBox(height: 2),
                Text(PartnerOffer.text(offer.title, lang),
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(PartnerOffer.text(offer.body, lang),
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                // On the free plan, the partner's Pro perk as a small locked
                // line: one tap to the plans (what pays for the app).
                if (!pro && offer.perk.isNotEmpty)
                  InkWell(
                    onTap: () => context.go('/plans'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.lock_outline_rounded,
                              size: 13, color: c.textFaint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                l.offerProPerk(
                                    PartnerOffer.text(offer.perk, lang)),
                                style:
                                    t.labelSmall?.copyWith(color: c.textMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (pro && offer.perk.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.workspace_premium_rounded,
                            size: 14, color: c.warning),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(PartnerOffer.text(offer.perk, lang),
                              style: t.labelMedium?.copyWith(
                                  color: c.brand, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact),
                      onPressed: () => openOffer(context, offer),
                      child: Text(l.offerOpen),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    // Who you deal with, said where you tap.
                    Flexible(
                      child: Text(l.offerBookWithPartner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelSmall?.copyWith(color: c.textFaint)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.offerHide,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: c.textFaint),
            onPressed: onHide,
          ),
        ],
      ),
    );
  }
}

/// Settings, Pro only: booking suggestions from partners on or off.
class ProSuggestionsSetting extends ConsumerWidget {
  const ProSuggestionsSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: ref.watch(proSuggestionsProvider),
      onChanged: (bool v) => ref.read(proSuggestionsProvider.notifier).set(v),
      title: Text(l.proSuggestionsShow, style: t.bodyMedium),
      subtitle: Text(l.proSuggestionsHint,
          style: t.bodySmall?.copyWith(color: c.textFaint)),
    );
  }
}

/// Opens the partner's page; the first time, says plainly that booking and
/// payment are with the partner, at the user's own responsibility, and not
/// part of SmartBudget or its Pro plan.
Future<void> openOffer(BuildContext context, PartnerOffer offer) async {
  const String key = 'sb_offers_notice_seen';
  bool seen = false;
  try {
    seen = (await SharedPreferences.getInstance()).getBool(key) ?? false;
  } catch (_) {}
  if (!seen) {
    if (!context.mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.offerNoticeTitle),
        content: Text(l.offerNoticeBody(
            offer.partner.isEmpty ? l.offerThePartner : offer.partner)),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.offerNoticeContinue)),
        ],
      ),
    );
    if (go != true) return;
    try {
      await (await SharedPreferences.getInstance()).setBool(key, true);
    } catch (_) {}
  }
  await launchUrl(offer.link(), mode: LaunchMode.externalApplication);
}
