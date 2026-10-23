import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/data/trip_image_share.dart';
import 'package:smartbudget/features/trips/data/trip_photos.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_share_card.dart';
import 'package:smartbudget/features/trips/presentation/trip_summary_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Whether the share card may drop the logo and QR code. Kept for a paid
/// plan later; false for everyone now and not tied to anything yet.
final canRemoveBrandingProvider = Provider<bool>((_) => false);

/// The share card's preview: pick a photo, values or percentages, a colour,
/// then share it as a 1080 × 1920 image.
class TripSharePage extends ConsumerStatefulWidget {
  const TripSharePage({super.key, required this.tripId});
  final String tripId;

  static Future<void> open(BuildContext context, {required String tripId}) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TripSharePage(tripId: tripId),
      ));

  @override
  ConsumerState<TripSharePage> createState() => _TripSharePageState();
}

class _TripSharePageState extends ConsumerState<TripSharePage> {
  final GlobalKey _cardKey = GlobalKey();
  Uint8List? _photo;
  TripCardColor _color = TripCardColor.green;
  bool _safeZones = false;
  bool _busy = false;

  @override
  void dispose() {
    // The shared file has been read by now: remove it.
    cleanUpTripImages();
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickPhoto(AppLocalizations l, TripPhotoSource source) async {
    try {
      final Uint8List? bytes = await ref
          .read(tripPhotoPickerProvider)
          .pick(source, aspect: TripShareCard.photoAspect);
      if (bytes != null && mounted) setState(() => _photo = bytes);
    } on TripPhotoDenied {
      _say(l.tripPhotoDenied);
    } catch (_) {
      _say(l.tripPhotoFailed);
    }
  }

  /// The card as a 1080 × 1920 PNG, or null when it couldn't be drawn.
  Future<Uint8List?> capture() async {
    try {
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image =
          await boundary.toImage(pixelRatio: TripShareCard.exportPixelRatio);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _share(AppLocalizations l, String place) async {
    setState(() => _busy = true);
    try {
      final Uint8List? png = await capture();
      if (png == null) {
        _say(l.tripShareFailed);
        return;
      }
      final bool ok = await shareTripImage(png,
          text: '${l.tripShareText(place)} ${AppConfig.appShareUrl}',
          filename: 'smarttrip.png');
      if (!ok) _say(l.tripShareFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    Trip? trip;
    for (final Trip x
        in ref.watch(tripsProvider).valueOrNull ?? const <Trip>[]) {
      if (x.id == widget.tripId) trip = x;
    }
    final DestinationCatalog catalog =
        ref.watch(destinationCatalogProvider).valueOrNull ??
            DestinationCatalog.empty;
    final bool pct = ref.watch(tripPercentModeProvider);

    return Scaffold(
      backgroundColor: c.bgElevated,
      appBar: AppBar(
        title: Text(l.tripShareTitle),
        backgroundColor: c.bgElevated,
      ),
      body: trip == null
          ? const SizedBox.shrink()
          : _body(context, l, c, t, trip, catalog, pct),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    DsColors c,
    TextTheme t,
    Trip trip,
    DestinationCatalog catalog,
    bool pct,
  ) {
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final TripReport report = TripReport.of(trip, txns, AppClock.now(),
        currency: ref.watch(baseCurrencyProvider));
    final Destination? destination = catalog.byText(trip.destination);
    final String place = catalog.display(trip.destination, appLangOf(context));

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                DsSpacing.lg, DsSpacing.sm, DsSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l.tripPhotoTitle,
                    style: t.labelMedium?.copyWith(color: c.textMuted)),
                const SizedBox(height: DsSpacing.xs),
                Row(
                  children: <Widget>[
                    _PhotoButton(
                      icon: Icons.photo_library_outlined,
                      label: l.tripPhotoGallery,
                      onTap: _busy
                          ? null
                          : () => _pickPhoto(l, TripPhotoSource.gallery),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    _PhotoButton(
                      icon: Icons.photo_camera_outlined,
                      label: l.tripPhotoCamera,
                      onTap: _busy
                          ? null
                          : () => _pickPhoto(l, TripPhotoSource.camera),
                    ),
                    const SizedBox(width: DsSpacing.xs),
                    _PhotoButton(
                      icon: Icons.restart_alt_rounded,
                      label: l.tripPhotoDefault,
                      onTap: _photo == null || _busy
                          ? null
                          : () => setState(() => _photo = null),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.sm),
                TripValueToggle(percentOnly: pct),
                const SizedBox(height: DsSpacing.sm),
                Wrap(
                  spacing: DsSpacing.xs,
                  runSpacing: DsSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: DsSpacing.xs),
                      child: Text(l.tripCardColor,
                          style: t.labelMedium?.copyWith(color: c.textMuted)),
                    ),
                    for (final TripCardColor k in TripCardColor.values)
                      _Swatch(
                        color: k,
                        selected: _color == k,
                        label: k.label(l),
                        onTap: () => setState(() => _color = k),
                      ),
                    const SizedBox(width: DsSpacing.sm),
                    FilterChip(
                      label: Text(l.tripSafeZones),
                      selected: _safeZones,
                      onSelected: (bool v) => setState(() => _safeZones = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: DsSpacing.lg),
              child: Center(
                child: FittedBox(
                  child: SizedBox(
                    width: TripShareCard.logicalWidth,
                    height: TripShareCard.logicalHeight,
                    child: Stack(
                      children: <Widget>[
                        RepaintBoundary(
                          key: _cardKey,
                          child: TripShareCard(
                            report: report,
                            color: _color,
                            percentOnly: pct,
                            destination: destination,
                            photo: _photo,
                          ),
                        ),
                        // Only in the preview: what Instagram covers.
                        if (_safeZones) ...<Widget>[
                          const _SafeBand(top: true),
                          const _SafeBand(top: false),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: DsButton(
              label: _busy ? l.tripShareMaking : l.tripShare,
              icon:
                  _busy ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
              expand: true,
              onPressed: _busy ? null : () => _share(l, place),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon over a label that may take two lines (long in some languages).
class _PhotoButton extends StatelessWidget {
  const _PhotoButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.xs, vertical: DsSpacing.sm),
            shape: const RoundedRectangleBorder(borderRadius: DsRadius.brMd),
          ),
          onPressed: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(height: DsSpacing.xxs),
              Text(label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final TripCardColor color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: DsRadius.brSm,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.color,
              borderRadius: DsRadius.brSm,
              border: Border.all(
                  color: selected
                      ? context.dsColors.textPrimary
                      : Colors.transparent,
                  width: 2),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      );
}

/// A red band over the top or bottom 13% of the preview.
class _SafeBand extends StatelessWidget {
  const _SafeBand({required this.top});
  final bool top;

  @override
  Widget build(BuildContext context) => Positioned(
        left: 0,
        right: 0,
        top: top ? 0 : null,
        bottom: top ? null : 0,
        height: TripShareCard.logicalHeight * TripShareCard.safeZone,
        child: IgnorePointer(
          child: ColoredBox(color: Colors.red.withValues(alpha: 0.28)),
        ),
      );
}
