import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/daret/domain/daret_link.dart';

Daret _daret({
  String name = 'جمعية العائلة',
  List<String> members = const <String>['أحمد', 'Sara', 'ليلى', 'Omar'],
  DaretFrequency frequency = DaretFrequency.monthly,
}) =>
    Daret(
      id: 'daret-1',
      name: name,
      contribution: const Money(500000, 'DZD'),
      frequency: frequency,
      start: DateTime(2026, 12, 1),
      members: members,
      meIndex: 2,
      createdAt: DateTime(2026, 11, 1),
      paidRounds: const <int>{0, 1},
      payoutReceived: true,
    );

String _pack(Map<String, dynamic> j) =>
    base64Url.encode(utf8.encode(jsonEncode(j))).replaceAll('=', '');

Map<String, dynamic> _good() => <String, dynamic>{
      'v': 1,
      'n': 'Family',
      'a': 1000,
      'c': 'USD',
      'f': 'm',
      's': '2026-12-01',
      'm': <String>['A', 'B'],
    };

void main() {
  test('a daret survives the trip through a link', () {
    final SharedDaret? back = DaretLink.decode(DaretLink.encode(_daret()));
    expect(back, isNotNull);
    expect(back!.name, 'جمعية العائلة');
    expect(back.contribution, const Money(500000, 'DZD'));
    expect(back.frequency, DaretFrequency.monthly);
    expect(back.start, DateTime(2026, 12, 1));
    expect(back.members, <String>['أحمد', 'Sara', 'ليلى', 'Omar']);
    expect(
        DaretLink.decode(DaretLink.encode(
                _daret(frequency: DaretFrequency.weekly)))!
            .frequency,
        DaretFrequency.weekly);
  });

  test("the sharer's own payments and place never leave the device", () {
    final String json = utf8.decode(base64Url.decode(
        base64Url.normalize(DaretLink.encode(_daret()))));
    final Map<String, dynamic> j = jsonDecode(json) as Map<String, dynamic>;
    expect(j.keys.toSet(), <String>{'v', 'n', 'a', 'c', 'f', 's', 'm'});
    expect(json.contains('paid'), isFalse);
    expect(json.contains('meIndex'), isFalse);
    expect(json.contains('daret-1'), isFalse);
  });

  test('the link is the app address with the daret and the invite code', () {
    final String url = DaretLink.link(
        'https://smartbudget.dgotix.com/', _daret(),
        inviteCode: 'AB23CD45');
    final Uri u = Uri.parse(url);
    expect(u.host, 'smartbudget.dgotix.com');
    expect(u.queryParameters['ref'], 'AB23CD45');
    expect(DaretLink.decode(DaretLink.payloadIn(u))!.name, 'جمعية العائلة');
    // No code: no ref parameter.
    expect(
        Uri.parse(DaretLink.link('https://smartbudget.dgotix.com/', _daret()))
            .queryParameters
            .containsKey('ref'),
        isFalse);
  });

  test('the payload is found in the query or in the fragment', () {
    final String p = DaretLink.encode(_daret());
    expect(DaretLink.payloadIn(Uri.parse('https://x.test/?daret=$p')), p);
    expect(
        DaretLink.payloadIn(Uri.parse('https://x.test/#/daret?daret=$p')), p);
    expect(DaretLink.payloadIn(Uri.parse('https://x.test/')), isNull);
    expect(DaretLink.payloadIn(Uri.parse('https://x.test/?daret=')), isNull);
  });

  test('the receiver gets a clean copy at the place they pick', () {
    final SharedDaret s = DaretLink.decode(DaretLink.encode(_daret()))!;
    final Daret mine =
        s.toDaret(id: 'new', meIndex: 3, createdAt: DateTime(2026, 11, 11));
    expect(mine.id, 'new');
    expect(mine.meIndex, 3);
    expect(mine.paidRounds, isEmpty);
    expect(mine.payoutReceived, isFalse);
    expect(DaretMath.myTurn(mine), DateTime(2027, 3, 1));
    // A place outside the list is pulled back into it.
    expect(s.toDaret(id: 'x', meIndex: 99, createdAt: DateTime(2026)).meIndex,
        3);
  });

  test('the same schedule is recognized, a changed one is not', () {
    final SharedDaret s = DaretLink.decode(DaretLink.encode(_daret()))!;
    expect(s.sameScheduleAs(_daret()), isTrue);
    expect(s.sameScheduleAs(_daret(name: 'Other')), isFalse);
    expect(
        s.sameScheduleAs(
            _daret(members: const <String>['Sara', 'أحمد', 'ليلى', 'Omar'])),
        isFalse);
  });

  group('a link is text a stranger can write: junk is refused', () {
    test('not ours at all', () {
      expect(DaretLink.decode(null), isNull);
      expect(DaretLink.decode(''), isNull);
      expect(DaretLink.decode('not base64 !!!'), isNull);
      expect(DaretLink.decode(_pack(<String, dynamic>{'hello': 1})), isNull);
      expect(
          DaretLink.decode(base64Url.encode(utf8.encode('[1,2,3]'))), isNull);
      expect(DaretLink.decode('A' * (DaretLink.maxPayloadLength + 1)), isNull);
    });

    test('the good sample itself is accepted', () {
      expect(DaretLink.decode(_pack(_good())), isNotNull);
    });

    void refused(String what, void Function(Map<String, dynamic>) change) {
      test(what, () {
        final Map<String, dynamic> j = _good();
        change(j);
        expect(DaretLink.decode(_pack(j)), isNull);
      });
    }

    refused('another version', (j) => j['v'] = 2);
    refused('no name', (j) => j['n'] = '   ');
    refused('a name that is not text', (j) => j['n'] = 5);
    refused('a name too long', (j) => j['n'] = 'x' * 61);
    refused('a zero amount', (j) => j['a'] = 0);
    refused('a negative amount', (j) => j['a'] = -5);
    refused('an absurd amount', (j) => j['a'] = 2000000000000000);
    refused('an amount that is not a whole number', (j) => j['a'] = 10.5);
    refused('an amount as text', (j) => j['a'] = '1000');
    refused('a currency the app does not have', (j) => j['c'] = 'ZZZ');
    refused('an unknown frequency', (j) => j['f'] = 'daily');
    refused('a malformed date', (j) => j['s'] = '1/12/2026');
    refused('a date that does not exist', (j) => j['s'] = '2026-02-31');
    refused('a date far away', (j) => j['s'] = '9999-01-01');
    refused('one member only', (j) => j['m'] = <String>['A']);
    refused('members that are not a list', (j) => j['m'] = 'A,B');
    refused('too many members',
        (j) => j['m'] = List<String>.generate(61, (int i) => 'm$i'));
    refused('an empty member', (j) => j['m'] = <String>['A', ' ']);
    refused('a member that is not text', (j) => j['m'] = <dynamic>['A', 7]);
    refused('a member name too long', (j) => j['m'] = <String>['A', 'x' * 41]);
  });

  test('control and direction characters are taken out of names', () {
    final Map<String, dynamic> j = _good()
      ..['n'] = 'Fam\u202Eily\n\u0000 circle'
      ..['m'] = <String>['A\u200Fli', '  B  '];
    final SharedDaret s = DaretLink.decode(_pack(j))!;
    expect(s.name, 'Fam ily circle');
    expect(s.members, <String>['A li', 'B']);
  });
}
