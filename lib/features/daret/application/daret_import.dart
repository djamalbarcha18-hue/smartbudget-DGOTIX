/// Carrying a shared daret from the link to the signed-in app.
///
/// A member opens the link, and may have to sign up (and confirm a mailbox,
/// which reloads the page) before there is anywhere to put the daret. So the
/// schedule waits on the device until the app shell is up, is offered once,
/// and is then forgotten whether it was added or not.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/daret/domain/daret_link.dart';

abstract final class DaretPending {
  /// Where the shared schedule waits between opening the link and the offer.
  static const String prefKey = 'daret_pending_share';

  /// Notes the daret in [url], if there is a valid one. The latest link wins.
  static Future<void> remember(Uri url) async {
    final String? payload = DaretLink.payloadIn(url);
    if (DaretLink.decode(payload) == null) return;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(prefKey, payload!);
    } catch (_) {
      // No store (private browsing): the daret is simply not carried.
    }
  }

  /// The waiting schedule, or null.
  static Future<SharedDaret?> read() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      return DaretLink.decode(p.getString(prefKey));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(prefKey);
    } catch (_) {
      // Best effort.
    }
  }
}
