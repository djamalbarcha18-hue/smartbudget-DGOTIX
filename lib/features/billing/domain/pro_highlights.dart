/// What the upgrade pop-up lists as reasons to go PRO.
///
/// This is the one place to add to when PRO grows (new themes, hidden features
/// that ship in later updates): add a [ProHighlight] to [all], in priority
/// order. The pop-up shows the first [popupCount] that are [visible]; the full
/// list stays on the plans page.
library;

import 'package:flutter/material.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ProHighlight {
  const ProHighlight({
    required this.icon,
    required this.text,
    this.visible,
  });

  final IconData icon;

  /// The line, in the person's language.
  final String Function(AppLocalizations l) text;

  /// Whether to show it (a feature still hidden behind a flag returns false).
  /// Null: always.
  final bool Function()? visible;
}

abstract final class ProHighlights {
  /// How many the pop-up shows.
  static const int popupCount = 4;

  static int _quota(Feature f) => FeatureCatalog.quotaFor(f, Plan.pro)?.limit ?? 0;

  /// Strongest reasons first. Add new PRO features here.
  static final List<ProHighlight> all = <ProHighlight>[
    ProHighlight(
      icon: Icons.auto_awesome_rounded,
      text: (AppLocalizations l) => l.planFeatAiMonthly(_quota(Feature.dgotixAi)),
    ),
    ProHighlight(
      icon: Icons.document_scanner_outlined,
      text: (AppLocalizations l) =>
          l.planFeatOcrMonthly(_quota(Feature.cloudOcr)),
    ),
    ProHighlight(
      icon: Icons.sync_rounded,
      text: (AppLocalizations l) => l.planFeatSyncAll,
    ),
    ProHighlight(
      icon: Icons.bar_chart_rounded,
      text: (AppLocalizations l) => l.planFeatAdvancedReports,
    ),
    ProHighlight(
      icon: Icons.palette_outlined,
      text: (AppLocalizations l) => l.featProThemes,
    ),
    ProHighlight(
      icon: Icons.category_outlined,
      text: (AppLocalizations l) => l.featCategoryIcons,
      visible: () => AppEnv.categoryIconPicker,
    ),
  ];

  /// What the pop-up shows now.
  static List<ProHighlight> forPopup() => all
      .where((ProHighlight h) => h.visible?.call() ?? true)
      .take(popupCount)
      .toList();
}
