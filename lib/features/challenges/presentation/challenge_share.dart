import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/challenges/domain/challenges.dart';
import 'package:smartbudget/features/share/data/native_share.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The challenge's share text: a win invites friends to try it, a run in
/// progress asks who's joining. The amount kept is added only on request.
String challengeShareText(
  AppLocalizations l,
  Challenge c,
  ChallengeProgress p, {
  bool withSaved = false,
}) {
  final String main = p.status == ChallengeStatus.won
      ? l.sfShareWon(l.sfTitle(c.days))
      : l.sfShareActive(p.clean, p.days);
  final String? saved =
      withSaved && p.saved != null ? MoneyFormatter.format(p.saved!) : null;
  return saved == null ? main : '$main ${l.sfShareSavedLine(saved)}';
}

/// Shareable card for a side-free challenge. Privacy first: days only; the
/// amount kept appears only when the user switches it on. Fixed colours so
/// the exported image looks the same in any theme. 4:5, saved at 1080×1350.
class ChallengeShareCard extends StatelessWidget {
  const ChallengeShareCard({
    super.key,
    required this.challenge,
    required this.progress,
    required this.qrSvg,
    this.showSaved = false,
  });

  final Challenge challenge;
  final ChallengeProgress progress;
  final String qrSvg;
  final bool showSaved;

  static const double width = 300;
  static const double height = 375;
  static const double exportPixelRatio = 1080 / width;

  static const Color _white = Colors.white;
  static const Color _soft = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final ChallengeProgress p = progress;
    final bool won = p.status == ChallengeStatus.won;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: won
              ? const <Color>[
                  Color(0xFF052E2B),
                  Color(0xFF0F766E),
                  Color(0xFF10B981),
                ]
              : const <Color>[
                  Color(0xFF0A1633),
                  Color(0xFF0F4C9E),
                  Color(0xFF1680F7),
                ],
          stops: const <double>[0, 0.6, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/brand/dgotix-logo-mono.svg',
                height: 14,
                colorFilter: const ColorFilter.mode(_white, BlendMode.srcIn),
              ),
              const Spacer(),
              Text(AppConfig.appName,
                  style: t.labelMedium
                      ?.copyWith(color: _white, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    won
                        ? Icons.emoji_events_rounded
                        : Icons.local_fire_department_rounded,
                    color: _white,
                    size: 22),
              ),
              const SizedBox(width: 10),
              Text(won ? l.sfCardWon : l.sfCardActive,
                  style: t.titleSmall
                      ?.copyWith(color: _white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('${p.clean}',
                    style: t.displayMedium?.copyWith(
                        color: _white, fontWeight: FontWeight.w800, height: 1)),
                Text('/${p.days}',
                    style: t.titleLarge
                        ?.copyWith(color: _soft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(l.sfCardLabel,
              style: t.titleSmall?.copyWith(color: _soft, height: 1.3)),
          const SizedBox(height: 12),
          _DotStrip(marks: p.marks),
          if (showSaved && p.saved != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Text(l.sfCardSaved(MoneyFormatter.format(p.saved!)),
                  style: t.labelMedium?.copyWith(
                      color: _white, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l.sfCardCta,
                        style: t.titleSmall?.copyWith(
                            color: _white, fontWeight: FontWeight.w700)),
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

/// The days as small dots: clean filled, slip hollow-red, others faint.
class _DotStrip extends StatelessWidget {
  const _DotStrip({required this.marks});
  final List<DayMark> marks;

  @override
  Widget build(BuildContext context) {
    final double size = marks.length > 14
        ? 9
        : marks.length > 7
            ? 12
            : 14;
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: <Widget>[
        for (final DayMark m in marks)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (m) {
                DayMark.clean => Colors.white,
                DayMark.slip => const Color(0xFFFCA5A5),
                DayMark.today => const Color(0x80FFFFFF),
                DayMark.upcoming => const Color(0x26FFFFFF),
              },
            ),
          ),
      ],
    );
  }
}

/// Preview + share: the card as an image (system share sheet, or saved and
/// the caption copied where that isn't available), or just the text.
class ChallengeShareSheet extends StatefulWidget {
  const ChallengeShareSheet({
    super.key,
    required this.challenge,
    required this.progress,
  });

  final Challenge challenge;
  final ChallengeProgress progress;

  static Future<void> show(
    BuildContext context,
    Challenge challenge,
    ChallengeProgress progress,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ChallengeShareSheet(challenge: challenge, progress: progress),
    );
  }

  @override
  State<ChallengeShareSheet> createState() => _ChallengeShareSheetState();
}

class _ChallengeShareSheetState extends State<ChallengeShareSheet> {
  static final RegExp _emoji =
      RegExp(r'[\u{1F000}-\u{1FFFF}]\s?', unicode: true);
  final GlobalKey _cardKey = GlobalKey();
  late final String _url = ShareQr.appUrl();
  late final String _qr = ShareQr.svg(_url, size: 256);
  bool _showSaved = false;
  bool _busy = false;
  String? _note;

  String _text(AppLocalizations l) => challengeShareText(
      l, widget.challenge, widget.progress,
      withSaved: _showSaved);

  Future<Uint8List?> _capture() async {
    try {
      final RenderRepaintBoundary boundary = _cardKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(
          pixelRatio: ChallengeShareCard.exportPixelRatio);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _share(AppLocalizations l) async {
    setState(() => _busy = true);
    final String caption = '${_text(l)}\n$_url';
    try {
      final Uint8List? bytes = await _capture();
      const String file = 'smartbudget-challenge.png';
      final NativeShareResult r = await shareNatively(
        text: caption,
        pngBytes: bytes,
        filename: bytes == null ? null : file,
      );
      if (r != NativeShareResult.unsupported) return;
      // No system share with files here (most desktops): save + copy caption.
      if (bytes != null) {
        await downloadBytes(filename: file, bytes: bytes, mime: 'image/png');
      }
      await Clipboard.setData(ClipboardData(text: caption));
      if (mounted) {
        setState(() => _note = bytes == null
            ? l.shareTextCopied
            : l.shareImageSavedCaption);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(AppLocalizations l) async {
    await Clipboard.setData(ClipboardData(text: '${_text(l)}\n$_url'));
    if (mounted) setState(() => _note = l.shareTextCopied);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool canShowSaved = widget.progress.saved != null;

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
                  Icon(Icons.ios_share_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.sfShareTitle,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: ChallengeShareCard(
                    challenge: widget.challenge,
                    progress: widget.progress,
                    qrSvg: _qr,
                    showSaved: _showSaved,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              // The app font has no emoji: preview without them (the shared
              // text keeps them, other apps draw them).
              Text(_text(l).replaceAll(_emoji, '').trim(),
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              if (canShowSaved)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showSaved,
                  onChanged: (bool v) => setState(() => _showSaved = v),
                  title: Text(l.sfShareShowSaved, style: t.bodyMedium),
                  subtitle: Text(l.sfShareShowSavedHint,
                      style: t.bodySmall?.copyWith(color: c.textFaint)),
                ),
              const SizedBox(height: DsSpacing.md),
              DsButton(
                label: l.sfShareNow,
                icon: Icons.ios_share_rounded,
                expand: true,
                onPressed: _busy ? null : () => _share(l),
              ),
              const SizedBox(height: DsSpacing.sm),
              DsButton(
                label: l.sfShareCopyText,
                icon: Icons.copy_rounded,
                variant: DsButtonVariant.ghost,
                expand: true,
                onPressed: () => _copy(l),
              ),
              if (_note != null) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                Text(_note!,
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: c.income)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
