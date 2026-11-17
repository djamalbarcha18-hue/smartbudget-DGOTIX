import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/settings/islamic_features.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/sadaqah/data/sadaqah_notifications.dart';
import 'package:smartbudget/features/sadaqah/domain/sadaqah_commitment.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The planner as the screen sees it.
@immutable
class SadaqahState {
  const SadaqahState({
    this.items = const <SadaqahCommitment>[],
    this.loaded = false,
    this.hideAmounts = false,
    this.remindersOn = false,
  });

  final List<SadaqahCommitment> items;
  final bool loaded;
  final bool hideAmounts;

  /// Off until the user turns it on (and allows notifications).
  final bool remindersOn;

  SadaqahState copyWith({
    List<SadaqahCommitment>? items,
    bool? loaded,
    bool? hideAmounts,
    bool? remindersOn,
  }) =>
      SadaqahState(
        items: items ?? this.items,
        loaded: loaded ?? this.loaded,
        hideAmounts: hideAmounts ?? this.hideAmounts,
        remindersOn: remindersOn ?? this.remindersOn,
      );
}

/// The Sadaqah Planner, kept on this device for the signed-in account (never
/// synced: what someone gives stays between them and their phone).
final sadaqahProvider =
    NotifierProvider<SadaqahController, SadaqahState>(SadaqahController.new);

class SadaqahController extends Notifier<SadaqahState> {
  static const String _itemsBase = 'sb_sadaqah';
  static const String _hideBase = 'sb_sadaqah_hide';
  static const String _remindBase = 'sb_sadaqah_remind';

  /// The expense category a gift is recorded in (an existing category).
  static const String category = 'صدقة وتبرّعات';

  String? _account;

  @override
  SadaqahState build() {
    _account = ref.watch(currentAccountIdProvider);
    _load();
    return const SadaqahState();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<SadaqahCommitment> items = <SadaqahCommitment>[];
      final String? raw = p.getString(AccountKeys.of(_itemsBase, _account));
      if (raw != null && raw.isNotEmpty) {
        final Object? list = jsonDecode(raw);
        if (list is List) {
          for (final Object? e in list) {
            final SadaqahCommitment? c = SadaqahCommitment.fromJson(e);
            if (c != null) items.add(c);
          }
        }
      }
      state = SadaqahState(
        items: items,
        loaded: true,
        hideAmounts: p.getBool(AccountKeys.of(_hideBase, _account)) ?? false,
        remindersOn: p.getBool(AccountKeys.of(_remindBase, _account)) ?? false,
      );
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  static String newId() =>
      'sadaqah-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> save(SadaqahCommitment c) async {
    final List<SadaqahCommitment> items = <SadaqahCommitment>[
      for (final SadaqahCommitment e in state.items)
        if (e.id != c.id) e,
    ];
    final int at = state.items.indexWhere((SadaqahCommitment e) => e.id == c.id);
    items.insert(at < 0 ? items.length : at, c);
    state = state.copyWith(items: items);
    await _writeItems();
  }

  Future<void> delete(String id) async {
    state = state.copyWith(items: <SadaqahCommitment>[
      for (final SadaqahCommitment e in state.items)
        if (e.id != id) e,
    ]);
    await _writeItems();
  }

  /// Marks this period done and, when asked, records the expense. Returns
  /// the id of the recorded transaction (for undo), or null.
  Future<String?> markDone(SadaqahCommitment c) async {
    final DateTime now = AppClock.now();
    await save(c.markedPaid(now));
    if (!c.recordAsExpense || c.amount == null) return null;
    final String id = TransactionActions.newId();
    await ref.read(transactionActionsProvider).add(Transaction(
          id: id,
          date: DateTime(now.year, now.month, now.day),
          type: TransactionType.expense,
          category: category,
          amount: c.amount!,
          createdAt: now,
        ));
    return id;
  }

  Future<void> undoDone(SadaqahCommitment c, String? transactionId) async {
    final SadaqahCommitment current = state.items
            .where((SadaqahCommitment e) => e.id == c.id)
            .firstOrNull ??
        c;
    await save(current.unmarkedPaid(AppClock.now()));
    if (transactionId != null) {
      await ref.read(transactionActionsProvider).delete(transactionId);
    }
  }

  Future<void> setHideAmounts(bool on) async {
    state = state.copyWith(hideAmounts: on);
    await _write((SharedPreferences p) =>
        p.setBool(AccountKeys.of(_hideBase, _account), on));
  }

  /// Turns the reminders on (asking the phone for permission) or off. False
  /// when the phone doesn't allow notifications for the app.
  Future<bool> setReminders(bool on) async {
    // Asked only now, when the user turns them on (never at start).
    if (on && !await ReminderNotifications.instance.requestPermission()) {
      return false;
    }
    state = state.copyWith(remindersOn: on);
    await _write((SharedPreferences p) =>
        p.setBool(AccountKeys.of(_remindBase, _account), on));
    return true;
  }

  Future<void> _writeItems() => _write((SharedPreferences p) => p.setString(
      AccountKeys.of(_itemsBase, _account),
      jsonEncode(<Object?>[
        for (final SadaqahCommitment c in state.items) c.toJson(),
      ])));

  Future<void> _write(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// What should be scheduled right now (Android): the times and the neutral
/// text in the app language. Rebuilt when the planner, the language or the
/// "Islamic features" choice changes; app.dart applies every new plan.
@immutable
class SadaqahPlan {
  const SadaqahPlan(this.times, this.title, this.body, this.channel);

  final List<DateTime> times;
  final String title;
  final String body;
  final String channel;

  @override
  bool operator ==(Object other) =>
      other is SadaqahPlan &&
      listEquals(other.times, times) &&
      other.title == title &&
      other.body == body &&
      other.channel == channel;

  @override
  int get hashCode => Object.hash(Object.hashAll(times), title, body, channel);
}

final sadaqahPlanProvider = Provider<SadaqahPlan?>((ref) {
  if (!SadaqahNotifications.supported) return null;
  final SadaqahState s = ref.watch(sadaqahProvider);
  if (!s.loaded) return null;
  final bool islamic = ref.watch(islamicFeaturesProvider);
  final Locale locale = ref.watch(localeProvider);
  final AppLocalizations l = lookupAppLocalizations(locale);
  return SadaqahPlan(
    s.remindersOn
        ? SadaqahSchedule.plan(s.items, AppClock.now())
        : const <DateTime>[],
    islamic ? l.navSadaqah : l.navGiving,
    l.sadaqahNotifBody,
    islamic ? l.sadaqahRemindersTitle : l.givingRemindersTitle,
  );
});

SadaqahPlan? _wanted;
bool _applying = false;

/// Applies a plan. Changes that come while one is being applied (several
/// quick taps on a switch) are folded into the last one, so the screen never
/// waits and the phone is scheduled once more at most.
void applySadaqahPlan(SadaqahPlan plan) {
  _wanted = plan;
  if (!_applying) unawaited(_drain());
}

Future<void> _drain() async {
  _applying = true;
  try {
    while (_wanted != null) {
      final SadaqahPlan plan = _wanted!;
      _wanted = null;
      final SadaqahNotifications n = SadaqahNotifications.instance;
      try {
        await (plan.times.isEmpty
            ? n.cancel()
            : n.schedule(plan.times,
                title: plan.title, body: plan.body, channel: plan.channel));
      } catch (_) {
        // Non-fatal: planned again on the next change or launch.
      }
    }
  } finally {
    _applying = false;
  }
}
