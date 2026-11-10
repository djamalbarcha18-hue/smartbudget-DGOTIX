import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/referrals/application/referral_claim.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_link.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

/// A server that records what it was asked, and answers as told.
class _FakeService implements ReferralService {
  _FakeService({this.claimAnswer = true});
  final bool claimAnswer;
  final List<String> claimed = <String>[];
  int completes = 0;

  @override
  Future<bool> claim(String code) async {
    claimed.add(code);
    return claimAnswer;
  }

  @override
  Future<bool> complete() async {
    completes++;
    return true;
  }

  @override
  Future<String?> code() async => 'AB23CD45';
  @override
  Future<ReferralProgress> progress() async => ReferralProgress.none;
  @override
  Future<Set<ReferralReward>> grants() async => const <ReferralReward>{};
  @override
  Future<bool> choose(ReferralReward reward) async => true;
  @override
  Future<DateTime?> welcomeGiftGrantedAt() async => null;
}

const String _app = 'https://smartbudget.dgotix.com/';

void main() {
  group('the invite link', () {
    test('carries the code', () {
      expect(ReferralLink.invite(_app, 'AB23CD45'),
          'https://smartbudget.dgotix.com/?ref=AB23CD45');
    });

    test('a bad code gives the plain link, never a broken one', () {
      for (final String? bad in <String?>[
        null,
        '',
        'short',
        'ab23cd45!',
        '01IL0000'
      ]) {
        expect(ReferralLink.invite(_app, bad), _app, reason: '$bad');
      }
    });

    test('a code is read back from the query', () {
      expect(ReferralLink.codeIn(Uri.parse('$_app?ref=AB23CD45')), 'AB23CD45');
    });

    test('and from the fragment, where the app routes', () {
      expect(ReferralLink.codeIn(Uri.parse('$_app#/plans?ref=ab23cd45')),
          'AB23CD45',
          reason: 'lower case is accepted and normalised');
    });

    test('a link with no code reads as none', () {
      expect(ReferralLink.codeIn(Uri.parse(_app)), isNull);
      expect(ReferralLink.codeIn(Uri.parse('$_app?utm=x')), isNull);
      expect(ReferralLink.codeIn(Uri.parse('$_app?ref=nope')), isNull,
          reason: 'a stray parameter must not become a server call');
    });

    test('the alphabet excludes the characters people mistype', () {
      for (final String c in <String>['0', 'O', '1', 'I', 'L']) {
        expect(ReferralLink.looksValid('AAAA${c}AAA'), isFalse, reason: c);
      }
    });

    test('existing query parameters survive', () {
      final String out = ReferralLink.invite('$_app?utm=flyer', 'AB23CD45');
      expect(out, contains('utm=flyer'));
      expect(out, contains('ref=AB23CD45'));
    });
  });

  group('carrying the invite to the new account', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    Future<String?> stored() async => (await SharedPreferences.getInstance())
        .getString(ReferralClaim.prefKey);

    test('a code in the address is kept until there is an account', () async {
      final _FakeService s = _FakeService();
      await ReferralClaim(s).remember(Uri.parse('$_app?ref=AB23CD45'));
      expect(await stored(), 'AB23CD45');
      expect(s.claimed, isEmpty, reason: 'nobody has signed up yet');
    });

    test('the first invite wins; a later link does not replace it', () async {
      final ReferralClaim c = ReferralClaim(_FakeService());
      await c.remember(Uri.parse('$_app?ref=AB23CD45'));
      await c.remember(Uri.parse('$_app?ref=ZZ99YY88'));
      expect(await stored(), 'AB23CD45');
    });

    test('signing in redeems it once, then forgets it', () async {
      final _FakeService s = _FakeService();
      final ReferralClaim c = ReferralClaim(s);
      await c.remember(Uri.parse('$_app?ref=AB23CD45'));

      expect(await c.redeem(), isTrue);
      expect(s.claimed, <String>['AB23CD45']);
      expect(await stored(), isNull);

      // A second sign-in must not send it again.
      expect(await c.redeem(), isFalse);
      expect(s.claimed.length, 1);
    });

    test('a refused code is dropped rather than retried forever', () async {
      final _FakeService s = _FakeService(claimAnswer: false);
      final ReferralClaim c = ReferralClaim(s);
      await c.remember(Uri.parse('$_app?ref=AB23CD45'));
      expect(await c.redeem(), isFalse);
      expect(await stored(), isNull);
    });

    test('activation is reported on every sign-in, invite or not', () async {
      final _FakeService s = _FakeService();
      final ReferralClaim c = ReferralClaim(s);
      await c.redeem();
      await c.redeem();
      expect(s.completes, 2,
          reason: 'a mailbox confirmed later still has to count');
      expect(s.claimed, isEmpty);
    });
  });

  group('progress', () {
    test('counts towards three and stops there', () {
      expect(const ReferralProgress(joined: 1, activated: 0).remaining, 3);
      expect(const ReferralProgress(joined: 3, activated: 2).remaining, 1);
      expect(const ReferralProgress(joined: 9, activated: 5).remaining, 0);
      expect(const ReferralProgress(joined: 9, activated: 5).fraction, 1);
      expect(const ReferralProgress(joined: 3, activated: 3).earned, isTrue);
      expect(const ReferralProgress(joined: 9, activated: 2).earned, isFalse,
          reason: 'joining is not enough; they have to start using it');
    });
  });
}
