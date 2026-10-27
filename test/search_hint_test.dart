import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/shell/app_top_bar.dart';

void main() {
  test('the search shortcut as each computer writes it, none on touch', () {
    expect(searchShortcutLabel(TargetPlatform.windows), 'Ctrl K');
    expect(searchShortcutLabel(TargetPlatform.linux), 'Ctrl K');
    expect(searchShortcutLabel(TargetPlatform.macOS), '⌘ K');
    expect(searchShortcutLabel(TargetPlatform.android), isNull);
    expect(searchShortcutLabel(TargetPlatform.iOS), isNull);
  });
}
