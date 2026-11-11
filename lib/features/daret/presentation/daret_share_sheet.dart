import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/daret/domain/daret_link.dart';
import 'package:smartbudget/features/daret/presentation/daret_schedule.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/share/data/native_share.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Sending a daret to its members: a link each of them opens to get their own
/// copy, and the schedule as a picture for those who only want to look.
class DaretShareSheet extends ConsumerStatefulWidget {
  const DaretShareSheet({super.key, required this.daret});

  final Daret daret;

  static Future<void> show(BuildContext context, Daret daret) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DaretShareSheet(daret: daret),
      );

  @override
  ConsumerState<DaretShareSheet> createState() => _DaretShareSheetState();
}

class _DaretShareSheetState extends ConsumerState<DaretShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  /// The link, with the sharer's invite code when they have one.
  String get _link => DaretLink.link(ShareQr.appUrl(), widget.daret,
      inviteCode: ref.read(referralCodeProvider).valueOrNull);

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyLink(AppLocalizations l) async {
    await Clipboard.setData(ClipboardData(text: _link));
    _say(l.shareLinkCopied);
  }

  Future<void> _shareLink(AppLocalizations l) async {
    final NativeShareResult r = await shareNatively(
      title: AppConfig.appName,
      text: l.daretShareMessage(widget.daret.name),
      url: _link,
    );
    if (r == NativeShareResult.unsupported) await _copyLink(l);
  }

  Future<void> _shareImage(AppLocalizations l) async {
    setState(() => _busy = true);
    try {
      Uint8List? bytes;
      try {
        final RenderRepaintBoundary boundary = _cardKey.currentContext!
            .findRenderObject()! as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 3);
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        bytes = data?.buffer.asUint8List();
      } catch (_) {
        bytes = null;
      }
      if (bytes == null) {
        _say(l.shareImageFailed);
        return;
      }
      final String caption =
          '${l.daretShareMessage(widget.daret.name)}\n$_link';
      final NativeShareResult r = await shareNatively(
          text: caption, pngBytes: bytes, filename: 'smartbudget-daret.png');
      if (r != NativeShareResult.unsupported) return;
      // No system share with files here (most desktops): save + copy caption.
      await downloadBytes(
          filename: 'smartbudget-daret.png', bytes: bytes, mime: 'image/png');
      await Clipboard.setData(ClipboardData(text: caption));
      _say(l.shareImageSavedCaption);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Daret d = widget.daret;
    ref.watch(referralCodeProvider); // the link gains the code when it arrives

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(l.daretShare,
                        style: t.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Text(l.daretShareHint,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.md),
              RepaintBoundary(
                key: _cardKey,
                child: DaretScheduleCard(
                  name: d.name,
                  contribution: d.contribution,
                  frequency: d.frequency,
                  start: d.start,
                  members: d.members,
                  footer: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(AppConfig.appName,
                        style: t.labelSmall?.copyWith(
                            color: c.brand, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              DsButton(
                key: const ValueKey<String>('daret-share-link'),
                expand: true,
                label: l.daretShareLink,
                icon: Icons.ios_share_rounded,
                onPressed: _busy ? null : () => _shareLink(l),
              ),
              const SizedBox(height: DsSpacing.sm),
              Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: <Widget>[
                  DsButton(
                    key: const ValueKey<String>('daret-copy-link'),
                    label: l.shareCopyLink,
                    icon: Icons.link_rounded,
                    variant: DsButtonVariant.secondary,
                    onPressed: _busy ? null : () => _copyLink(l),
                  ),
                  DsButton(
                    key: const ValueKey<String>('daret-share-image'),
                    label: l.shareImage,
                    icon: Icons.image_outlined,
                    variant: DsButtonVariant.secondary,
                    onPressed: _busy ? null : () => _shareImage(l),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Container(
                padding: const EdgeInsets.all(DsSpacing.sm),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: DsRadius.brMd,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: c.textMuted),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(l.daretSharePrivacy,
                          style:
                              t.labelSmall?.copyWith(color: c.textMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
