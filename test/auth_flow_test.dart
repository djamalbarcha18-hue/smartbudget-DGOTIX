import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/domain/auth_failure.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    // Keep the auth controller alive for the duration of the test.
    final ProviderSubscription<AuthState> sub =
        container.listen(authControllerProvider, (_, __) {});
    addTearDown(sub.close);
    addTearDown(container.dispose);
    return container;
  }

  test('starts unauthenticated with a clean session', () async {
    final ProviderContainer container = makeContainer();
    await _settle();
    expect(container.read(authControllerProvider).status,
        AuthStatus.unauthenticated);
  });

  test('sign in transitions to authenticated with the user', () async {
    final ProviderContainer container = makeContainer();
    await _settle();

    await container.read(authControllerProvider.notifier).signIn(
          email: 'djamal@example.com',
          password: 'secret123',
        );
    await _settle();

    final AuthState state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.user?.email, 'djamal@example.com');
  });

  test('sign out returns to unauthenticated', () async {
    final ProviderContainer container = makeContainer();
    await _settle();

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.com', password: 'secret123');
    await _settle();
    await container.read(authControllerProvider.notifier).signOut();
    await _settle();

    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  test('weak password is rejected with a typed failure', () async {
    final ProviderContainer container = makeContainer();
    await _settle();

    expect(
      () => container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: '123'),
      throwsA(
        isA<AuthFailure>().having(
          (AuthFailure f) => f.kind,
          'kind',
          AuthFailureKind.weakPassword,
        ),
      ),
    );
  });
}
