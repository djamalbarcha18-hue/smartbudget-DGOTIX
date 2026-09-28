import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/core/env/app_env.dart';

/// Why an AI answer was reported.
enum AiReportReason { inaccurate, harmful, other }

final aiReportServiceProvider =
    Provider<AiReportService>((ref) => const AiReportService());

/// "Report this answer" for the AI assistant (Google Play requires a way to
/// flag AI-generated content). With a backend the report is stored for the
/// owner to review (supabase/ai_reports.sql); the answer is hidden either way.
class AiReportService {
  const AiReportService();

  /// True when the report reached the server (or there is no server to send
  /// it to). Never throws.
  Future<bool> send({
    required AiReportReason reason,
    required String answer,
    String? note,
  }) async {
    if (!AppEnv.hasSupabase) return true;
    try {
      await Supabase.instance.client.from('ai_reports').insert(
        <String, dynamic>{
          'reason': reason.name,
          'answer': answer.length > 8000 ? answer.substring(0, 8000) : answer,
          if (note != null && note.trim().isNotEmpty)
            'note': note.trim().length > 1000
                ? note.trim().substring(0, 1000)
                : note.trim(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
