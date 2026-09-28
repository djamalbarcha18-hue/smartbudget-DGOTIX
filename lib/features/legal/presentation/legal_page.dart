import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/ds_back_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Renders a legal document (Privacy Policy or Terms of Service) from the
/// shared, bilingual [LegalContent]. Pure presentation — no business logic.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.doc, this.showBack = true});

  final LegalDoc doc;

  /// Off on the public pages (no app behind them to go back to).
  final bool showBack;

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
              Row(
                children: <Widget>[
                  if (showBack) ...<Widget>[
                    const DsBackButton(fallbackRoute: '/support'),
                    const SizedBox(width: DsSpacing.xs),
                  ],
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
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

/// The policy on its own public page (`/#/privacy`, `/#/terms`), readable
/// without an account: the address given to Google Play and the App Store.
/// `?lang=en` or `?lang=ar` picks the language.
class PublicLegalPage extends StatelessWidget {
  const PublicLegalPage({super.key, required this.doc, this.lang});

  final LegalDoc doc;
  final String? lang;

  @override
  Widget build(BuildContext context) {
    final Widget page = Scaffold(
      backgroundColor: context.dsColors.bgPage,
      body: SafeArea(child: LegalPage(doc: doc, showBack: false)),
    );
    if (lang != 'ar' && lang != 'en') return page;
    return Localizations.override(
      context: context,
      locale: Locale(lang!),
      child: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: page,
      ),
    );
  }
}
