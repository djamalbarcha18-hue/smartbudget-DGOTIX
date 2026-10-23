import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy mode: hides the money figures on KPI cards from anyone looking at
/// the screen.
///
/// - [hidden] is the viewer's choice, made with the eye button on any KPI card
///   and kept between visits.
/// - [hideWhileEntering] (on by default) also hides them while a transaction
///   is being added or edited — the moment the screen is most likely to be
///   seen — and brings them back when the sheet closes.
///
/// Both are stored in shared_preferences — a per-device convenience, never
/// financial data — and every read/write is guarded so a storage failure can
/// never break the app.
@immutable
class PrivacyState {
  const PrivacyState({
    this.hidden = false,
    this.hideWhileEntering = true,
    this.openEntries = 0,
  });

  final bool hidden;
  final bool hideWhileEntering;

  /// Entry sheets open right now (see [PrivacyController.whileEntering]).
  final int openEntries;

  /// Whether figures are masked at this moment.
  bool get masked => hidden || (hideWhileEntering && openEntries > 0);

  PrivacyState copyWith(
          {bool? hidden, bool? hideWhileEntering, int? openEntries}) =>
      PrivacyState(
        hidden: hidden ?? this.hidden,
        hideWhileEntering: hideWhileEntering ?? this.hideWhileEntering,
        openEntries: openEntries ?? this.openEntries,
      );
}

final privacyProvider =
    NotifierProvider<PrivacyController, PrivacyState>(PrivacyController.new);

class PrivacyController extends Notifier<PrivacyState> {
  static const String _hiddenKey = 'sb_privacy_hidden';
  static const String _enteringKey = 'sb_privacy_hide_entering';

  @override
  PrivacyState build() {
    _load();
    return const PrivacyState();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        hidden: prefs.getBool(_hiddenKey),
        hideWhileEntering: prefs.getBool(_enteringKey),
      );
    } catch (_) {
      // Ignore — keep the defaults. Storage is optional.
    }
  }

  /// The eye button: hide when anything shows, show when hidden.
  Future<void> toggle() => setHidden(!state.masked);

  Future<void> setHidden(bool on) async {
    state = state.copyWith(hidden: on);
    await _save(_hiddenKey, on);
  }

  Future<void> setHideWhileEntering(bool on) async {
    state = state.copyWith(hideWhileEntering: on);
    await _save(_enteringKey, on);
  }

  void beginEntry() =>
      state = state.copyWith(openEntries: state.openEntries + 1);

  void endEntry() => state = state.copyWith(
      openEntries: state.openEntries > 0 ? state.openEntries - 1 : 0);

  /// Runs [open] (a transaction sheet) with figures hidden until it closes.
  static Future<T> whileEntering<T>(
      BuildContext context, Future<T> Function() open) async {
    final PrivacyController? ctrl = _of(context);
    if (ctrl == null) return open();
    ctrl.beginEntry();
    try {
      return await open();
    } finally {
      ctrl.endEntry();
    }
  }

  /// Null outside a ProviderScope (a sheet shown on its own in a test).
  static PrivacyController? _of(BuildContext context) {
    try {
      return ProviderScope.containerOf(context, listen: false)
          .read(privacyProvider.notifier);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(String key, bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Non-fatal.
    }
  }
}
