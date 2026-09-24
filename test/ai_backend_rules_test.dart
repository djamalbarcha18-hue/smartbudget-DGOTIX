import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/assistant/application/ai_backend.dart';

void main() {
  AiBackend? pick({
    required bool key,
    required bool pro,
    required bool gateway,
  }) =>
      AiBackendRules.choose(
          keyConnected: key, byokAllowed: pro, gatewayAvailable: gateway);

  test('PRO with a key uses the key', () {
    expect(pick(key: true, pro: true, gateway: true), AiBackend.byok);
    expect(pick(key: true, pro: true, gateway: false), AiBackend.byok);
  });

  test('a saved key is ignored below PRO: the plan quota applies', () {
    expect(pick(key: true, pro: false, gateway: true), AiBackend.gateway);
    expect(pick(key: true, pro: false, gateway: false), isNull);
  });

  test('without a key the gateway answers when available', () {
    expect(pick(key: false, pro: true, gateway: true), AiBackend.gateway);
    expect(pick(key: false, pro: false, gateway: true), AiBackend.gateway);
    expect(pick(key: false, pro: false, gateway: false), isNull);
  });
}
