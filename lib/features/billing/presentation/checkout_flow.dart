import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/data/checkout_service.dart';
import 'package:smartbudget/features/billing/data/subscription_service.dart';
import 'package:smartbudget/features/billing/domain/payment_links.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Buys [plan] for [period]: asks which payment method when more than one is
/// set up, has the server create the checkout and opens it. Shared by the
/// plans page and the upgrade pop-up so both behave the same.
///
/// Returns null when the checkout was opened, else a message to show the
/// person (not signed in, already subscribed, not configured, error).
Future<String?> runProCheckout(
  BuildContext context,
  WidgetRef ref, {
  required Plan plan,
  required BillingPeriod period,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  if (!ref.read(authControllerProvider).isAuthenticated) {
    return l.checkoutSignIn;
  }

  // Which payment methods are actually configured?
  List<PayProvider> providers;
  try {
    providers = await ref.read(enabledProvidersProvider.future);
  } catch (_) {
    providers = const <PayProvider>[];
  }
  if (!context.mounted) return null;

  final PayProvider provider;
  if (providers.length >= 2) {
    final PayProvider? chosen = await _pickProvider(context, providers);
    if (chosen == null || !context.mounted) return null;
    provider = chosen;
  } else {
    provider = providers.isNotEmpty ? providers.first : PayProvider.whop;
  }

  final CheckoutStart r = await ref
      .read(checkoutServiceProvider)
      .start(plan: plan, period: period, provider: provider);

  final Uri? link = r.ok ? PaymentLinks.trusted(r.url) : null;
  if (r.ok && link == null) {
    // Never open a link that isn't the payment provider's or ours.
    return l.checkoutError;
  }
  if (r.ok) {
    await launchUrl(link!,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    // When they return, re-fetch so the new plan shows without a restart.
    ref.invalidate(remoteEntitlementProvider);
    return null;
  }
  if (r.error == CheckoutError.alreadySubscribed) {
    ref.invalidate(subscriptionProvider);
    return l.checkoutAlreadySubscribed;
  }
  if (r.error == CheckoutError.notConfigured) return l.planBillingSoon;
  return l.checkoutError;
}

Future<PayProvider?> _pickProvider(
    BuildContext context, List<PayProvider> providers) {
  final AppLocalizations l = AppLocalizations.of(context);
  final DsColors c = context.dsColors;
  return showModalBottomSheet<PayProvider>(
    context: context,
    backgroundColor: c.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: DsSpacing.sm),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Text(l.payChooseMethod,
                style: Theme.of(ctx)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final PayProvider p in providers)
            ListTile(
              leading: Icon(
                p == PayProvider.paypal
                    ? Icons.account_balance_wallet_outlined
                    : Icons.credit_card_outlined,
                color: c.brand,
              ),
              title: Text(p == PayProvider.paypal
                  ? l.payMethodPaypal
                  : l.payMethodCard),
              onTap: () => Navigator.of(ctx).pop(p),
            ),
          const SizedBox(height: DsSpacing.sm),
        ],
      ),
    ),
  );
}
