import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The icon named in destinations.json.
IconData destinationIcon(String? name) => switch (name) {
      'mosque' => Icons.mosque_outlined,
      'temple' => Icons.temple_buddhist_outlined,
      'city' => Icons.location_city_outlined,
      'tower' || 'skyscraper' => Icons.apartment_outlined,
      'museum' => Icons.museum_outlined,
      'columns' => Icons.account_balance_outlined,
      'church' => Icons.church_outlined,
      'souk' => Icons.storefront_outlined,
      'pyramid' => Icons.change_history_outlined,
      'beach' => Icons.beach_access_outlined,
      'sea' => Icons.sailing_outlined,
      'mountain' => Icons.landscape_outlined,
      _ => Icons.place_outlined,
    };

/// A place's picture, or its icon when it has none (or for a typed place).
class DestinationAvatar extends StatelessWidget {
  const DestinationAvatar({super.key, this.destination, this.size = 40});

  final Destination? destination;
  final double size;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Widget icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.brand.withValues(alpha: 0.14),
        borderRadius: DsRadius.brMd,
      ),
      child: Icon(destinationIcon(destination?.icon),
          color: c.brand, size: size * 0.55),
    );
    final String? image = destination?.image;
    if (image == null) return icon;
    return ClipRRect(
      borderRadius: DsRadius.brMd,
      child: Image.asset(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => icon,
      ),
    );
  }
}

/// "12 – 19 Oct 2026" style, in the app language.
String tripDates(BuildContext context, Trip t) {
  final String locale = Localizations.localeOf(context).toString();
  final DateFormat full = DateFormat.yMMMd(locale);
  if (t.start == t.end) return full.format(t.start);
  final DateFormat short =
      t.start.year == t.end.year ? DateFormat.MMMd(locale) : full;
  return '${short.format(t.start)} – ${full.format(t.end)}';
}

String tripStatusLabel(AppLocalizations l, Trip t, DateTime now) =>
    switch (TripMath.status(t, now)) {
      TripStatus.upcoming => l.tripInDays(TripMath.daysUntil(t, now)),
      TripStatus.active => l.tripActive,
      TripStatus.ended => l.tripEnded,
    };

/// The plane by the trip's state: taking off while planned, flying while
/// under way, landing once back.
IconData tripStatusIcon(TripStatus s) => switch (s) {
      TripStatus.upcoming => SbIcons.tripTakeoff,
      TripStatus.active => SbIcons.tripInFlight,
      TripStatus.ended => SbIcons.tripLanding,
    };

Color tripStatusColor(DsColors c, Trip t, DateTime now) =>
    switch (TripMath.status(t, now)) {
      TripStatus.upcoming => c.brand,
      TripStatus.active => c.income,
      TripStatus.ended => c.textMuted,
    };

/// A trip item's icon on the summary, the editor and the share card.
IconData tripItemIcon(TripItem item) => switch (item) {
      TripItem.flights => SbIcons.tripFlights,
      TripItem.stay => SbIcons.tripStay,
      TripItem.package => SbIcons.tripPackage,
      TripItem.connectivity => SbIcons.tripConnectivity,
      TripItem.food => SbIcons.tripFood,
      TripItem.transport => SbIcons.tripTransport,
      TripItem.activities => SbIcons.tripActivities,
      TripItem.gifts => SbIcons.tripGifts,
      TripItem.emergency => SbIcons.tripEmergency,
      TripItem.other => SbIcons.tripOther,
    };

String tripItemLabel(AppLocalizations l, TripItem item) => switch (item) {
      TripItem.flights => l.tripItemFlights,
      TripItem.stay => l.tripItemStay,
      TripItem.package => l.tripItemPackage,
      TripItem.connectivity => l.tripItemConnectivity,
      TripItem.food => l.tripItemFood,
      TripItem.transport => l.tripItemTransport,
      TripItem.activities => l.tripItemActivities,
      TripItem.gifts => l.tripItemGifts,
      TripItem.emergency => l.tripItemEmergency,
      TripItem.other => l.tripItemOther,
    };

/// One colour per item, the same on every screen and card; never red, which
/// says "over its share".
Color tripItemColor(TripItem item) => switch (item) {
      TripItem.flights => const Color(0xFF3B82F6), // blue
      TripItem.stay => const Color(0xFFF59E0B), // amber
      TripItem.package => const Color(0xFF2563EB), // deep blue
      TripItem.connectivity => const Color(0xFF06B6D4), // cyan
      TripItem.food => const Color(0xFF10B981), // emerald
      TripItem.transport => const Color(0xFF8B5CF6), // violet
      TripItem.activities => const Color(0xFF14B8A6), // teal
      TripItem.gifts => const Color(0xFFEC4899), // pink
      TripItem.emergency => const Color(0xFF6366F1), // indigo
      TripItem.other => DsChartPalette.other,
    };

/// A destination's country in the app language (the suggested places'
/// countries; null for any other code).
String? tripCountryName(AppLocalizations l, String code) => switch (code) {
      'SA' => l.tripCountrySA,
      'TH' => l.tripCountryTH,
      'GB' => l.tripCountryGB,
      'TR' => l.tripCountryTR,
      'AE' => l.tripCountryAE,
      'FR' => l.tripCountryFR,
      'MY' => l.tripCountryMY,
      'IT' => l.tripCountryIT,
      'ES' => l.tripCountryES,
      'MA' => l.tripCountryMA,
      'EG' => l.tripCountryEG,
      'ID' => l.tripCountryID,
      'TN' => l.tripCountryTN,
      'GE' => l.tripCountryGE,
      _ => null,
    };

String tripKindLabel(AppLocalizations l, TripKind kind) => switch (kind) {
      TripKind.independent => l.tripKindIndependent,
      TripKind.organized => l.tripKindOrganized,
    };

String tripLevelLabel(AppLocalizations l, TripLevel level) => switch (level) {
      TripLevel.economy => l.tripLevelEconomy,
      TripLevel.standard => l.tripLevelStandard,
      TripLevel.luxury => l.tripLevelLuxury,
    };
