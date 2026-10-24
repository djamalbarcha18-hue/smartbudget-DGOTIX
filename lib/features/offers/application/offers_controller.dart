import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
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

/// Whether offers show at all: ads on the free plan; on Pro, booking
/// suggestions unless the subscriber turned them off.
final offersOnProvider = Provider<bool>((ref) =>
    AppEnv.smartTrip &&
    AppEnv.partnerOffers &&
    (!ref.watch(paidProProvider) || ref.watch(proSuggestionsProvider)));

/// The country the user lives in, as their main currency tells it (null for
/// a currency of many countries, like the euro).
final homeCountryProvider = Provider<String?>((ref) {
  final String c =
      Currencies.byCode(ref.watch(baseCurrencyProvider)).country.toUpperCase();
  return c.length == 2 && c != 'EU' ? c : null;
});

/// Pro: booking suggestions from partners on (default) or off.
final proSuggestionsProvider = NotifierProvider<ProSuggestionsController, bool>(
    ProSuggestionsController.new);

class ProSuggestionsController extends Notifier<bool> {
  static const String _key = 'sb_pro_suggestions';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final bool? v = p.getBool(_key);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_key, on);
    } catch (_) {}
  }
}

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
    perk: <String, String>{
      'ar': '1 جيغابايت إضافي',
      'en': '1 GB extra',
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
  // Pro: booking suggestions with a perk, and a partner from home.
  PartnerOffer(
    id: 'demo-pro-hotel',
    partner: 'Sample hotels',
    kind: OfferKind.hotel,
    audience: OfferAudience.pro,
    title: <String, String>{
      'ar': 'فنادق مختارة في وجهتك',
      'en': 'Hand-picked hotels where you are going',
    },
    body: <String, String>{
      'ar': 'احجز مباشرة من الشريك.',
      'en': 'Book directly with the partner.',
    },
    perk: <String, String>{
      'ar': 'خصم 10% لمشتركي Pro',
      'en': '10% off for Pro subscribers',
    },
    url: 'https://example.com/pro-hotels',
  ),
  PartnerOffer(
    id: 'demo-pro-airline-home',
    partner: 'Sample home airline',
    kind: OfferKind.airline,
    audience: OfferAudience.pro,
    homeCountries: <String>{'SA'},
    title: <String, String>{
      'ar': 'شركة طيران من بلدك إلى وجهتك',
      'en': 'An airline from your country to your destination',
    },
    body: <String, String>{
      'ar': 'رحلات مباشرة وحجز بعملتك.',
      'en': 'Direct flights, booked in your currency.',
    },
    perk: <String, String>{
      'ar': 'حقيبة إضافية مجانًا لمشتركي Pro',
      'en': 'A free extra bag for Pro subscribers',
    },
    url: 'https://example.com/home-airline',
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
