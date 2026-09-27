import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/core/time/clock_format.dart';
import 'package:smartbudget/core/time/http_date.dart';
import 'package:smartbudget/core/time/network_time.dart';

String _httpDate(DateTime utc) {
  const List<String> days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${days[utc.weekday - 1]}, ${two(utc.day)} ${months[utc.month - 1]} '
      '${utc.year} ${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} GMT';
}

void main() {
  tearDown(AppClock.reset);

  group('parseHttpDate', () {
    test('reads an IMF-fixdate as UTC', () {
      final DateTime? d = parseHttpDate('Sun, 27 Sep 2026 10:15:30 GMT');
      expect(d, DateTime.utc(2026, 9, 27, 10, 15, 30));
      expect(d!.isUtc, isTrue);
    });

    test('rejects missing or malformed values', () {
      expect(parseHttpDate(null), isNull);
      expect(parseHttpDate(''), isNull);
      expect(parseHttpDate('Sun, 27 Foo 2026 10:15:30 GMT'), isNull);
      expect(parseHttpDate('2026-09-27T10:15:30Z'), isNull);
    });
  });

  group('AppClock', () {
    test('is the device clock until synced', () {
      expect(AppClock.isSynced, isFalse);
      expect(AppClock.offset, Duration.zero);
      expect(AppClock.now().difference(DateTime.now()).inSeconds.abs(),
          lessThan(1));
    });

    test('measures against the round-trip midpoint (+0.5 s truncation)', () {
      final DateTime sent = DateTime.utc(2026, 9, 27, 10);
      final Duration d = AppClock.measure(
        serverUtc: DateTime.utc(2026, 9, 27, 12, 0, 1),
        sentAt: sent,
        receivedAt: sent.add(const Duration(seconds: 2)),
      );
      expect(d, const Duration(hours: 2, milliseconds: 500));
    });

    test('ignores jitter within the tolerance', () {
      AppClock.applyOffset(const Duration(seconds: 2));
      expect(AppClock.offset, Duration.zero);
      expect(AppClock.isSynced, isTrue);
    });

    test('corrects a device clock that is a month behind', () {
      AppClock.applyOffset(const Duration(days: 31));
      final DateTime expected = DateTime.now().add(const Duration(days: 31));
      expect(AppClock.now().difference(expected).inSeconds.abs(), lessThan(1));
    });
  });

  group('NetworkTime.sync', () {
    test('applies the offset from the server Date header', () async {
      final DateTime server =
          DateTime.now().toUtc().add(const Duration(hours: 3));
      late http.Request seen;
      final NetworkTime nt = NetworkTime(
        origin: Uri.parse('https://example.com/app/#/settings'),
        client: MockClient((http.Request r) async {
          seen = r;
          return http.Response('', 200,
              headers: <String, String>{'date': _httpDate(server)});
        }),
      );
      expect(await nt.sync(), isTrue);
      expect(seen.method, 'HEAD');
      expect(seen.url.path, '/app/version.json');
      expect(seen.url.fragment, isEmpty);
      expect(
          (AppClock.offset - const Duration(hours: 3)).inMilliseconds.abs(),
          lessThan(1600));
    });

    test('keeps the device clock when the header is missing', () async {
      final NetworkTime nt = NetworkTime(
        origin: Uri.parse('https://example.com/'),
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(await nt.sync(), isFalse);
      expect(AppClock.isSynced, isFalse);
    });

    test('keeps the device clock offline', () async {
      final NetworkTime nt = NetworkTime(
        origin: Uri.parse('https://example.com/'),
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await nt.sync(), isFalse);
      expect(AppClock.offset, Duration.zero);
    });

    test('does nothing without a web origin', () async {
      final NetworkTime nt = NetworkTime(
        origin: Uri.parse('file:///tmp/app'),
        client: MockClient((_) async => fail('no request expected')),
      );
      expect(await nt.sync(), isFalse);
    });
  });

  group('formatting', () {
    test('UTC offsets', () {
      expect(formatUtcOffset(const Duration(hours: 1)), 'UTC+01:00');
      expect(formatUtcOffset(const Duration(hours: -5, minutes: -30)),
          'UTC−05:30');
      expect(formatUtcOffset(Duration.zero), 'UTC+00:00');
    });

    test('drift parts', () {
      final ({int days, int hours, int minutes, int seconds}) p =
          splitDrift(const Duration(days: -1, hours: -2, minutes: -3));
      expect(p, (days: 1, hours: 2, minutes: 3, seconds: 0));
    });
  });
}
