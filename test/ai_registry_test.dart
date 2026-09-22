import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/ai/application/ai_config.dart';
import 'package:smartbudget/features/ai/application/model_router.dart';
import 'package:smartbudget/features/ai/domain/ai_errors.dart';
import 'package:smartbudget/features/ai/domain/ai_registry.dart';

void main() {
  group('ModelRegistry', () {
    test('no retired model is offered as active', () {
      for (final AiProviderId p in AiProviderId.values) {
        for (final AiModel m in ModelRegistry.activeFor(p)) {
          expect(m.isActive, isTrue, reason: '${m.id} should be active');
          expect(m.status, isNot(AiModelStatus.shutdown));
          expect(m.status, isNot(AiModelStatus.deprecated));
        }
      }
    });

    test('Gemini default is a live alias, not a retired model', () {
      expect(ModelRegistry.defaultIdFor(AiProviderId.google),
          'gemini-flash-latest');
      expect(ModelRegistry.activeIdsFor(AiProviderId.google),
          isNot(contains('gemini-2.0-flash')));
      expect(ModelRegistry.activeIdsFor(AiProviderId.google),
          isNot(contains('gemini-1.5-flash')));
    });

    test('migration maps retired ids to a live replacement', () {
      expect(ModelRegistry.resolveUsableId(AiProviderId.google, 'gemini-2.0-flash'),
          'gemini-flash-latest');
      expect(
          ModelRegistry.resolveUsableId(
              AiProviderId.google, 'gemini-2.0-flash-lite'),
          'gemini-flash-lite-latest');
      // A still-usable id is kept as-is.
      expect(
          ModelRegistry.resolveUsableId(AiProviderId.google, 'gemini-2.5-flash'),
          'gemini-2.5-flash');
      // Null / unknown → provider default.
      expect(ModelRegistry.resolveUsableId(AiProviderId.google, null),
          'gemini-flash-latest');
      expect(ModelRegistry.resolveUsableId(AiProviderId.google, 'made-up'),
          'gemini-flash-latest');
    });
  });

  group('ModelRouter', () {
    const AiConfig cfg = AiConfig();

    test('receipt scan only routes to image + structured models', () {
      final List<AiModel> c = ModelRouter.candidatesFor(
          AiTaskType.receiptScan, cfg);
      expect(c, isNotEmpty);
      for (final AiModel m in c) {
        expect(m.supportsImage, isTrue);
        expect(m.supportsStructured, isTrue);
      }
    });

    test('chat has candidates and prefers the connected provider first', () {
      final List<AiModel> c = ModelRouter.candidatesFor(AiTaskType.chat, cfg,
          preferred: AiProviderId.google);
      expect(c, isNotEmpty);
      expect(c.first.provider, AiProviderId.google);
    });

    test('provider kill switch removes that provider from routing', () {
      final AiConfig off =
          cfg.copyWith(disabledProviders: <AiProviderId>{AiProviderId.google});
      final List<AiModel> c = ModelRouter.candidatesFor(AiTaskType.chat, off);
      expect(c.any((AiModel m) => m.provider == AiProviderId.google), isFalse);
    });

    test('model kill switch removes just that model', () {
      final AiConfig off =
          cfg.copyWith(disabledModels: <String>{'gemini-flash-latest'});
      final List<AiModel> c = ModelRouter.providerCandidates(
          AiProviderId.google, AiTaskType.chat, off);
      expect(c.any((AiModel m) => m.id == 'gemini-flash-latest'), isFalse);
    });
  });

  group('AiError policy', () {
    test('permanent errors do not fail over', () {
      expect(AiErrorKindX.fromHttp(401).isRetryable, isFalse);
      expect(AiErrorKindX.fromHttp(400).isRetryable, isFalse);
      expect(AiErrorKindX.fromHttp(404).isRetryable, isFalse);
      expect(AiErrorKind.invalidApiKey.isRetryable, isFalse);
      expect(AiErrorKind.unsupportedCapability.isRetryable, isFalse);
    });

    test('transient errors may fail over', () {
      expect(AiErrorKindX.fromHttp(503).isRetryable, isTrue);
      expect(AiErrorKindX.fromHttp(500).isRetryable, isTrue);
      expect(AiErrorKindX.fromHttp(429).isRetryable, isTrue);
      expect(AiErrorKindX.fromHttp(408).isRetryable, isTrue);
    });

    test('429 with quota text classifies as quotaExceeded', () {
      expect(AiErrorKindX.fromHttp(429, message: 'quota exceeded'),
          AiErrorKind.quotaExceeded);
    });
  });
}
