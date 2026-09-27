import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/install/application/install_controller.dart';
import 'package:smartbudget/features/install/data/pwa_install.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<void> _install(BuildContext context, InstallMode mode) async {
  if (mode == InstallMode.iosHint) {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => const _IosHowTo(),
    );
    return;
  }
  await promptInstall();
}

/// Dashboard card offering to install the app (dismissible for 30 days).
class InstallBanner extends ConsumerWidget {
  const InstallBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InstallMode mode =
        ref.watch(installModeProvider).valueOrNull ?? InstallMode.none;
    final bool dismissed = ref.watch(installBannerProvider);
    if (dismissed ||
        (mode != InstallMode.prompt && mode != InstallMode.iosHint)) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.installTitle,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(l.installBody, style: t.bodySmall?.copyWith(color: c.textMuted)),
      ],
    );
    final Widget icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.brand.withValues(alpha: 0.14),
        borderRadius: DsRadius.brMd,
      ),
      child: Icon(Icons.install_mobile_rounded, color: c.brand),
    );
    final Widget buttons = Wrap(
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.sm,
      children: <Widget>[
        DsButton(
          label: mode == InstallMode.iosHint ? l.installHow : l.installCta,
          icon: Icons.download_rounded,
          onPressed: () => _install(context, mode),
        ),
        DsButton(
          label: l.installLater,
          variant: DsButtonVariant.ghost,
          onPressed: () => ref.read(installBannerProvider.notifier).dismiss(),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.gridGap),
      child: GlassCard(
        accent: c.brand,
        child: context.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      icon,
                      const SizedBox(width: DsSpacing.md),
                      Expanded(child: text),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.md),
                  buttons,
                ],
              )
            : Row(
                children: <Widget>[
                  icon,
                  const SizedBox(width: DsSpacing.md),
                  Expanded(child: text),
                  const SizedBox(width: DsSpacing.md),
                  buttons,
                ],
              ),
      ),
    );
  }
}

/// Settings content: install button, iPhone steps, or "installed".
class InstallSection extends ConsumerWidget {
  const InstallSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final InstallMode mode =
        ref.watch(installModeProvider).valueOrNull ?? InstallMode.none;
    if (mode == InstallMode.installed) {
      return Row(
        children: <Widget>[
          Icon(Icons.verified_rounded, color: c.income, size: 20),
          const SizedBox(width: DsSpacing.sm),
          Expanded(child: Text(l.installDone, style: t.bodyMedium)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
            mode == InstallMode.none ? l.installUnsupported : l.installBody,
            style: t.bodySmall?.copyWith(color: c.textMuted)),
        if (mode != InstallMode.none) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: mode == InstallMode.iosHint ? l.installHow : l.installCta,
            icon: Icons.install_mobile_rounded,
            variant: DsButtonVariant.secondary,
            onPressed: () => _install(context, mode),
          ),
        ],
      ],
    );
  }
}

class _IosHowTo extends StatelessWidget {
  const _IosHowTo();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    Widget step(int n, IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 13,
                backgroundColor: c.brand.withValues(alpha: 0.15),
                child: Text('$n',
                    style: t.labelMedium?.copyWith(color: c.brand)),
              ),
              const SizedBox(width: DsSpacing.md),
              Icon(icon, size: 20, color: c.textMuted),
              const SizedBox(width: DsSpacing.sm),
              Expanded(child: Text(text, style: t.bodyMedium)),
            ],
          ),
        );
    return AlertDialog(
      title: Text(l.installTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          step(1, Icons.ios_share_rounded, l.installIos1),
          step(2, Icons.add_box_outlined, l.installIos2),
          step(3, Icons.check_circle_outline_rounded, l.installIos3),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
