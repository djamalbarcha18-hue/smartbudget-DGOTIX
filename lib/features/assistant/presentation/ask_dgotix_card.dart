import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/features/assistant/application/ask_ai_controller.dart';
import 'package:smartbudget/features/assistant/data/ai_chat_service.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class _Msg {
  const _Msg({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

/// "Ask DGOTIX AI" — a lightweight chat that sends the user's question (plus a
/// compact real-data context) to their chosen provider using their own key, and
/// shows the live answer. Shown only when a personal key is connected.
class AskDgotixCard extends ConsumerStatefulWidget {
  const AskDgotixCard({super.key});

  @override
  ConsumerState<AskDgotixCard> createState() => _AskDgotixCardState();
}

class _AskDgotixCardState extends ConsumerState<AskDgotixCard> {
  final TextEditingController _ctrl = TextEditingController();
  final List<_Msg> _msgs = <_Msg>[];
  bool _busy = false;
  AiChatError? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String q = _ctrl.text.trim();
    if (q.isEmpty || _busy) return;
    final AiKeyConfig? cfg = ref.read(aiKeyProvider);
    if (cfg == null || !cfg.isSet) return;
    final String context = ref.read(aiContextProvider);

    setState(() {
      _msgs.add(_Msg(fromUser: true, text: q));
      _busy = true;
      _error = null;
      _ctrl.clear();
    });

    try {
      final String answer = await ref
          .read(aiChatServiceProvider)
          .ask(config: cfg, question: q, context: context);
      if (!mounted) return;
      setState(() => _msgs.add(_Msg(fromUser: false, text: answer)));
    } on AiChatException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.kind);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AiChatError.unknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(AppLocalizations l, AiChatError e) => switch (e) {
        AiChatError.invalidKey => l.askAiErrInvalidKey,
        AiChatError.unsupported => l.askAiErrUnsupported,
        AiChatError.rateLimited => l.askAiErrRate,
        AiChatError.network => l.askAiErrNetwork,
        AiChatError.empty => l.askAiErrGeneric,
        AiChatError.unknown => l.askAiErrGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return GlassCard(
      accent: c.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.askAiTitle,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (_msgs.isNotEmpty)
                IconButton(
                  tooltip: l.askAiClear,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_sweep_outlined,
                      size: 18, color: c.textMuted),
                  onPressed: _busy ? null : () => setState(_msgs.clear),
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),

          if (_msgs.isEmpty && !_busy && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
              child: Text(l.askAiIntro,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
            )
          else
            for (final _Msg m in _msgs) ...<Widget>[
              _Bubble(msg: m),
              const SizedBox(height: DsSpacing.sm),
            ],

          if (_busy) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.brand),
                ),
                const SizedBox(width: DsSpacing.sm),
                Text(l.askAiThinking,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ],

          if (_error != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.error_outline_rounded, size: 16, color: c.expense),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(_errorText(l, _error!),
                      style: t.bodySmall?.copyWith(color: c.expense)),
                ),
              ],
            ),
          ],

          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !_busy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.askAiHint,
                    filled: true,
                    fillColor: c.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: DsRadius.brMd,
                      borderSide: BorderSide(color: c.brand),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              _SendButton(busy: _busy, onSend: _send),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 13, color: c.textFaint),
              const SizedBox(width: DsSpacing.xs),
              Expanded(
                child: Text(l.askAiDisclaimer,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onSend});
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Material(
      color: busy ? c.surfaceMuted : c.brand,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: busy ? null : onSend,
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.sm),
          child: Icon(Icons.send_rounded,
              size: 20, color: busy ? c.textFaint : c.onBrand),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool user = msg.fromUser;
    return Align(
      alignment: user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: DsSpacing.sm),
          decoration: BoxDecoration(
            color: user ? c.brand.withValues(alpha: 0.14) : c.surfaceMuted,
            borderRadius: DsRadius.brMd,
            border: Border.all(
                color: user ? c.brand.withValues(alpha: 0.30) : c.border),
          ),
          child: SelectableText(
            msg.text,
            style: t.bodyMedium?.copyWith(color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}
