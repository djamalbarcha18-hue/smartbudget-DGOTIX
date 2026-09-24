import 'package:shared_preferences/shared_preferences.dart';

/// Removes device data left behind by retired features.
///
/// Personal AI keys are no longer supported (DGOTIX is the only AI provider),
/// so any key an earlier version saved on this device is erased at startup,
/// together with the personal cost limits and price overrides that went with it.
Future<void> removeRetiredLocalData() async {
  try {
    final SharedPreferences p = await SharedPreferences.getInstance();
    for (final String k in const <String>[
      'sb_ai_key',
      'sb_ai_provider',
      'sb_ai_model',
      'sb_ai_limit_req',
      'sb_ai_limit_cost',
      'sb_ai_prices',
    ]) {
      if (p.containsKey(k)) await p.remove(k);
    }
  } catch (_) {
    // Best effort; never blocks startup.
  }
}
