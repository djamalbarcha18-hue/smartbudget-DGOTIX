import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/shell/nav_seen.dart';

void main() {
  test('a "new" page, once opened, stays seen', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(navSeenProvider), isEmpty);
    await c.read(navSeenProvider.notifier).markSeen('/zakat');
    expect(c.read(navSeenProvider), <String>{'/zakat'});
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getStringList('sb_nav_seen'), <String>['/zakat']);

    // Read back on the next start.
    final ProviderContainer next = ProviderContainer();
    addTearDown(next.dispose);
    next.read(navSeenProvider);
    await Future<void>.delayed(Duration.zero);
    expect(next.read(navSeenProvider), contains('/zakat'));
  });
}
