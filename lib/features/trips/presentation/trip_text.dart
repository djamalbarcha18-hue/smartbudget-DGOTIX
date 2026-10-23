import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The icon named in destinations.json.
IconData destinationIcon(String? name) => switch (name) {
      'mosque' => Icons.mosque_outlined,
      'temple' => Icons.temple_buddhist_outlined,
      'city' => Icons.location_city_outlined,
      'tower' => Icons.apartment_outlined,
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

Color tripStatusColor(DsColors c, Trip t, DateTime now) =>
    switch (TripMath.status(t, now)) {
      TripStatus.upcoming => c.brand,
      TripStatus.active => c.income,
      TripStatus.ended => c.textMuted,
    };
