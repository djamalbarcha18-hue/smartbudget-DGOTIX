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

  /// Placeholder support email — replace with the real address in this ONE spot.
  static const String supportEmail = 'support@YOUR-DOMAIN.com';

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
