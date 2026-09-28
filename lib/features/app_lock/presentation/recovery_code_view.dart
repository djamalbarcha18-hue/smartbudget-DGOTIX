import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Shows a freshly made recovery code once: the code, a copy button, and a
/// "saved it" check that must be ticked before [onDone].
/// Works without a Navigator or ScaffoldMessenger (the lock screen has none).
class RecoveryCodeView extends StatefulWidget {
  const RecoveryCodeView({
    super.key,
    required this.code,
    required this.message,
    required this.doneLabel,
    required this.onDone,
  });

  final String code;
  final String message;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  State<RecoveryCodeView> createState() => _RecoveryCodeViewState();
}

class _RecoveryCodeViewState extends State<RecoveryCodeView> {
  bool _saved = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.message,
            style: t.bodyMedium?.copyWith(color: c.textMuted, height: 1.5)),
        const SizedBox(height: DsSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: DsSpacing.lg),
          decoration: BoxDecoration(
            color: c.brand.withValues(alpha: 0.08),
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.brand.withValues(alpha: 0.45)),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              widget.code,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _copy,
            icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 18),
            label: Text(_copied ? l.lockRecoveryCopied : l.lockRecoveryCopy),
          ),
        ),
        CheckboxListTile(
          value: _saved,
          onChanged: (bool? v) => setState(() => _saved = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l.lockRecoverySaved, style: t.bodyMedium),
        ),
        const SizedBox(height: DsSpacing.sm),
        DsButton(
          label: widget.doneLabel,
          icon: Icons.check_circle_outline_rounded,
          expand: true,
          onPressed: _saved ? widget.onDone : null,
        ),
      ],
    );
  }
}

/// The recovery code in a bottom sheet that only closes once it's saved.
abstract final class RecoveryCodeSheet {
  static Future<void> show(
    BuildContext context,
    String code, {
    bool replaced = false,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final DsColors c = ctx.dsColors;
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                      Icon(Icons.key_rounded, color: c.brand),
                      const SizedBox(width: DsSpacing.sm),
                      Text(l.lockRecoveryTitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.md),
                  RecoveryCodeView(
                    code: code,
                    message: replaced
                        ? '${l.lockRecoveryIntro} ${l.lockRecoveryReplaced}'
                        : l.lockRecoveryIntro,
                    doneLabel: l.lockRecoveryDone,
                    onDone: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
