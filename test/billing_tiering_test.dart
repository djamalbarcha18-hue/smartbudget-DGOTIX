import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

void main() {
  group('Plan ordering', () {
    test('two plans: free < pro', () {
      expect(Plan.values, <Plan>[Plan.free, Plan.pro]);
      expect(Plan.free.index < Plan.pro.index, isTrue);
    });

    test('atLeast is a rank compare', () {
      expect(Plan.pro.atLeast(Plan.free), isTrue);
      expect(Plan.free.atLeast(Plan.pro), isFalse);
      expect(Plan.free.atLeast(Plan.free), isTrue);
    });

    test('storage round-trips; unknown ⇒ free', () {
      for (final Plan p in Plan.values) {
        expect(PlanX.fromStorage(p.storageId), p);
      }
      expect(PlanX.fromStorage('nope'), Plan.free);
      // BASIC was merged into PRO.
      expect(PlanX.fromStorage('basic'), Plan.pro);
      expect(PlanX.fromStorage(null), Plan.free);
    });

    test('locked display prices match docs/PRICING.md', () {
      expect(Plan.free.priceUsd(BillingPeriod.monthly), 0);
      expect(Plan.pro.priceUsd(BillingPeriod.monthly), 9.99);
      expect(Plan.pro.priceUsd(BillingPeriod.yearly), 59.99);
      expect(Plan.free.priceUsd(BillingPeriod.yearly), 0);
    });
  });

  group('FeatureCatalog quotas (locked)', () {
    test('DGOTIX AI: 5 lifetime / 100 a month', () {
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.free)!.limit, 5);
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.free)!.window,
          QuotaWindow.lifetime);
      expect(FeatureCatalog.quotaFor(Feature.dgotixAi, Plan.pro)!.limit, 100);
    });

    test('Cloud OCR: 3 / 50 a month', () {
      expect(FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.free)!.limit, 3);
      expect(FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.pro)!.limit, 50);
    });

    test('boolean gates have no quota and a min tier', () {
      expect(FeatureCatalog.quotaFor(Feature.advancedReports, Plan.pro), isNull);
      expect(FeatureCatalog.minTierFor(Feature.advancedReports), Plan.pro);
      expect(FeatureCatalog.minTierFor(Feature.prioritySupport), Plan.pro);
    });

    test('nextTierWithMore points upward until the top', () {
      expect(FeatureCatalog.nextTierWithMore(Feature.dgotixAi, Plan.free),
          Plan.pro);
      expect(FeatureCatalog.nextTierWithMore(Feature.dgotixAi, Plan.pro),
          isNull);
    });
  });

  group('Salary split is a paid feature', () {
    test('FREE is asked to upgrade to Pro', () {
      final GateDecision d =
          FeatureGate.evaluate(Feature.salarySplit, plan: Plan.free);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.needsUpgrade);
      expect(d.suggestedTier, Plan.pro);
    });

    test('Pro can use it', () {
      expect(FeatureGate.evaluate(Feature.salarySplit, plan: Plan.pro).allowed,
          isTrue);
    });
  });

  group('Smart alerts are a Pro feature', () {
    test('FREE is asked to upgrade to Pro', () {
      for (final Plan p in <Plan>[Plan.free]) {
        final GateDecision d =
            FeatureGate.evaluate(Feature.smartAlerts, plan: p);
        expect(d.allowed, isFalse);
        expect(d.reason, GateReason.needsUpgrade);
        expect(d.suggestedTier, Plan.pro);
      }
    });

    test('Pro gets it, billed monthly or yearly', () {
      for (final BillingPeriod? period in <BillingPeriod?>[
        null,
        BillingPeriod.monthly,
        BillingPeriod.yearly,
      ]) {
        expect(
            FeatureGate.evaluate(Feature.smartAlerts,
                    plan: Plan.pro, period: period)
                .allowed,
            isTrue);
      }
    });
  });

  group('Counted features (FREE limits)', () {
    test('FREE has a few, then is asked to upgrade to Pro', () {
      const Map<Feature, int> freeLimits = <Feature, int>{
        Feature.wallets: 2,
        Feature.categoryBudgets: 5,
        Feature.goals: 2,
        Feature.debts: 2,
        Feature.darets: 1,
        Feature.seasons: 1,
        Feature.recurringRules: 5,
      };
      freeLimits.forEach((Feature f, int limit) {
        expect(
            FeatureGate.evaluate(f, plan: Plan.free, used: limit - 1).allowed,
            isTrue,
            reason: '$f below the limit');
        final GateDecision d =
            FeatureGate.evaluate(f, plan: Plan.free, used: limit);
        expect(d.allowed, isFalse, reason: '$f at the limit');
        expect(d.reason, GateReason.quotaReached);
        expect(d.window, QuotaWindow.items);
        expect(d.suggestedTier, Plan.pro);
      });
    });

    test('Pro has no limit', () {
      for (final Plan p in <Plan>[Plan.pro]) {
        for (final Feature f in <Feature>[
          Feature.wallets,
          Feature.goals,
          Feature.recurringRules,
        ]) {
          expect(FeatureGate.evaluate(f, plan: p, used: 500).allowed, isTrue);
        }
      }
    });

    test('every paid feature: FREE is asked to go Pro, Pro has it',
        () {
      for (final Feature f in <Feature>[
        Feature.multiCurrency,
        Feature.advancedReports,
        Feature.parallelRates,
        Feature.cloudSyncFull,
        Feature.healthDetails,
        Feature.salarySplit,
        Feature.reportPdf,
        Feature.reportTrends,
        Feature.smartAlerts,
        Feature.portfolioFull,
        Feature.projects,
        Feature.prioritySupport,
        Feature.tripPhotoCard,
        Feature.proThemes,
      ]) {
        final GateDecision d = FeatureGate.evaluate(f, plan: Plan.free);
        expect(d.allowed, isFalse, reason: '$f');
        expect(d.suggestedTier, Plan.pro, reason: '$f');
        expect(FeatureGate.evaluate(f, plan: Plan.pro).allowed, isTrue);
      }
    });
  });

  group('FeatureGate.evaluate', () {
    test('boolean gate below min tier ⇒ needsUpgrade to that tier', () {
      final GateDecision d =
          FeatureGate.evaluate(Feature.advancedReports, plan: Plan.free);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.needsUpgrade);
      expect(d.suggestedTier, Plan.pro);
    });

    test('boolean gate at/above min tier ⇒ allowed', () {
      expect(
          FeatureGate.evaluate(Feature.advancedReports, plan: Plan.pro)
              .allowed,
          isTrue);
      expect(
          FeatureGate.evaluate(Feature.prioritySupport, plan: Plan.pro).allowed,
          isTrue);
    });

    test('metered under budget ⇒ allowed with remaining', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.pro, used: 10);
      expect(d.allowed, isTrue);
      expect(d.limit, 100);
      expect(d.remaining, 90);
      expect(d.isMetered, isTrue);
    });

    test('metered at budget ⇒ quotaReached + upgrade tier', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.free, used: 5);
      expect(d.allowed, isFalse);
      expect(d.reason, GateReason.quotaReached);
      expect(d.remaining, 0);
      expect(d.suggestedTier, Plan.pro);
    });

    test('usedFraction drives the 80/90/100 nudges', () {
      final GateDecision d = FeatureGate.evaluate(Feature.dgotixAi,
          plan: Plan.pro, used: 80);
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
        plan: Plan.free,
        trialPlan: Plan.pro,
        trialExpiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(e.trialActiveAt(now), isFalse);
      expect(e.effectivePlanAt(now), Plan.free);
    });

    test('billing period round-trips; FREE never has a paid period', () {
      const Entitlement yearly =
          Entitlement(plan: Plan.pro, period: BillingPeriod.yearly);
      expect(Entitlement.fromJson(yearly.toJson()).paidPeriod,
          BillingPeriod.yearly);
      expect(
          const Entitlement(period: BillingPeriod.yearly).paidPeriod, isNull);
      expect(Entitlement.fromJson(const <String, dynamic>{'plan': 'pro'}).period,
          isNull);
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
