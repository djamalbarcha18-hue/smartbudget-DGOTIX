import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/account/application/account_deletion.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings → Account: delete the account and its data (after typing a
/// confirmation word, so it can't happen by accident).
class DeleteAccountSection extends ConsumerWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.deleteAccountHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.md),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.expense,
            side: BorderSide(color: c.expense.withValues(alpha: 0.6)),
            shape: const RoundedRectangleBorder(borderRadius: DsRadius.brMd),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          icon: const Icon(Icons.person_remove_outlined, size: 18),
          label: Text(l.deleteAccount),
          onPressed: () => _confirm(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDialog(),
    );
    if (ok != true) return;
    final AccountDeletionResult r =
        await ref.read(accountDeletionProvider).deleteAccount();
    final String? msg = switch (r) {
      AccountDeletionResult.deleted => null,
      AccountDeletionResult.activeSubscription => l.deleteAccountActiveSub,
      AccountDeletionResult.failed => l.deleteAccountFailed,
    };
    if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog();

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final TextEditingController _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String word = l.deleteAccountWord;
    final bool confirmed =
        _word.text.trim().toUpperCase() == word.toUpperCase();

    return AlertDialog(
      backgroundColor: c.bgElevated,
      title: Text(l.deleteAccountTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.deleteAccountBody,
                style: t.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: DsSpacing.lg),
            Text(l.lockEraseTypeHint(word),
                style: t.labelMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.xs),
            TextField(
              controller: _word,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: word),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: c.expense, foregroundColor: Colors.white),
          onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
          child: Text(l.deleteAccount),
        ),
      ],
    );
  }
}
