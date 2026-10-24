import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/offers/domain/partner_offer.dart';

/// The partners' offers: the app's own file (empty until partners sign),
/// plus made-up samples in development builds.
final partnerOffersProvider = FutureProvider<List<PartnerOffer>>((ref) async {
  final List<PartnerOffer> out = <PartnerOffer>[];
  try {
    final Map<String, dynamic> j = jsonDecode(
            await rootBundle.loadString('assets/data/partner_offers.json'))
        as Map<String, dynamic>;
    for (final dynamic o in (j['offers'] as List<dynamic>?) ?? <dynamic>[]) {
      final PartnerOffer? offer =
          o is Map<String, dynamic> ? PartnerOffer.fromJson(o) : null;
      if (offer != null) out.add(offer);
    }
  } catch (_) {
    // No offers.
  }
  if (AppEnv.demoOffers) out.addAll(demoOffers);
  return out;
});

/// A paying Pro subscriber (not the free launch access): they see no
/// offers at all.
final paidProProvider = Provider<bool>((ref) {
  final Entitlement e = ref.watch(remoteEntitlementProvider).valueOrNull ??
      ref.watch(entitlementProvider);
  return e.effectivePlanAt(AppClock.now()) == Plan.pro;
});

/// Whether offers show at all.
final offersOnProvider = Provider<bool>((ref) =>
    AppEnv.smartTrip && AppEnv.partnerOffers && !ref.watch(paidProProvider));

/// Offers the user hid, and when (they stay away 30 days).
final hiddenOffersProvider =
    NotifierProvider<HiddenOffersController, Map<String, DateTime>>(
        HiddenOffersController.new);

class HiddenOffersController extends Notifier<Map<String, DateTime>> {
  static const String _key = 'sb_offers_hidden';

  @override
  Map<String, DateTime> build() {
    _load();
    return const <String, DateTime>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null) return;
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      state = <String, DateTime>{
        ...state,
        for (final MapEntry<String, dynamic> e in j.entries)
          if (DateTime.tryParse('${e.value}') case final DateTime d) e.key: d,
      };
    } catch (_) {}
  }

  Future<void> hide(String id) async {
    state = <String, DateTime>{...state, id: AppClock.now()};
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode(<String, String>{
            for (final MapEntry<String, DateTime> e in state.entries)
              e.key: e.value.toIso8601String(),
          }));
    } catch (_) {}
  }
}

/// Made-up samples for development builds (no real company, a placeholder
/// link): they show where and how offers appear.
const List<PartnerOffer> demoOffers = <PartnerOffer>[
  PartnerOffer(
    id: 'demo-esim',
    partner: 'Sample eSIM',
    kind: OfferKind.esim,
    title: <String, String>{
      'ar': 'إنترنت طوال رحلتك دون شريحة جديدة',
      'en': 'Internet for the whole trip, no new SIM',
    },
    body: <String, String>{
      'ar': 'باقة بيانات eSIM تفعّلها قبل السفر.',
      'en': 'A data eSIM you activate before you fly.',
    },
    url: 'https://example.com/esim',
  ),
  PartnerOffer(
    id: 'demo-insurance',
    partner: 'Sample insurer',
    kind: OfferKind.insurance,
    title: <String, String>{
      'ar': 'تأمين سفر لراحة بالك',
      'en': 'Travel insurance, for peace of mind',
    },
    body: <String, String>{
      'ar': 'يغطي العلاج والأمتعة والإلغاء.',
      'en': 'Covers care, luggage and cancellation.',
    },
    url: 'https://example.com/insurance',
  ),
  PartnerOffer(
    id: 'demo-hotel',
    partner: 'Sample hotels',
    kind: OfferKind.hotel,
    title: <String, String>{
      'ar': 'فنادق شريكة في وجهتك',
      'en': 'Partner hotels where you are going',
    },
    body: <String, String>{
      'ar': 'أسعار خاصة لمستخدمي SmartBudget.',
      'en': 'Special prices for SmartBudget users.',
    },
    url: 'https://example.com/hotels',
  ),
  PartnerOffer(
    id: 'demo-airline',
    partner: 'Sample airline',
    kind: OfferKind.airline,
    title: <String, String>{
      'ar': 'رحلات طيران إلى وجهتك',
      'en': 'Flights to where you are going',
    },
    body: <String, String>{
      'ar': 'قارن المواعيد واحجز مباشرة.',
      'en': 'Compare times and book directly.',
    },
    url: 'https://example.com/flights',
  ),
  PartnerOffer(
    id: 'demo-agency',
    partner: 'Sample agency',
    kind: OfferKind.agency,
    title: <String, String>{
      'ar': 'باقات عمرة منظّمة',
      'en': 'Organized Umrah packages',
    },
    body: <String, String>{
      'ar': 'طيران وإقامة قرب الحرم في باقة واحدة.',
      'en': 'Flights and a stay near the Haram in one package.',
    },
    url: 'https://example.com/umrah',
    destinations: <String>{'mecca', 'medina'},
  ),
  PartnerOffer(
    id: 'demo-transport',
    partner: 'Sample rides',
    kind: OfferKind.transport,
    title: <String, String>{
      'ar': 'من المطار إلى الفندق بسعر ثابت',
      'en': 'Airport to hotel, at a fixed price',
    },
    body: <String, String>{
      'ar': 'احجز توصيلتك مسبقًا.',
      'en': 'Book your ride ahead.',
    },
    url: 'https://example.com/rides',
  ),
  PartnerOffer(
    id: 'demo-restaurant',
    partner: 'Sample food',
    kind: OfferKind.restaurant,
    title: <String, String>{
      'ar': 'مطاعم قريبة منك بخصم',
      'en': 'Restaurants near you, with a discount',
    },
    body: <String, String>{
      'ar': 'اعرض الرمز في المطعم.',
      'en': 'Show the code at the restaurant.',
    },
    url: 'https://example.com/food',
  ),
];
