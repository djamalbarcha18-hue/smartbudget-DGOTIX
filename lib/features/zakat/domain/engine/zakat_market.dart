/// Which country profile (market) a user's zakat is computed for, and the
/// rules that apply. Only the profiles listed in [ZakatMarkets.enabled] are
/// used; any other market (Saudi Arabia included) resolves to null and the
/// app keeps its earlier calculator for it, unchanged.
library;

import 'package:smartbudget/features/zakat/domain/engine/profiles/algeria_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';

abstract final class ZakatMarkets {
  /// The profiles in use. Adding one is a separate, approved step.
  static final List<ZakatProfile> enabled = <ZakatProfile>[algeriaZakatProfile];

  static ZakatProfile? byCountry(String code) {
    for (final ZakatProfile p in enabled) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// The profile for [settings]: the country the user chose, else the one
  /// whose currency is the app's [baseCurrency]. Null when none is enabled.
  static ZakatProfile? resolve(ZakatSettings settings, String baseCurrency) {
    final String? chosen = settings.country;
    if (chosen != null) return byCountry(chosen);
    for (final ZakatProfile p in enabled) {
      if (p.currency == baseCurrency) return p;
    }
    return null;
  }

  /// The rules for [profile] under the school in [settings]. The profile's
  /// own (approved) rules when the school is the profile's; another school's
  /// preset otherwise, marked not approved until it is reviewed for that
  /// country, so its results show as provisional.
  static ZakatRules rulesFor(ZakatProfile profile, ZakatSettings settings) {
    final ZakatRules base = profile.defaultRules;
    if (settings.school == base.school) return base;
    return ZakatSchools.apply(settings.school, base)
        .copyWith(version: '${base.version}+${settings.school.name}', approved: false);
  }
}
