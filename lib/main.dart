import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/storage/legacy_cleanup.dart';
import 'package:smartbudget/core/storage/persistent_storage.dart';
import 'package:smartbudget/core/time/network_time.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/data/lock_store.dart';
import 'package:smartbudget/features/app_lock/domain/lock_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Every date (including the Arabic date picker) uses Latin digits 0-9.
  LatinDigits.enforce();

  // Production backend is initialized ONLY when configured. With no credentials
  // the app runs entirely on the local dev backend (fake), so the free web demo
  // works with zero setup.
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

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

  // Erase personal AI keys saved by earlier versions (no longer supported).
  removeRetiredLocalData().ignore();

  // Read before the first frame so a locked app never shows its content.
  final LockConfig lock = await LockStore.load();

  runApp(
    ProviderScope(
      overrides: <Override>[
        initialLockConfigProvider.overrideWithValue(lock),
      ],
      child: const SmartBudgetApp(),
    ),
  );
}
