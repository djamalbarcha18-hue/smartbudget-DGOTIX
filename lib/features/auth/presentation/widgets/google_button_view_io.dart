import 'package:flutter/widgets.dart';

/// Google's own button exists on the website only (web/google_signin.html);
/// the apps use the Supabase redirect. Nothing here.
class GoogleButtonView extends StatelessWidget {
  const GoogleButtonView({
    super.key,
    required this.query,
    required this.onCredential,
    required this.onError,
  });

  final Map<String, String> query;
  final ValueChanged<String> onCredential;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
