import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/offers/application/offers_controller.dart';
import 'package:smartbudget/features/offers/domain/partner_offer.dart';
import 'package:smartbudget/features/offers/presentation/partner_offer_card.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  final DateTime now = DateTime(2026, 6, 15, 12);
  final DateTime today = DateTime(2026, 6, 15);
  const Destination mecca = Destination(
      id: 'mecca',
      names: <String, String>{'en': 'Mecca'},
      country: 'SA',
      icon: 'mosque',
      order: 1);
  const Destination rome = Destination(
      id: 'rome',
      names: <String, String>{'en': 'Rome'},
      country: 'IT',
      icon: 'columns',
      order: 2);

  Trip trip(
          {int from = 5, int to = 10, TripKind kind = TripKind.independent}) =>
      Trip(
        id: 'a',
        name: 'Trip',
        destination: 'Rome',
        start: today.add(Duration(days: from)),
        end: today.add(Duration(days: to)),
        createdAt: DateTime(2026),
        kind: kind,
      );

  PartnerOffer? pick(OfferSlot slot, Trip t,
          {Destination? place = rome,
          Map<String, DateTime> hidden = const <String, DateTime>{},
          TripReport? report,
          List<PartnerOffer> offers = demoOffers}) =>
      OfferMatcher.pick(
          offers: offers,
          slot: slot,
          trip: t,
          place: place,
          now: now,
          hidden: hidden,
          report: report);

  group('one offer, at the moment it helps', () {
    test('two weeks before: the eSIM first; nothing earlier', () {
      expect(pick(OfferSlot.beforeTrip, trip(from: 5))!.kind, OfferKind.esim);
      expect(pick(OfferSlot.beforeTrip, trip(from: 40, to: 45)), isNull);
    });

    test('internet already paid for: insurance comes next', () {
      final Trip t = trip(from: 5);
      final TripReport r = TripReport.of(
          t,
          <Transaction>[
            Transaction(
              id: 'x',
              date: today,
              type: TransactionType.expense,
              category: 'الاتصالات والإنترنت',
              amount: const Money(2000, 'USD'),
              description: '',
              tripId: 'a',
              createdAt: DateTime(2026),
            ),
          ],
          now,
          currency: 'USD');
      expect(
          pick(OfferSlot.beforeTrip, t, report: r)!.kind, OfferKind.insurance);
    });

    test('during the trip; never after it', () {
      expect(pick(OfferSlot.duringTrip, trip(from: -2, to: 3)), isNotNull);
      expect(pick(OfferSlot.duringTrip, trip(from: 5)), isNull);
      final Trip ended = trip(from: -10, to: -3);
      for (final OfferSlot s in OfferSlot.values) {
        expect(pick(s, ended), isNull, reason: '$s');
      }
    });

    test('in the editor: a hotel; an agency for an organized trip there', () {
      expect(pick(OfferSlot.tripEditor, trip())!.kind, OfferKind.hotel);
      expect(
          pick(OfferSlot.tripEditor, trip(kind: TripKind.organized),
                  place: mecca)!
              .kind,
          OfferKind.agency);
      // The Umrah packages are for Mecca and Medina only.
      expect(pick(OfferSlot.tripEditor, trip(kind: TripKind.organized))!.kind,
          OfferKind.hotel);
    });

    test('hidden: away for 30 days, then back', () {
      final Map<String, DateTime> hidden = <String, DateTime>{
        'demo-esim': now.subtract(const Duration(days: 3)),
      };
      expect(pick(OfferSlot.beforeTrip, trip(), hidden: hidden)!.kind,
          OfferKind.insurance);
      final Map<String, DateTime> old = <String, DateTime>{
        'demo-esim': now.subtract(const Duration(days: 31)),
      };
      expect(pick(OfferSlot.beforeTrip, trip(), hidden: old)!.kind,
          OfferKind.esim);
    });

    test('no offers: nothing shows', () {
      expect(pick(OfferSlot.beforeTrip, trip(), offers: const <PartnerOffer>[]),
          isNull);
    });
  });

  group('Pro: booking suggestions, partners from home', () {
    PartnerOffer offer(String id,
            {OfferAudience audience = OfferAudience.everyone,
            Set<String> home = const <String>{}}) =>
        PartnerOffer(
          id: id,
          partner: id,
          kind: OfferKind.airline,
          title: const <String, String>{'en': 'x'},
          body: const <String, String>{'en': 'y'},
          url: 'https://example.com/$id',
          audience: audience,
          homeCountries: home,
        );
    final List<PartnerOffer> offers = <PartnerOffer>[
      offer('ad'),
      offer('free-only', audience: OfferAudience.free),
      offer('pro'),
      offer('pro-perk', audience: OfferAudience.pro),
      offer('pro-home-sa', audience: OfferAudience.pro, home: <String>{'SA'}),
    ];
    String? id({required bool pro, String? home}) => OfferMatcher.pick(
          offers: offers,
          slot: OfferSlot.tripEditor,
          trip: trip(kind: TripKind.independent),
          place: rome,
          now: now,
          pro: pro,
          home: home,
          // Only airlines in this list: hide nothing, the hotel slot is empty.
        )?.id;

    test('Pro: a partner from their own country first, then Pro picks', () {
      expect(id(pro: true, home: 'SA'), 'pro-home-sa');
      expect(id(pro: true, home: 'MA'), 'pro-perk');
      expect(id(pro: true), 'pro-perk');
    });

    test('the free plan never gets the Pro picks', () {
      expect(<String?>{id(pro: false), id(pro: false, home: 'SA')},
          everyElement(isIn(<String>['ad', 'free-only'])));
    });

    test('Pro can turn the suggestions off', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = ProviderContainer(
          overrides: <Override>[paidProProvider.overrideWithValue(true)]);
      addTearDown(c.dispose);
      expect(c.read(offersOnProvider), isTrue);
      await c.read(proSuggestionsProvider.notifier).set(false);
      expect(c.read(offersOnProvider), isFalse);
    });

    test('home is the country of the main currency; none for the euro', () {
      for (final (String, String?) v in <(String, String?)>[
        ('SAR', 'SA'),
        ('MAD', 'MA'),
        ('EUR', null),
      ]) {
        final ProviderContainer c = ProviderContainer(overrides: <Override>[
          baseCurrencyProvider.overrideWith(() => _Base(v.$1)),
        ]);
        addTearDown(c.dispose);
        expect(c.read(homeCountryProvider), v.$2, reason: v.$1);
      }
    });
  });

  group('reading offers', () {
    test('only https links, known kinds; dates, places', () {
      final PartnerOffer o = PartnerOffer.fromJson(<String, dynamic>{
        'id': 'p1',
        'partner': 'P',
        'kind': 'hotel',
        'title': <String, String>{'en': 'Hotels', 'ar': 'فنادق'},
        'body': <String, String>{'en': 'Nice'},
        'url': 'https://partner.example/hotels?x=1',
        'countries': <String>['IT'],
        'until': '2026-06-01',
      })!;
      expect(o.isFor(rome), isTrue);
      expect(o.isFor(mecca), isFalse);
      expect(o.isFor(null), isFalse); // a typed place: only offers for anywhere
      expect(o.liveOn(today), isFalse); // over
      expect(PartnerOffer.text(o.body, 'fr'), 'Nice');
      expect(o.link().queryParameters['utm_source'], 'smartbudget');
      expect(o.link().queryParameters['x'], '1');
      expect(
          PartnerOffer.fromJson(<String, dynamic>{
            'id': 'p2',
            'kind': 'hotel',
            'url': 'http://insecure.example',
          }),
          isNull);
      expect(
          PartnerOffer.fromJson(<String, dynamic>{
            'id': 'p3',
            'kind': 'casino',
            'url': 'https://x.example',
          }),
          isNull);
    });
  });

  group('quiet, marked, and not for Pro', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    test('a paying Pro subscriber sees no ads (only Pro picks, if on)', () {
      final ProviderContainer pro = ProviderContainer(overrides: <Override>[
        paidProProvider.overrideWithValue(true),
        proSuggestionsProvider.overrideWith(_Off.new),
      ]);
      addTearDown(pro.dispose);
      expect(pro.read(offersOnProvider), isFalse);
      final ProviderContainer free = ProviderContainer(
          overrides: <Override>[paidProProvider.overrideWithValue(false)]);
      addTearDown(free.dispose);
      expect(free.read(offersOnProvider), isTrue); // debug build
    });

    testWidgets('says it is a partner offer, for which trip; can be hidden',
        (WidgetTester tester) async {
      bool hidden = false;
      await tester.pumpWidget(MaterialApp(
        theme: DsTheme.light(),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PartnerOfferCard(
              offer: demoOffers.first,
              place: 'Rome',
              onHide: () => hidden = true),
        ),
      ));
      expect(
          find.text('Partner offer · for your trip to Rome'), findsOneWidget);
      expect(find.text('See the offer'), findsOneWidget);
      // The partner's Pro perk, locked, on the free plan.
      expect(find.text('With Pro: 1 GB extra'), findsOneWidget);
      await tester.tap(find.byTooltip('Hide'));
      expect(hidden, isTrue);
      // Booking is with the partner: said on the card, and plainly the
      // first time the offer is opened (not part of SmartBudget or Pro).
      expect(find.text('Booked with the partner'), findsOneWidget);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.tap(find.text('See the offer'));
      await tester.pumpAndSettle();
      expect(find.text('Before you go to the partner'), findsOneWidget);
      expect(
          find.textContaining(
              'not part of your SmartBudget subscription or the Pro plan'),
          findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Before you go to the partner'), findsNothing);
    });
  });
}

class _Off extends ProSuggestionsController {
  @override
  bool build() => false;
}

class _Base extends BaseCurrencyController {
  _Base(this.code);
  final String code;

  @override
  String build() => code;
}
