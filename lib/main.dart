import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/storage/persistent_storage.dart';

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

  // Financial data lives in the browser's storage: ask the browser not to
  // evict it under storage pressure. Fire-and-forget — never blocks startup.
  requestPersistentStorage().ignore();

  runApp(
    const ProviderScope(
      child: SmartBudgetApp(),
    ),
  );
}
