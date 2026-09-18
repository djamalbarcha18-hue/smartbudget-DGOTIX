import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/features/shell/splash_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('App boots and shows the splash while auth resolves',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SmartBudgetApp()),
    );

    // One frame: auth status is still `unknown`, so the router shows the splash.
    // Avoid pumpAndSettle — the splash spinner animates forever and async
    // SVG/font loading would make the test time-dependent.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
