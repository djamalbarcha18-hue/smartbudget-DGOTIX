import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether category icons are drawn plain (grey, told apart by their shape)
/// instead of in their colours. Free for everyone; kept on the device. The
/// charts keep their colours: their slices cannot be told apart in grey.
final categoryIconsPlainProvider =
    NotifierProvider<CategoryIconsPlainController, bool>(
        CategoryIconsPlainController.new);

class CategoryIconsPlainController extends Notifier<bool> {
  static const String key = 'sb_category_icons_plain';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final bool? v = (await SharedPreferences.getInstance()).getBool(key);
      if (v == true) state = true;
    } catch (_) {
      // Keep the colours (also when the container ended before the read).
    }
  }

  Future<void> set(bool plain) async {
    state = plain;
    try {
      await (await SharedPreferences.getInstance()).setBool(key, plain);
    } catch (_) {}
  }
}
