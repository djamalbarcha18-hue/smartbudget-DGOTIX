import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Share SmartBudget": a QR code that opens the platform, plus the link.
///
/// The card is always dark-on-white (even in dark mode) so phones can scan it
/// from the screen, and it can be saved as a PNG (for social media/chats) or an
/// SVG (vector, for printing flyers and posters at any size).
class ShareAppSheet extends StatefulWidget {
  const ShareAppSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareAppSheet(),
    );
  }

  @override
  State<ShareAppSheet> createState() => _ShareAppSheetState();
}

class _ShareAppSheetState extends State<ShareAppSheet> {
  final GlobalKey _cardKey = GlobalKey();
  late final String _url = ShareQr.appUrl();
  late final String _svg = ShareQr.svg(_url);
  String? _status; // inline feedback (snackbars sit behind the sheet)
  bool _busy = false;

  Future<void> _copy(AppLocalizations l) async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) setState(() => _status = l.shareLinkCopied);
  }

  Future<void> _downloadSvg(AppLocalizations l) async {
    await downloadText(
      filename: 'smartbudget-qr.svg',
      text: ShareQr.svg(_url, size: 1024),
      mime: 'image/svg+xml',
    );
    if (mounted) setState(() => _status = l.shareDownloaded);
  }

  Future<void> _downloadPng(AppLocalizations l) async {
    setState(() => _busy = true);
    try {
      final RenderRepaintBoundary boundary = _cardKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 4);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('no image data');
      await downloadBytes(
        filename: 'smartbudget-qr.png',
        bytes: data.buffer.asUint8List(),
        mime: 'image/png',
      );
      if (mounted) setState(() => _status = l.shareDownloaded);
    } catch (_) {
      if (mounted) setState(() => _status = l.shareImageFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.qr_code_2_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.shareTitle,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(l.shareSubtitle,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.lg),

              // The shareable card. Fixed light colours on purpose.
              Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(DsSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: DsRadius.brMd,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SvgPicture.string(_svg, width: 232, height: 232),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          '${AppConfig.appName} · ${AppConfig.parentBrand}',
                          style: t.titleSmall?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConfig.tagline,
                          style: t.labelSmall
                              ?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),

              // The link itself (always left-to-right, even in Arabic).
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: DsRadius.brMd,
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.link_rounded, size: 16, color: c.textMuted),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(_url,
                            style: t.bodySmall
                                ?.copyWith(color: c.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              DsButton(
                label: l.shareCopyLink,
                icon: Icons.copy_rounded,
                expand: true,
                onPressed: () => _copy(l),
              ),
              const SizedBox(height: DsSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DsButton(
                      label: l.shareDownloadPng,
                      icon: Icons.image_outlined,
                      variant: DsButtonVariant.secondary,
                      onPressed: _busy ? null : () => _downloadPng(l),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: DsButton(
                      label: l.shareDownloadSvg,
                      icon: Icons.print_outlined,
                      variant: DsButtonVariant.secondary,
                      onPressed: () => _downloadSvg(l),
                    ),
                  ),
                ],
              ),
              if (_status != null) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                Text(_status!,
                    textAlign: TextAlign.center,
                    style: t.labelMedium?.copyWith(color: c.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
