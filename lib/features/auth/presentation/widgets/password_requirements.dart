import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/domain/password_policy.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Live checklist under a new-password field: a 4-step strength bar and each
/// rule ticking green as the user types, so the requirements are visible
/// before submitting rather than discovered as an error.
class PasswordRequirements extends StatefulWidget {
  const PasswordRequirements({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PasswordRequirements> createState() => _PasswordRequirementsState();
}

class _PasswordRequirementsState extends State<PasswordRequirements> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant PasswordRequirements old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final PasswordCheck check = PasswordPolicy.check(widget.controller.text);
    final int score = check.score;
    final Color barColor = switch (score) {
      <= 1 => c.expense,
      2 || 3 => c.saving,
      _ => c.income,
    };

    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < 4; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? barColor : c.surfaceMuted,
                      borderRadius: DsRadius.brPill,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          _Rule(ok: check.hasMinLength, label: l.pwRuleLength),
          _Rule(ok: check.hasLetter, label: l.pwRuleLetter),
          _Rule(ok: check.hasDigit, label: l.pwRuleDigit),
          _Rule(ok: check.hasSymbol, label: l.pwRuleSymbol),
          if (!check.hasNoSpaces)
            _Rule(ok: false, label: l.valPasswordSpaces),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.label});
  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: ok ? c.income : c.textFaint,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: ok ? c.textPrimary : c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
