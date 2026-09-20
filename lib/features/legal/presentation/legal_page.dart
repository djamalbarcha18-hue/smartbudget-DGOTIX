import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Renders a legal document (Privacy Policy or Terms of Service) from the
/// shared, bilingual [LegalContent]. Pure presentation — no business logic.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final String title =
        doc == LegalDoc.privacy ? l.pageLegalPrivacy : l.pageLegalTerms;
    final List<LegalSection> sections = LegalContent.sections(doc, ar: ar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: DsSpacing.xs),
              Text(
                l.legalLastUpdated(LegalContent.lastUpdated),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textFaint),
              ),
              const SizedBox(height: DsSpacing.xl),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int i = 0; i < sections.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: DsSpacing.lg),
                      Text(sections[i].heading,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: DsSpacing.xs),
                      Text(
                        sections[i].body,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: c.textMuted, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
