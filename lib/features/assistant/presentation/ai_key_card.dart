import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A compact card in the AI service that lets the user connect / manage their
/// own personal AI key. Connected state shows the provider + a masked key;
/// otherwise it invites the user to connect one. All the sensitive text and the
/// ownership warning live in [_AiKeySheet].
class AiKeyCard extends ConsumerWidget {
  const AiKeyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final AiKeyConfig? cfg = ref.watch(aiKeyProvider);
    final bool connected = cfg?.isSet ?? false;

    return GlassCard(
      accent: connected ? c.income : c.brand,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (connected ? c.income : c.brand).withValues(alpha: 0.14),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(connected ? Icons.verified_user_outlined : Icons.key_outlined,
                size: 20, color: connected ? c.income : c.brand),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  connected ? l.aiKeyConnectedTitle : l.aiKeyTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? l.aiKeyConnectedSub(cfg!.provider.label, cfg.masked)
                      : l.aiKeyConnectSub,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: DsSpacing.sm),
                DsButton(
                  label: connected ? l.aiKeyManage : l.aiKeyConnect,
                  icon: connected ? Icons.tune_rounded : Icons.add_rounded,
                  variant:
                      connected ? DsButtonVariant.secondary : DsButtonVariant.primary,
                  onPressed: () => _AiKeySheet.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to enter, activate or remove the personal AI key. Carries the
/// explicit ownership / privacy warning.
class _AiKeySheet extends ConsumerStatefulWidget {
  const _AiKeySheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiKeySheet(),
    );
  }

  @override
  ConsumerState<_AiKeySheet> createState() => _AiKeySheetState();
}

class _AiKeySheetState extends ConsumerState<_AiKeySheet> {
  final TextEditingController _ctrl = TextEditingController();
  AiProvider _provider = AiProvider.openai;
  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final AiKeyConfig? cfg = ref.read(aiKeyProvider);
    if (cfg != null) _provider = cfg.provider;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String key = _ctrl.text.trim();
    if (key.isEmpty) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    setState(() => _busy = true);
    await ref.read(aiKeyProvider.notifier).save(_provider, key);
    messenger.showSnackBar(SnackBar(content: Text(l.aiKeySaved)));
    nav.pop();
  }

  Future<void> _remove() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    setState(() => _busy = true);
    await ref.read(aiKeyProvider.notifier).remove();
    messenger.showSnackBar(SnackBar(content: Text(l.aiKeyRemoved)));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool connected = ref.watch(aiKeyConnectedProvider);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: DsRadius.brPill,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.lg),
              Row(
                children: <Widget>[
                  Icon(Icons.key_outlined, size: 20, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.aiKeyTitle,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),

              // ---- Ownership / privacy warning (the required notice) ----
              _WarningBox(title: l.aiKeyWarningTitle, body: l.aiKeyWarning),
              const SizedBox(height: DsSpacing.lg),

              Text(l.aiKeyProviderLabel,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.xs),
              Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: <Widget>[
                  for (final AiProvider p in AiProvider.values)
                    _ProviderChip(
                      label: p.label,
                      selected: _provider == p,
                      onTap: () => setState(() => _provider = p),
                    ),
                ],
              ),
              const SizedBox(height: DsSpacing.lg),

              Text(l.aiKeyField,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.xs),
              TextField(
                controller: _ctrl,
                obscureText: _obscure,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '••••••••••••',
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              DsButton(
                label: l.aiKeyActivate,
                icon: Icons.bolt_outlined,
                variant: DsButtonVariant.primary,
                onPressed: _busy ? null : _save,
              ),
              if (connected) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                DsButton(
                  label: l.aiKeyRemove,
                  icon: Icons.delete_outline_rounded,
                  variant: DsButtonVariant.secondary,
                  onPressed: _busy ? null : _remove,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          color: selected ? c.brand : c.surfaceMuted,
          borderRadius: DsRadius.brPill,
          border: Border.all(color: selected ? c.brand : c.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? c.onBrand : c.textMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.saving.withValues(alpha: 0.10),
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.saving.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, size: 18, color: c.saving),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: t.labelLarge?.copyWith(
                        color: c.saving, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
