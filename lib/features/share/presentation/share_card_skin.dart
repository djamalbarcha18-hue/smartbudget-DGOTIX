import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The colours of a shareable card: DGOTIX blue by default, or the user's
/// Pro theme. The logo, text and QR stay the same, so every card still
/// reads as SmartBudget.
class ShareCardSkin {
  const ShareCardSkin({
    required this.gradient,
    this.accent = Colors.white,
    this.border,
  });

  /// Top-left to bottom-right, at 0, 0.6 and 1.
  final List<Color> gradient;

  /// The big figure and the icon.
  final Color accent;

  /// A thin edge (Black Gold), or none.
  final Color? border;

  static const ShareCardSkin brand = ShareCardSkin(
    gradient: <Color>[Color(0xFF0A1633), Color(0xFF0F4C9E), Color(0xFF1680F7)],
  );

  /// A won challenge.
  static const ShareCardSkin won = ShareCardSkin(
    gradient: <Color>[Color(0xFF052E2B), Color(0xFF0F766E), Color(0xFF10B981)],
  );

  // Dark ends of each Pro theme, so the white text stays easy to read.
  static const ShareCardSkin beige = ShareCardSkin(
    gradient: <Color>[Color(0xFF2B241D), Color(0xFF5C4A3A), Color(0xFF7A5C42)],
    accent: Color(0xFFF6E7CC),
  );
  static const ShareCardSkin sage = ShareCardSkin(
    gradient: <Color>[Color(0xFF17221C), Color(0xFF2F5A48), Color(0xFF42705A)],
    accent: Color(0xFFDCEFE1),
  );
  static const ShareCardSkin pomegranate = ShareCardSkin(
    gradient: <Color>[Color(0xFF2A0F16), Color(0xFF632130), Color(0xFF8E3550)],
    accent: Color(0xFFFAD9E0),
  );
  static const ShareCardSkin blackGold = ShareCardSkin(
    gradient: <Color>[Color(0xFF0F0E0D), Color(0xFF1C1A17), Color(0xFF2C2721)],
    accent: Color(0xFFD4AF37),
    border: Color(0x80D4AF37),
  );

  /// The skin of a Pro theme, or null for Classic.
  static ShareCardSkin? ofStyle(AppThemeStyle style) => switch (style) {
        AppThemeStyle.classic => null,
        AppThemeStyle.beige => beige,
        AppThemeStyle.sage => sage,
        AppThemeStyle.pomegranate => pomegranate,
        AppThemeStyle.black => blackGold,
      };

  BoxDecoration get decoration => BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
          stops: const <double>[0, 0.6, 1],
        ),
        border: border == null ? null : Border.all(color: border!, width: 1.2),
      );
}

/// The Pro theme a share card can wear: null on the free plan, with Classic,
/// or while the Pro themes are hidden.
final shareCardThemeSkinProvider = Provider<ShareCardSkin?>((ref) {
  if (!AppEnv.proThemes) return null;
  if (!ref.watch(featureGateProvider(Feature.proThemes)).allowed) return null;
  return ShareCardSkin.ofStyle(ref.watch(themeStyleProvider));
});

/// Whether the share cards wear the theme (on when there is one).
final shareCardUseThemeProvider = StateProvider<bool>((ref) => true);

/// The theme's skin when the user keeps it on, else null (DGOTIX colours).
final shareCardSkinProvider = Provider<ShareCardSkin?>((ref) =>
    ref.watch(shareCardUseThemeProvider)
        ? ref.watch(shareCardThemeSkinProvider)
        : null);

/// "In my theme colours" switch under a share card; shown only with a Pro
/// theme.
class ShareCardThemeSwitch extends ConsumerWidget {
  const ShareCardThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(shareCardThemeSkinProvider) == null) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: ref.watch(shareCardUseThemeProvider),
      onChanged: (bool v) =>
          ref.read(shareCardUseThemeProvider.notifier).state = v,
      secondary: Icon(Icons.workspace_premium_rounded, color: c.warning),
      title: Text(l.shareCardThemeColors, style: t.bodyMedium),
      subtitle: Text(l.shareCardThemeColorsHint,
          style: t.bodySmall?.copyWith(color: c.textFaint)),
    );
  }
}
