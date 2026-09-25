import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/share/application/share_controller.dart';
import 'package:smartbudget/features/share/data/native_share.dart';
import 'package:smartbudget/features/share/domain/share_channels.dart';
import 'package:smartbudget/features/share/domain/share_highlight.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/features/share/presentation/share_progress_card.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

enum ShareTab { invite, progress }

/// "Share SmartBudget": invite friends through any social channel (each with a
/// message written for it), or share a privacy-safe card of your own progress.
class ShareAppSheet extends ConsumerStatefulWidget {
  const ShareAppSheet({super.key, this.initialTab = ShareTab.invite});

  final ShareTab initialTab;

  static Future<void> show(BuildContext context,
      {ShareTab tab = ShareTab.invite}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareAppSheet(initialTab: tab),
    );
  }

  @override
  ConsumerState<ShareAppSheet> createState() => _ShareAppSheetState();
}

class _ShareAppSheetState extends ConsumerState<ShareAppSheet> {
  final GlobalKey _qrCardKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  late final String _url = ShareQr.appUrl();
  late final String _svg = ShareQr.svg(_url);
  late final String _smallQr = ShareQr.svg(_url, size: 256);
  late ShareTab _tab = widget.initialTab;
  String? _status; // inline feedback (snackbars sit behind the sheet)
  bool _busy = false;

  static bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  List<ShareChannel> get _channels => <ShareChannel>[
        ShareChannel.whatsapp,
        ShareChannel.telegram,
        ShareChannel.x,
        ShareChannel.facebook,
        ShareChannel.linkedin,
        ShareChannel.instagram,
        ShareChannel.email,
        if (_isMobile) ShareChannel.sms,
      ];

  void _say(String s) {
    if (mounted) setState(() => _status = s);
  }

  // ---- Messages ------------------------------------------------------------

  SharePayload _invite(AppLocalizations l, ShareTone tone) {
    final String base = switch (tone) {
      ShareTone.personal => l.shareMsgPersonal,
      ShareTone.short => l.shareMsgShort,
      ShareTone.professional => l.shareMsgPro,
    };
    return SharePayload(
      text: AppEnv.betaAllAccess ? '$base ${l.shareMsgBetaTail}' : base,
      link: _url,
      subject: l.shareEmailSubject,
    );
  }

  SharePayload _progress(AppLocalizations l, ShareHighlight h) {
    final String text = switch (h.kind) {
      HighlightKind.goals => l.shareProgGoals(h.goalsCompleted),
      HighlightKind.health => l.shareProgHealth(h.healthScore!),
      HighlightKind.savings => l.shareProgSavings(h.savingsPct!),
      HighlightKind.journey => l.shareProgJourney,
    };
    return SharePayload(text: text, link: _url, subject: l.shareEmailSubject);
  }

  SharePayload _payloadFor(AppLocalizations l, ShareChannel ch) =>
      _tab == ShareTab.invite
          ? _invite(l, ShareLinks.toneOf(ch))
          : _progress(l, ref.read(shareHighlightProvider));

  // ---- Actions -------------------------------------------------------------

  Future<Uint8List?> _capture(GlobalKey key, double pixelRatio) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  GlobalKey get _cardKey =>
      _tab == ShareTab.invite ? _qrCardKey : _progressKey;
  double get _cardRatio => _tab == ShareTab.invite
      ? 4
      : ShareProgressCard.exportPixelRatio;
  String get _cardFile => _tab == ShareTab.invite
      ? 'smartbudget-qr.png'
      : 'smartbudget-progress.png';

  Future<bool> _saveCard() async {
    final Uint8List? bytes = await _capture(_cardKey, _cardRatio);
    if (bytes == null) return false;
    await downloadBytes(filename: _cardFile, bytes: bytes, mime: 'image/png');
    return true;
  }

  Future<void> _onChannel(AppLocalizations l, ShareChannel ch) async {
    final SharePayload p = _payloadFor(l, ch);
    if (ch == ShareChannel.instagram) {
      setState(() => _busy = true);
      final bool saved = await _saveCard();
      await Clipboard.setData(ClipboardData(text: p.textWithLink));
      if (mounted) setState(() => _busy = false);
      _say(saved ? l.shareInstagramReady : l.shareImageFailed);
      return;
    }
    if (ShareLinks.copiesCaption(ch)) {
      await Clipboard.setData(ClipboardData(text: p.textWithLink));
      _say(l.shareCaptionCopied);
    }
    final bool inPlace = ch == ShareChannel.email || ch == ShareChannel.sms;
    await launchUrl(ShareLinks.uri(ch, p)!,
        webOnlyWindowName: inPlace ? '_self' : '_blank');
  }

  Future<void> _nativeInvite(AppLocalizations l) async {
    final SharePayload p = _invite(l, ShareTone.personal);
    final NativeShareResult r = await shareNatively(
        title: AppConfig.appName, text: p.text, url: p.link);
    if (r == NativeShareResult.unsupported) await _copyLink(l);
  }

  Future<void> _shareProgressImage(AppLocalizations l) async {
    final SharePayload p = _progress(l, ref.read(shareHighlightProvider));
    setState(() => _busy = true);
    try {
      final Uint8List? bytes =
          await _capture(_progressKey, ShareProgressCard.exportPixelRatio);
      if (bytes == null) {
        _say(l.shareImageFailed);
        return;
      }
      final NativeShareResult r = await shareNatively(
        text: p.textWithLink,
        pngBytes: bytes,
        filename: 'smartbudget-progress.png',
      );
      if (r != NativeShareResult.unsupported) return;
      // No system share with files here (most desktops): save + copy caption.
      await downloadBytes(
          filename: 'smartbudget-progress.png',
          bytes: bytes,
          mime: 'image/png');
      await Clipboard.setData(ClipboardData(text: p.textWithLink));
      _say(l.shareImageSavedCaption);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(AppLocalizations l) async {
    await Clipboard.setData(ClipboardData(text: _url));
    _say(l.shareLinkCopied);
  }

  Future<void> _copyText(AppLocalizations l, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _say(l.shareTextCopied);
  }

  Future<void> _downloadSvg(AppLocalizations l) async {
    await downloadText(
      filename: 'smartbudget-qr.svg',
      text: ShareQr.svg(_url, size: 1024),
      mime: 'image/svg+xml',
    );
    _say(l.shareDownloaded);
  }

  Future<void> _downloadPng(AppLocalizations l) async {
    setState(() => _busy = true);
    final bool ok = await _saveCard();
    if (mounted) setState(() => _busy = false);
    _say(ok ? l.shareDownloaded : l.shareImageFailed);
  }

  // ---- UI ------------------------------------------------------------------

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
                  Icon(Icons.ios_share_rounded, color: c.brand),
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
              const SizedBox(height: DsSpacing.sm),
              SegmentedButton<ShareTab>(
                showSelectedIcon: false,
                segments: <ButtonSegment<ShareTab>>[
                  ButtonSegment<ShareTab>(
                    value: ShareTab.invite,
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: Text(l.shareTabInvite),
                  ),
                  ButtonSegment<ShareTab>(
                    value: ShareTab.progress,
                    icon: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: Text(l.shareTabProgress),
                  ),
                ],
                selected: <ShareTab>{_tab},
                onSelectionChanged: (Set<ShareTab> s) =>
                    setState(() {
                      _tab = s.first;
                      _status = null;
                    }),
              ),
              const SizedBox(height: DsSpacing.lg),
              if (_tab == ShareTab.invite)
                ..._inviteTab(context, l, c, t)
              else
                ..._progressTab(context, l, c, t),
              if (_status != null) ...<Widget>[
                const SizedBox(height: DsSpacing.md),
                Text(_status!,
                    textAlign: TextAlign.center,
                    style: t.labelMedium?.copyWith(color: c.brand)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _inviteTab(
      BuildContext context, AppLocalizations l, DsColors c, TextTheme t) {
    return <Widget>[
      Text(AppEnv.betaAllAccess ? l.shareInviteHookBeta : l.shareInviteHook,
          style: t.bodySmall?.copyWith(color: c.textMuted)),
      const SizedBox(height: DsSpacing.lg),
      if (canShareNatively) ...<Widget>[
        DsButton(
          label: l.shareNative,
          icon: Icons.ios_share_rounded,
          expand: true,
          onPressed: () => _nativeInvite(l),
        ),
        const SizedBox(height: DsSpacing.lg),
      ],
      _ChannelGrid(
        channels: _channels,
        enabled: !_busy,
        onTap: (ShareChannel ch) => _onChannel(l, ch),
      ),
      const SizedBox(height: DsSpacing.lg),
      // The link itself (always left-to-right, even in Arabic).
      Container(
        padding: const EdgeInsetsDirectional.only(
            start: DsSpacing.md, end: DsSpacing.xs),
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
                    maxLines: 1,
                    style: t.bodySmall?.copyWith(color: c.textPrimary)),
              ),
            ),
            IconButton(
              tooltip: l.shareCopyLink,
              icon: Icon(Icons.copy_rounded, size: 18, color: c.brand),
              onPressed: () => _copyLink(l),
            ),
          ],
        ),
      ),
      const SizedBox(height: DsSpacing.xl),
      Row(
        children: <Widget>[
          Icon(Icons.qr_code_2_rounded, size: 18, color: c.brand),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(l.shareQrSection,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      const SizedBox(height: DsSpacing.xs),
      Text(l.shareSubtitle, style: t.bodySmall?.copyWith(color: c.textMuted)),
      const SizedBox(height: DsSpacing.md),
      // Always dark-on-white (even in dark mode) so phones can scan it.
      Center(
        child: RepaintBoundary(
          key: _qrCardKey,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(DsSpacing.lg),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: DsRadius.brMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.string(_svg, width: 192, height: 192),
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
                  style: t.labelSmall?.copyWith(color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: DsSpacing.md),
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
    ];
  }

  List<Widget> _progressTab(
      BuildContext context, AppLocalizations l, DsColors c, TextTheme t) {
    final ShareHighlight h = ref.watch(shareHighlightProvider);
    return <Widget>[
      Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, size: 16, color: c.income),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(l.sharePrivacyNote,
                style: t.bodySmall?.copyWith(color: c.textMuted)),
          ),
        ],
      ),
      const SizedBox(height: DsSpacing.lg),
      Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: RepaintBoundary(
            key: _progressKey,
            child: ShareProgressCard(highlight: h, qrSvg: _smallQr),
          ),
        ),
      ),
      const SizedBox(height: DsSpacing.lg),
      DsButton(
        label: l.shareImage,
        icon: Icons.ios_share_rounded,
        expand: true,
        onPressed: _busy ? null : () => _shareProgressImage(l),
      ),
      const SizedBox(height: DsSpacing.sm),
      Row(
        children: <Widget>[
          Expanded(
            child: DsButton(
              label: l.shareSaveImage,
              icon: Icons.download_rounded,
              variant: DsButtonVariant.secondary,
              onPressed: _busy ? null : () => _downloadPng(l),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: DsButton(
              label: l.shareCopyText,
              icon: Icons.copy_rounded,
              variant: DsButtonVariant.secondary,
              onPressed: () => _copyText(l, _progress(l, h).textWithLink),
            ),
          ),
        ],
      ),
      const SizedBox(height: DsSpacing.lg),
      _ChannelGrid(
        channels: _channels,
        enabled: !_busy,
        onTap: (ShareChannel ch) => _onChannel(l, ch),
      ),
    ];
  }
}

class _ChannelGrid extends StatelessWidget {
  const _ChannelGrid({
    required this.channels,
    required this.onTap,
    required this.enabled,
  });

  final List<ShareChannel> channels;
  final ValueChanged<ShareChannel> onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.md,
      children: <Widget>[
        for (final ShareChannel ch in channels)
          _ChannelTile(
              channel: ch, onTap: enabled ? () => onTap(ch) : null),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel, required this.onTap});
  final ShareChannel channel;
  final VoidCallback? onTap;

  static const Gradient _instagram = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: <Color>[Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
  );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    Widget glyph(String s) => Text(s,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            height: 1));

    final (Color color, Widget icon, String label) = switch (channel) {
      ShareChannel.whatsapp => (
          const Color(0xFF25D366),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.flip(
                flipX: true,
                child: const Icon(Icons.mode_comment_outlined,
                    color: Colors.white, size: 26),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.phone, color: Colors.white, size: 11),
              ),
            ],
          ),
          'WhatsApp'
        ),
      ShareChannel.telegram => (
          const Color(0xFF229ED9),
          const Icon(Icons.telegram, color: Colors.white, size: 24),
          'Telegram'
        ),
      ShareChannel.x => (const Color(0xFF0F1419), glyph('X'), 'X'),
      ShareChannel.facebook => (
          const Color(0xFF1877F2),
          const Icon(Icons.facebook, color: Colors.white, size: 24),
          'Facebook'
        ),
      ShareChannel.linkedin => (const Color(0xFF0A66C2), glyph('in'), 'LinkedIn'),
      ShareChannel.instagram => (
          const Color(0xFFDD2A7B),
          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
          'Instagram'
        ),
      ShareChannel.email => (
          const Color(0xFF6B7280),
          const Icon(Icons.mail_rounded, color: Colors.white, size: 22),
          l.shareChEmail
        ),
      ShareChannel.sms => (
          const Color(0xFF34C759),
          const Icon(Icons.sms_rounded, color: Colors.white, size: 22),
          l.shareChSms
        ),
    };

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.brMd,
        child: SizedBox(
          width: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
            child: Column(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: channel == ShareChannel.instagram ? null : color,
                    gradient:
                        channel == ShareChannel.instagram ? _instagram : null,
                    border: channel == ShareChannel.x
                        ? Border.all(color: c.border)
                        : null,
                  ),
                  child: icon,
                ),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
