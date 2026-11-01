import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/motion/ds_motion.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/quick_entry/data/speech_engine.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The microphone beside the quick entry field: speak an entry instead of
/// typing it ("قهوة 200").
///
/// Shown only where a speech engine can answer, so it is never a button that
/// does nothing. The first tap explains what the phone's engine does with the
/// sound (see [_notice]) before anything is recorded; the microphone
/// permission is asked for only after that, never when the sheet opens.
class VoiceInputButton extends ConsumerStatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onText,
    this.onListening,
  });

  /// The words heard so far. [done] marks the engine's final answer; what
  /// comes before can still change as it hears more.
  final void Function(String text, {required bool done}) onText;

  /// Told whenever the microphone opens or closes, so the sheet can say so.
  final void Function(bool listening)? onListening;

  /// Whether the notice has been shown on this device.
  static const String prefKey = 'voice_notice_seen';

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _listening = false;

  /// The engine while it is listening. Held so [dispose] can close the
  /// microphone without reaching for a provider the widget no longer has.
  SpeechEngine? _open;

  void _setListening(bool v, {SpeechEngine? engine}) {
    _open = v ? engine : null;
    if (_listening == v) return;
    setState(() => _listening = v);
    widget.onListening?.call(v);
  }

  /// Set when the engine refuses for good (no engine, permission off), so the
  /// microphone stops being offered for the rest of this sheet.
  bool _gone = false;

  @override
  void dispose() {
    _pulse.dispose();
    // Nothing should keep listening once the sheet is gone.
    _open?.cancel();
    super.dispose();
  }

  Future<bool> _noticeSeen() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      return p.getBool(VoiceInputButton.prefKey) ?? false;
    } catch (_) {
      // No store (private browsing): the notice is shown again rather than
      // skipped, which is the safe way round.
      return false;
    }
  }

  Future<void> _rememberNotice() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(VoiceInputButton.prefKey, true);
    } catch (_) {
      // Best effort.
    }
  }

  /// What the phone's engine does with the sound, before it hears any.
  Future<bool> _notice(AppLocalizations l) async {
    final DsColors c = context.dsColors;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: Icon(Icons.mic_none_rounded, color: c.brand),
        title: Text(l.voiceNoticeTitle),
        content: Text(l.voiceNoticeBody),
        actions: <Widget>[
          DsButton(
            label: MaterialLocalizations.of(ctx).cancelButtonLabel,
            variant: DsButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          DsButton(
            label: l.voiceNoticeOk,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _tap() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final SpeechEngine engine = ref.read(speechEngineProvider);

    if (_listening) {
      await engine.stop();
      _pulse.stop();
      if (mounted) _setListening(false);
      return;
    }

    if (!await _noticeSeen()) {
      if (!mounted) return;
      if (!await _notice(l)) return;
      await _rememberNotice();
    }
    if (!mounted) return;

    final VoiceFailure? failed = await engine.start(
      language: appLangOf(context).code,
      onHeard: (VoiceHeard h) {
        if (!mounted) return;
        widget.onText(h.text, done: h.done);
        if (h.done) {
          _pulse.stop();
          _setListening(false);
        }
      },
      onFailure: _report,
    );
    if (!mounted) return;
    if (failed != null) {
      _report(failed);
      return;
    }
    _setListening(true, engine: engine);
    if (!DsMotion.reduced(context)) _pulse.repeat(reverse: true);
  }

  void _report(VoiceFailure failure) {
    if (!mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    _pulse.stop();
    _setListening(false);
    setState(() {
      // No engine or no permission won't fix itself by tapping again.
      _gone =
          failure == VoiceFailure.unavailable || failure == VoiceFailure.denied;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (failure) {
        VoiceFailure.unavailable => l.voiceFailedUnavailable,
        VoiceFailure.denied => l.voiceFailedDenied,
        VoiceFailure.noSpeech => l.voiceFailedNoSpeech,
        VoiceFailure.failed => l.voiceFailedError,
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_gone || !ref.watch(speechEngineProvider).supported) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final Widget icon = Icon(
      _listening ? Icons.stop_rounded : Icons.mic_none_rounded,
      color: _listening ? c.brand : c.textMuted,
    );
    return IconButton(
      tooltip: _listening ? l.voiceStop : l.voiceStart,
      onPressed: _tap,
      icon: _listening
          ? FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.45).animate(_pulse),
              child: icon,
            )
          : icon,
    );
  }
}

/// "Listening…", under the field while the microphone is open.
class VoiceListeningLine extends StatelessWidget {
  const VoiceListeningLine({super.key});

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(Icons.graphic_eq_rounded, size: 16, color: c.brand),
          const SizedBox(width: DsSpacing.sm),
          Text(
            AppLocalizations.of(context).voiceListening,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c.brand),
          ),
        ],
      ),
    );
  }
}
