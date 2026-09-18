import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/core/env/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production backend is initialized ONLY when configured. With no credentials
  // the app runs entirely on the local dev backend (fake), so the free web demo
  // works with zero setup.
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  runApp(
    const ProviderScope(
      child: SmartBudgetApp(),
    ),
  );
}
