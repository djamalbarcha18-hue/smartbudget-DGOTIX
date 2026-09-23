/// Single source of truth for app-level, non-financial configuration.
///
/// Support email, legal/support links, and brand-lockup ordering all live here
/// so they can be changed in ONE place (never duplicated across widgets).
abstract final class AppConfig {
  static const String appName = 'SmartBudget';
  static const String parentBrand = 'DGOTIX';
  static const String tagline = 'Plan · Track · Grow';

  /// App version (kept in sync with pubspec).
  static const String version = '0.1.0';

  /// Copyright year shown in the footer.
  static const int copyrightYear = 2026;

  /// Support inbox users can write to. Leave EMPTY until a real inbox exists:
  /// while empty the app never shows an address (the Help page and the legal
  /// pages point to Help & Support instead). Set it here, in this ONE spot, and
  /// every screen picks it up.
  static const String supportEmail = '';

  /// True once a real support inbox has been configured above.
  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;

  /// Public address of the platform, used by "Share SmartBudget" and its QR
  /// code. Leave EMPTY to use the address the app is served from (so the QR
  /// follows the site automatically); set it once you have your own domain,
  /// e.g. 'https://smartbudget.example.com/'.
  static const String publicUrl = '';

  /// Where the app is deployed today — used only when there is no web address
  /// to read (tests, non-web builds).
  static const String fallbackUrl =
      'https://djamalbarcha18-hue.github.io/smartbudget-DGOTIX/';

  /// Support/legal destinations. Kept as route/URL placeholders for now; the
  /// support architecture (email / chat / tickets / FAQ) plugs in here later
  /// without touching the footer or sidebar widgets.
  static const String privacyUrl = '/legal/privacy';
  static const String termsUrl = '/legal/terms';
  static const String helpCenterUrl = '/support/help';

  /// Brand lockup ordering. Per current brand direction the PARENT brand
  /// (DGOTIX) leads and the PRODUCT (SmartBudget) sits beneath it. Flip this
  /// single flag to reverse the relationship everywhere.
  static const bool parentBrandFirst = true;
}
