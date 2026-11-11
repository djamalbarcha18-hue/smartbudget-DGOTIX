/// Sharing a daret with its members as a link.
///
/// The link carries the schedule itself (name, contribution, how often, the
/// first round and the members in turn order) as a compact, URL-safe string in
/// one query parameter. Nothing is stored on a server: whoever has the link
/// has the schedule, and a member who opens it gets their own copy, says which
/// name is theirs, and tracks their own payments.
///
/// Pure Dart (no Flutter), so every rule here is unit-testable. Everything
/// read back out of a link is checked: a link is text a stranger can write.
library;

import 'dart:convert';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';

/// A daret as shared: the schedule without anyone's own payments.
class SharedDaret {
  const SharedDaret({
    required this.name,
    required this.contribution,
    required this.frequency,
    required this.start,
    required this.members,
  });

  final String name;
  final Money contribution;
  final DaretFrequency frequency;
  final DateTime start;
  final List<String> members;

  /// The receiver's own copy, with [meIndex] as their place in the order.
  Daret toDaret({
    required String id,
    required int meIndex,
    required DateTime createdAt,
  }) =>
      Daret(
        id: id,
        name: name,
        contribution: contribution,
        frequency: frequency,
        start: start,
        members: members,
        meIndex: meIndex.clamp(0, members.length - 1),
        createdAt: createdAt,
      );

  /// Whether [d] is this same schedule (so opening the link twice, or the
  /// organizer opening their own link, does not make a second copy).
  bool sameScheduleAs(Daret d) =>
      d.name == name &&
      d.contribution == contribution &&
      d.frequency == frequency &&
      d.start.year == start.year &&
      d.start.month == start.month &&
      d.start.day == start.day &&
      d.members.length == members.length &&
      <int>[for (int i = 0; i < members.length; i++) i]
          .every((int i) => d.members[i] == members[i]);
}

abstract final class DaretLink {
  /// The query parameter carrying the schedule: `?daret=…`.
  static const String param = 'daret';

  static const int _version = 1;

  // Limits on what a link may carry. Generous for real circles, small enough
  // that a hand-made link cannot fill the screen or the device's storage.
  static const int maxPayloadLength = 6000;
  static const int maxNameLength = 60;
  static const int maxMemberLength = 40;
  static const int minMembers = 2;
  static const int maxMembers = 60;

  /// [d] as the compact string that rides in the link.
  static String encode(Daret d) {
    final Map<String, dynamic> j = <String, dynamic>{
      'v': _version,
      'n': d.name,
      'a': d.contribution.minorUnits,
      'c': d.contribution.currencyCode,
      'f': d.frequency == DaretFrequency.weekly ? 'w' : 'm',
      's': _ymd(d.start),
      'm': d.members,
    };
    return base64Url.encode(utf8.encode(jsonEncode(j))).replaceAll('=', '');
  }

  /// [appUrl] with [d] attached (and [inviteCode], the sharer's own invite
  /// code, when they have one, so members who join count as their invites).
  static String link(String appUrl, Daret d, {String? inviteCode}) {
    final Uri base = Uri.parse(appUrl);
    return base.replace(queryParameters: <String, String>{
      ...base.queryParameters,
      param: encode(d),
      if (inviteCode != null && inviteCode.isNotEmpty) 'ref': inviteCode,
    }).toString();
  }

  /// The schedule in [payload], or null when it is not one of ours or breaks
  /// any limit. Never throws.
  static SharedDaret? decode(String? payload) {
    if (payload == null) return null;
    final String p = payload.trim();
    if (p.isEmpty || p.length > maxPayloadLength) return null;
    try {
      final String padded = p.padRight(p.length + (4 - p.length % 4) % 4, '=');
      final Object? j = jsonDecode(utf8.decode(base64Url.decode(padded)));
      if (j is! Map) return null;
      if (j['v'] != _version) return null;

      final String name = _clean(j['n'], maxNameLength);
      if (name.isEmpty) return null;

      final Object? amount = j['a'];
      if (amount is! int || amount <= 0 || amount > 1000000000000000) {
        return null;
      }
      final Object? code = j['c'];
      if (code is! String ||
          !Currencies.all.any((Currency c) => c.code == code)) {
        return null;
      }

      final DaretFrequency frequency = switch (j['f']) {
        'w' => DaretFrequency.weekly,
        'm' => DaretFrequency.monthly,
        _ => throw const FormatException('frequency'),
      };

      final Object? s = j['s'];
      if (s is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
        return null;
      }
      final DateTime? parsed = DateTime.tryParse(s);
      if (parsed == null || parsed.year < 2000 || parsed.year > 2100) {
        return null;
      }
      // "2026-02-31" parses as March 3rd: a date that is not itself is junk.
      if (_ymd(parsed) != s) return null;

      final Object? m = j['m'];
      if (m is! List || m.length < minMembers || m.length > maxMembers) {
        return null;
      }
      final List<String> members = <String>[];
      for (final Object? e in m) {
        final String member = _clean(e, maxMemberLength);
        if (member.isEmpty) return null;
        members.add(member);
      }

      return SharedDaret(
        name: name,
        contribution: Money(amount, code),
        frequency: frequency,
        start: DateTime(parsed.year, parsed.month, parsed.day),
        members: List<String>.unmodifiable(members),
      );
    } catch (_) {
      return null;
    }
  }

  /// The payload in [url], or null. Reads the query string and, because the
  /// app routes on the fragment (`/#/daret?daret=…`), the fragment's too.
  static String? payloadIn(Uri url) {
    final String? direct = url.queryParameters[param];
    if (direct != null && direct.isNotEmpty) return direct;
    final String fragment = url.fragment;
    final int q = fragment.indexOf('?');
    if (q < 0) return null;
    final String? inner =
        Uri.splitQueryString(fragment.substring(q + 1))[param];
    return inner == null || inner.isEmpty ? null : inner;
  }

  /// A line of text someone else wrote, made safe to show: a string, with no
  /// control or invisible direction characters, trimmed, within [max].
  static String _clean(Object? v, int max) {
    if (v is! String) return '';
    final String s = v
        .replaceAll(
            RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.length > max ? '' : s;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
