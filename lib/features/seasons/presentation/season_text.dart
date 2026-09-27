import 'package:flutter/material.dart';

import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

String seasonName(AppLocalizations l, SeasonKind k, String custom) =>
    switch (k) {
      SeasonKind.ramadan => l.seasonRamadan,
      SeasonKind.eidAdha => l.seasonEidAdha,
      SeasonKind.schoolStart => l.seasonSchool,
      SeasonKind.summer => l.seasonSummer,
      SeasonKind.custom => custom.isEmpty ? l.seasonCustom : custom,
    };

SeasonKind seasonKindFromKey(String subject) {
  final String k = subject.replaceFirst('season:', '');
  return SeasonKind.values.firstWhere((SeasonKind v) => v.name == k,
      orElse: () => SeasonKind.custom);
}

IconData seasonIcon(SeasonKind k) => switch (k) {
      SeasonKind.ramadan => Icons.nightlight_round,
      SeasonKind.eidAdha => Icons.volunteer_activism_outlined,
      SeasonKind.schoolStart => Icons.backpack_outlined,
      SeasonKind.summer => Icons.beach_access_outlined,
      SeasonKind.custom => Icons.event_outlined,
    };

Color seasonColor(SeasonKind k) => switch (k) {
      SeasonKind.ramadan => const Color(0xFF8B5CF6),
      SeasonKind.eidAdha => const Color(0xFF10B981),
      SeasonKind.schoolStart => const Color(0xFF1680F7),
      SeasonKind.summer => const Color(0xFFF59E0B),
      SeasonKind.custom => const Color(0xFF14B8A6),
    };
