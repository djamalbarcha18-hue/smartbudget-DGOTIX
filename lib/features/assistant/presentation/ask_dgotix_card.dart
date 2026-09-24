import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/markdown_text.dart';
import 'package:smartbudget/features/assistant/domain/ai_conversation.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/ai/data/ai_gateway_service.dart';
import 'package:smartbudget/features/ai/domain/ai_errors.dart';
import 'package:smartbudget/features/ai/domain/ai_registry.dart';
import 'package:smartbudget/features/assistant/application/ai_backend.dart';
import 'package:smartbudget/features/assistant/application/ai_usage_controller.dart';
import 'package:smartbudget/features/assistant/application/ask_ai_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Ask DGOTIX AI" — a lightweight chat that sends the user's question (plus a
/// compact real-data context) to the DGOTIX AI gateway, which answers within the
/// plan's quota. The conversation is saved on-device; suggestion chips help
/// start. Shown only when the gateway is available.
class AskDgotixCard extends ConsumerStatefulWidget {
  const AskDgotixCard({super.key});

  @override
  ConsumerState<AskDgotixCard> createState() => _AskDgotixCardState();
}

class _AskDgotixCardState extends ConsumerState<AskDgotixCard> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  String? _error; // already-localized message
  bool _errorIsQuota = false; // error is a quota wall ⇒ offer Upgrade

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendText(String raw) async {
    final String q = raw.trim();
    if (q.isEmpty || _busy) return;
    if (!ref.read(assistantReadyProvider)) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final String ctx = ref.read(aiContextProvider);
    final ChatMessagesController chat = ref.read(chatMessagesProvider.notifier);
    final AiUsageController usage = ref.read(aiUsageProvider.notifier);

    _ctrl.clear();
    chat.add(ChatMessage(fromUser: true, text: q));
    // Memory: the recent turns before this question, trimmed and alternating.
    final List<ChatMessage> history =
        AiConversation.history(ref.read(chatMessagesProvider));
    setState(() {
      _busy = true;
      _error = null;
      _errorIsQuota = false;
    });

    try {
      // DGOTIX AI: keys, routing, quota and failover all happen server-side.
      final GatewayAnswer a = await ref.read(aiGatewayServiceProvider).ask(
          task: AiTaskType.chat, prompt: q, context: ctx, history: history);
      chat.add(ChatMessage(fromUser: false, text: a.text));
      usage.record(a.model.isEmpty ? 'dgotix-ai' : a.model,
          inputTokens: a.inputTokens, outputTokens: a.outputTokens);
    } on AiFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = _gatewayError(l, e);
          _errorIsQuota = e.kind == AiErrorKind.quotaExceeded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = l.askAiErrGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _gatewayError(AppLocalizations l, AiFailure e) => switch (e.kind) {
        AiErrorKind.quotaExceeded => l.askAiErrQuota,
        AiErrorKind.rateLimited => l.askAiErrRate,
        _ => l.askAiUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<ChatMessage> msgs = ref.watch(chatMessagesProvider);
    // Plan-quota nudges (80% / 90% / 100%); the server is the real enforcer.
    final GateDecision gate = ref.watch(featureGateProvider(Feature.dgotixAi));
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
                  child: Text(_error!,
                      style: t.bodySmall?.copyWith(color: c.expense)),
                ),
              ],
            ),
            if (_errorIsQuota) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _UpgradeButton(label: l.aiUpgrade),
              ),
            ],
          ],

          if (_error == null) _QuotaNudge(gate: gate),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  inputFormatters: LatinDigitsFormatter.only,
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

/// Advisory usage nudge for the server gateway. Shows nothing until the user
/// crosses ~80% of the period allowance (per docs/PRICING.md §6); at/over the
/// limit it surfaces the upgrade-only wall.
class _QuotaNudge extends StatelessWidget {
  const _QuotaNudge({required this.gate});
  final GateDecision gate;

  @override
  Widget build(BuildContext context) {
    final int? limit = gate.limit;
    final int? remaining = gate.remaining;
    final double? frac = gate.usedFraction;
    // Not metered / unlimited / comfortably under budget ⇒ no nudge.
    if (limit == null || remaining == null || frac == null || frac < 0.8) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool over = !gate.allowed;
    final Color color = over ? c.expense : c.saving;
    final bool lifetime = gate.window == QuotaWindow.lifetime;
    final String left = lifetime
        ? l.aiQuotaLeftLifetime(remaining, limit)
        : l.aiQuotaLeftMonth(remaining, limit);

    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: DsRadius.brMd,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: <Widget>[
            Icon(over ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
                size: 16, color: color),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Text(
                over ? l.askAiErrQuota : '${l.aiQuotaNear} $left',
                style: t.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            _UpgradeButton(label: l.aiUpgrade),
          ],
        ),
      ),
    );
  }
}

/// A compact button that takes the user to the Plans screen. Upgrade is the
/// only call to action on a quota wall.
class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Material(
      color: c.brand,
      borderRadius: DsRadius.brPill,
      child: InkWell(
        borderRadius: DsRadius.brPill,
        onTap: () => context.go('/plans'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.arrow_upward_rounded, size: 14, color: c.onBrand),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: c.onBrand, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
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
          child: user
              ? SelectableText(
                  msg.text,
                  style: t.bodyMedium?.copyWith(color: c.textPrimary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Formatted answer (bold, bullets) instead of raw symbols.
                    MarkdownText(msg.text),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: AppLocalizations.of(context).askAiCopy,
                        icon: Icon(Icons.copy_rounded,
                            size: 16, color: c.textFaint),
                        onPressed: () async {
                          final ScaffoldMessengerState? m =
                              ScaffoldMessenger.maybeOf(context);
                          final String done =
                              AppLocalizations.of(context).askAiCopied;
                          await Clipboard.setData(
                              ClipboardData(text: msg.text));
                          m?.showSnackBar(SnackBar(content: Text(done)));
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
