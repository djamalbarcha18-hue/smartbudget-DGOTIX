import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/money/number_style.dart';

/// How amounts are written (Settings → Region & currency), kept on this
/// device. [MoneyFormatter] reads it; the app applies a change everywhere at
/// once ([applyNumberStyle]).
final numberStyleProvider =
    NotifierProvider<NumberStyleController, NumberStyle>(
        NumberStyleController.new);

class NumberStyleController extends Notifier<NumberStyle> {
  static const String key = 'sb_number_style';

  @override
  NumberStyle build() {
    _load();
    return MoneyFormatter.style;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = NumberStyle.fromName(prefs.getString(key));
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> set(NumberStyle style) async {
    state = style;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, style.name);
    } catch (_) {
      // Shown for this session; saved next time.
    }
  }
}

/// Makes [style] the one amounts are written in and rebuilds every screen,
/// since amounts are formatted inside each widget's build.
void applyNumberStyle(NumberStyle style) {
  if (MoneyFormatter.style == style) return;
  MoneyFormatter.style = style;
  void mark(Element e) {
    e.markNeedsBuild();
    e.visitChildren(mark);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(mark);
}
