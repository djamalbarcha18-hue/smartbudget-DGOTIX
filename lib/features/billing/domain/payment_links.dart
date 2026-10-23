/// Which payment links the app may open.
///
/// Checkout and "manage subscription" links come from our own functions, but
/// the app still opens only https pages of the payment providers and of our
/// own domain, so a tampered response can't send the user somewhere else.
library;

abstract final class PaymentLinks {
  /// Hosts allowed as is, or as the parent domain of the link's host.
  static const List<String> trustedDomains = <String>[
    'whop.com', // checkout and the buyer's billing page (and sandbox hosts)
    'paypal.com', // approve and manage (www and sandbox)
    'dgotix.com', // our own site (back from a checkout)
  ];

  /// The link as a [Uri] when it is safe to open, otherwise null.
  static Uri? trusted(String? url) {
    if (url == null) return null;
    final Uri? u = Uri.tryParse(url.trim());
    if (u == null || u.scheme != 'https' || u.host.isEmpty) return null;
    if (u.userInfo.isNotEmpty) return null; // https://whop.com@evil.example
    final String host = u.host.toLowerCase();
    for (final String d in trustedDomains) {
      if (host == d || host.endsWith('.$d')) return u;
    }
    return null;
  }
}
