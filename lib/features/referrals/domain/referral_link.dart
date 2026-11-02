/// The invite link, and reading a code back out of one.
///
/// Pure Dart (no Flutter, no Supabase) so every rule here is unit-testable.
/// The code rides as a query parameter on the ordinary app URL, which already
/// works on the web and opens the browser on a phone — no new deep-link
/// scheme, no new registration, nothing extra to keep working.
library;

abstract final class ReferralLink {
  /// The query parameter carrying the code: `?ref=AB23CD45`.
  static const String param = 'ref';

  /// Codes the server makes: eight characters from an alphabet without the
  /// pairs people mistype — no 0/O, no 1/I, no L. This must stay exactly the
  /// 31 characters `my_referral_code()` draws from in supabase/referrals.sql.
  static final RegExp _shape = RegExp(r'^[2-9A-HJKMNP-Z]{8}$');

  /// Whether [code] could be one of ours. Checked before it is sent, so a
  /// stray query parameter never becomes a server call.
  static bool looksValid(String? code) =>
      code != null && _shape.hasMatch(code.trim().toUpperCase());

  /// [appUrl] with [code] attached. Returns [appUrl] unchanged when the code
  /// is not one of ours, so a broken code can never produce a broken link.
  static String invite(String appUrl, String? code) {
    if (!looksValid(code)) return appUrl;
    final Uri base = Uri.parse(appUrl);
    return base.replace(queryParameters: <String, String>{
      ...base.queryParameters,
      param: code!.trim().toUpperCase(),
    }).toString();
  }

  /// The code in [url], or null. Reads the query string and, because the app
  /// routes on the fragment (`/#/plans?ref=…`), the fragment's query too.
  static String? codeIn(Uri url) {
    final String? direct = url.queryParameters[param];
    if (looksValid(direct)) return direct!.trim().toUpperCase();

    final String fragment = url.fragment;
    final int q = fragment.indexOf('?');
    if (q < 0) return null;
    final String? inner =
        Uri.splitQueryString(fragment.substring(q + 1))[param];
    return looksValid(inner) ? inner!.trim().toUpperCase() : null;
  }
}
