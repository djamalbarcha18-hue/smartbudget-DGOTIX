import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

void main() {
  group('Plan ordering', () {
    test('ranks ascend free < basic < pro', () {
      expect(Plan.free.index < Plan.basic.index, isTrue);
      expect(Plan.basic.index < Plan.pro.index, isTrue);
    });

    test('atLeast is a rank compare', () {
      expect(Plan.pro.atLeast(Plan.basic), isTrue);
      expect(Plan.basic.atLeast(Plan.pro), isFalse);
      expect(Plan.free.atLeast(Plan.free), isTrue);
    });

    test('storage round-trips; unknown ⇒ free', () {
      for (final Plan p in Plan.values) {
        expect(PlanX.fromStorage(p.storageId), p);
      }
      expect(PlanX.fromStorage('nope'), Plan.free);
      expect(PlanX.fromStorage(null), Plan.free);
    });

    test('locked display prices match docs/PRICING.md', () {
      expect(Plan.free.priceUsd(BillingPeriod.monthly), 0);
      expect(Plan.basic.priceUsd(BillingPeriod.monthly), 7.99);
      expect(Plan.basic.priceUsd(BillingPeriod.yearly), 50);
      expect(Plan.pro.priceUsd(BillingPeriod.monthly), 14.99);
      expect(Plan.pro.priceUsd(BillingPeriod.yearly), 119);
      expect(Plan.free.priceUsd(BillingPeriod.yearly), 0);
    });
  });

  group('FeatureCatalog quotas (locked)', () {
    test('DGOTIX AI: 5 lifetime / 30 / 150', () {
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.free)!.limit, 5);
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.free)!.window,
          QuotaWindow.lifetime);
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.basic)!.limit, 30);
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.pro)!.limit, 150);
    });

    test('Cloud OCR: 3 lifetime / 15 / 100', () {
      expect(FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.free)!.limit, 3);
      expect(FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.basic)!.limit, 15);
      expect(FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.pro)!.limit, 100);
    });

    test('boolean gates have no quota and a min tier', () {
      expect(FeatureCatalog.quotaFor(Feature.advancedReports, Plan.pro), isNull);
      expect(FeatureCatalog.minTierFor(Feature.advancedReports), Plan.basic);
      expect(FeatureCatalog.minTierFor(Feature.prioritySupport), Plan.pro);
    });

    test('nextTierWithMore points upward until the top', () {
      expect(FeatureCatalog.nextTierWithMore(Feature.dgotixAi, Plan.free),
          Plan.basic);
      expect(FeatureCatalog.nextTierWithMore(Feature.dgotixAi, Plan.basic),
          Plan.pro);
      expect(FeatureCatalog.nextTierWithMore(Feature.dgotixAi, Plan.pro),
          isNull);
    });
  });

  group('Salary split is a paid feature', () {
    test('FREE is asked to upgrade to BASIC', () {
      final GateDecision d =
          FeatureGate.evaluate(Feature.salarySplit, plan: Plan.free);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.needsUpgrade);
      expect(d.suggestedTier, Plan.basic);
    });

    test('BASIC and PRO can use it', () {
      expect(FeatureGate.evaluate(Feature.salarySplit, plan: Plan.basic).allowed,
          isTrue);
      expect(FeatureGate.evaluate(Feature.salarySplit, plan: Plan.pro).allowed,
          isTrue);
    });
  });

  group('FeatureGate.evaluate', () {
    test('boolean gate below min tier ⇒ needsUpgrade to that tier', () {
      final GateDecision d =
          FeatureGate.evaluate(Feature.advancedReports, plan: Plan.free);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.needsUpgrade);
      expect(d.suggestedTier, Plan.basic);
    });

    test('boolean gate at/above min tier ⇒ allowed', () {
      expect(
          FeatureGate.evaluate(Feature.advancedReports, plan: Plan.basic)
              .allowed,
          isTrue);
      expect(
          FeatureGate.evaluate(Feature.prioritySupport, plan: Plan.pro).allowed,
          isTrue);
    });

    test('metered under budget ⇒ allowed with remaining', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.basic, used: 10);
      expect(d.allowed, isTrue);
      expect(d.limit, 30);
      expect(d.remaining, 20);
      expect(d.isMetered, isTrue);
    });

    test('metered at budget ⇒ quotaReached + upgrade tier', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.free, used: 5);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.quotaReached);
      expect(d.remaining, 0);
      expect(d.suggestedTier, Plan.basic);
    });

    test('usedFraction drives the 80/90/100 nudges', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.basic, used: 24);
      expect(d.usedFraction, closeTo(0.8, 1e-9));
    });

    test('overuse is clamped, never negative remaining', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.free, used: 99);
      expect(d.remaining, 0);
      expect(d.usedFraction, 1.0);
    });
  });

  group('Entitlement', () {
    test('defaults to free; effective plan is free', () {
      final Entitlement e = Entitlement.free;
      expect(e.plan, Plan.free);
      expect(e.effectivePlanAt(DateTime(2026, 9, 22)), Plan.free);
    });

    test('active trial lifts the effective plan', () {
      final DateTime now = DateTime(2026, 9, 22);
      final Entitlement e = Entitlement(
        plan: Plan.free,
        trialPlan: Plan.pro,
        trialExpiresAt: now.add(const Duration(days: 3)),
      );
      expect(e.trialActiveAt(now), isTrue);
      expect(e.effectivePlanAt(now), Plan.pro);
    });

    test('expired trial falls back to the paid plan', () {
      final DateTime now = DateTime(2026, 9, 22);
      final Entitlement e = Entitlement(
        plan: Plan.basic,
        trialPlan: Plan.pro,
        trialExpiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(e.trialActiveAt(now), isFalse);
      expect(e.effectivePlanAt(now), Plan.basic);
    });

    test('JSON round-trips', () {
      final DateTime exp = DateTime.utc(2026, 10, 1, 12);
      final Entitlement e = Entitlement(
        plan: Plan.pro,
        trialPlan: Plan.pro,
        trialExpiresAt: exp,
      );
      final Entitlement back = Entitlement.fromJson(e.toJson());
      expect(back.plan, Plan.pro);
      expect(back.trialPlan, Plan.pro);
      expect(back.trialExpiresAt!.toUtc(), exp);
    });
  });
}
