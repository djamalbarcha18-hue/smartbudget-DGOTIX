import 'package:intl/intl.dart' as intl;

import 'package:smartbudget/features/sadaqah/domain/sadaqah_commitment.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The planner's words, in its two faces: "Sadaqah Planner" when the Islamic
/// features are shown, a neutral "Giving Planner" otherwise (same screen).
class SadaqahText {
  const SadaqahText(this.l, {required this.islamic});

  final AppLocalizations l;
  final bool islamic;

  String get title => islamic ? l.navSadaqah : l.navGiving;
  String get hint => islamic ? l.sadaqahHint : l.givingHint;
  String get empty => islamic ? l.sadaqahEmpty : l.givingEmpty;
  String get add => islamic ? l.sadaqahAdd : l.givingAdd;
  String get deleteQuestion =>
      islamic ? l.sadaqahDeleteQuestion : l.givingDeleteQuestion;
  String get remindersTitle =>
      islamic ? l.sadaqahRemindersTitle : l.givingRemindersTitle;
  String get promoTitle => islamic ? l.sadaqahPromoTitle : l.givingPromoTitle;
  String get promoBody => islamic ? l.sadaqahPromoBody : l.givingPromoBody;

  String kind(SadaqahKind k) => switch (k) {
        SadaqahKind.sadaqah =>
          islamic ? l.sadaqahKindSadaqah : l.givingKindDonation,
        SadaqahKind.family => l.sadaqahKindFamily,
        SadaqahKind.sponsorship => l.sadaqahKindSponsorship,
      };

  String doneFor(SadaqahFrequency f) => f == SadaqahFrequency.weekly
      ? l.sadaqahDoneWeek
      : l.sadaqahDoneMonth;

  /// "Every Friday · 10:00" / "Day 1 of every month · 10:00" (Latin digits).
  String schedule(SadaqahCommitment c, String languageCode) {
    final String time =
        '${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}';
    final String when = c.frequency == SadaqahFrequency.weekly
        ? l.sadaqahEveryWeek(weekday(c.weekday, languageCode))
        : l.sadaqahEveryMonth('${c.dayOfMonth}');
    return '$when · $time';
  }

  /// The name of [weekday] (1 = Monday) in the app language.
  static String weekday(int weekday, String languageCode) {
    final String name =
        intl.DateFormat.localeExists(languageCode) ? languageCode : 'en';
    try {
      // 1 January 2024 was a Monday.
      return intl.DateFormat.EEEE(name).format(DateTime(2024, 1, weekday));
    } catch (_) {
      return intl.DateFormat.EEEE('en').format(DateTime(2024, 1, weekday));
    }
  }
}
