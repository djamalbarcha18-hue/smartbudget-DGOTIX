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

/// "Ask DGOTIX AI" — a lightweight chat that sends the user's question (plus a
/// compact real-data context) to their chosen provider using their own key, and
/// shows the live answer. The conversation is saved on-device; suggestion chips
/// help start. Shown only when a personal key is connected.
class AskDgotixCard extends ConsumerStatefulWidget {
  const AskDgotixCard({super.key});

  @override
  ConsumerState<AskDgotixCard> createState() => _AskDgotixCardState();
}

class _AskDgotixCardState extends ConsumerState<AskDgotixCard> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  AiChatError? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendText(String raw) async {
    final String q = raw.trim();
    if (q.isEmpty || _busy) return;
    final AiKeyConfig? cfg = ref.read(aiKeyProvider);
    if (cfg == null || !cfg.isSet) return;
    final String context = ref.read(aiContextProvider);
    final ChatMessagesController chat = ref.read(chatMessagesProvider.notifier);

    _ctrl.clear();
    chat.add(ChatMessage(fromUser: true, text: q));
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final String answer = await ref
          .read(aiChatServiceProvider)
          .ask(config: cfg, question: q, context: context);
      chat.add(ChatMessage(fromUser: false, text: answer));
    } on AiChatException catch (e) {
      if (mounted) setState(() => _error = e.kind);
    } catch (_) {
      if (mounted) setState(() => _error = AiChatError.unknown);
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
    final List<ChatMessage> msgs = ref.watch(chatMessagesProvider);
    final List<String> suggestions = <String>[
      l.askAiSuggest1,
      l.askAiSuggest2,
      l.askAiSuggest3,
      l.askAiSuggest4,
    ];

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
              if (msgs.isNotEmpty)
                IconButton(
                  tooltip: l.askAiClear,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_sweep_outlined,
                      size: 18, color: c.textMuted),
                  onPressed: _busy
                      ? null
                      : () => ref.read(chatMessagesProvider.notifier).clear(),
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),

          if (msgs.isEmpty && !_busy && _error == null) ...<Widget>[
            Text(l.askAiIntro,
                style: t.bodySmall?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.md),
            Wrap(
              spacing: DsSpacing.sm,
              runSpacing: DsSpacing.sm,
              children: <Widget>[
                for (final String s in suggestions)
                  _SuggestionChip(
                      label: s, onTap: _busy ? null : () => _sendText(s)),
              ],
            ),
          ] else
            for (final ChatMessage m in msgs) ...<Widget>[
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
                  onSubmitted: _sendText,
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
              _SendButton(busy: _busy, onSend: () => _sendText(_ctrl.text)),
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return InkWell(
      borderRadius: DsRadius.brPill,
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DsSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: DsRadius.brPill,
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add_rounded, size: 14, color: c.brand),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: c.textPrimary)),
            ),
          ],
        ),
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
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool user = msg.fromUser;
    return Align(
      alignment:
          user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
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
