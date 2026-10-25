import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/core/app_restart.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/storage/legacy_cleanup.dart';
import 'package:smartbudget/core/storage/persistent_storage.dart';
import 'package:smartbudget/core/time/network_time.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/data/lock_store.dart';
import 'package:smartbudget/features/app_lock/domain/lock_config.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Every date (including the Arabic date picker) uses Latin digits 0-9.
  LatinDigits.enforce();

  // Draw under the status and navigation bars on every Android version, as
  // Android 15 does anyway; the shell keeps the content clear of them.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).ignore();
  }

  // Production backend is initialized ONLY when configured. With no credentials
  // the app runs entirely on the local dev backend (fake), so the free web demo
  // works with zero setup.
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  // Notes a tap on the daily reminder that opened the app.
  if (ReminderNotifications.supported) {
    ReminderNotifications.instance.init().ignore();
  }

  AppRestart.register(_start);
  await _start();
}

/// Everything that must run again when the app restarts after its local data
/// was erased (mobile has no page reload): a fresh [ProviderScope] (new key),
/// the lock read again.
Future<void> _start() async {
  // Correct "now" against world time before the first screen, so the current
  // month and due dates are right even when the device clock is wrong. Capped
  // so a slow or offline start is never held up (the clock then falls back to
  // device time and re-syncs later).
  await NetworkTime()
      .sync()
      .timeout(const Duration(milliseconds: 1500), onTimeout: () => false);

  // Financial data lives in the browser's storage: ask the browser not to
  // evict it under storage pressure. Fire-and-forget — never blocks startup.
  requestPersistentStorage().ignore();

  // Licenses of the fonts bundled for offline use (assets/google_fonts).
  LicenseRegistry.addLicense(() async* {
    for (final String f in <String>['Tajawal', 'Inter', 'NotoNaskhArabic']) {
      yield LicenseEntryWithLineBreaks(<String>[f],
          await rootBundle.loadString('assets/google_fonts/OFL-$f.txt'));
    }
    // The trip item icons in SbIcons are Lucide's.
    yield LicenseEntryWithLineBreaks(<String>['Lucide'],
        await rootBundle.loadString('assets/fonts/LICENSE-Lucide.txt'));
  });

  // Erase personal AI keys saved by earlier versions (no longer supported).
  removeRetiredLocalData().ignore();

  // Read before the first frame so a locked app never shows its content.
  final LockConfig lock = await LockStore.load();
  final LockAttempts lockAttempts = await LockStore.loadAttempts();

  runApp(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        initialLockConfigProvider.overrideWithValue(lock),
        initialLockAttemptsProvider.overrideWithValue(lockAttempts),
      ],
      child: const SmartBudgetApp(),
    ),
  );
}
