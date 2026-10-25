import 'package:web/web.dart' as web;

bool _taken = false;

/// The installed web app's share target opens it with the shared text in
/// the address (web/manifest.json). Taken once, then removed from the
/// address so a reload doesn't share it again.
String? takeSharedText() {
  if (_taken) return null;
  _taken = true;
  final Map<String, String> q = Uri.base.queryParameters;
  final String text = <String?>[
    q['share_title'],
    q['share_text'],
    q['share_url']
  ].whereType<String>().where((String s) => s.trim().isNotEmpty).join('\n');
  if (text.isEmpty) return null;
  final Uri clean = Uri.base.replace(queryParameters: <String, String>{
    for (final MapEntry<String, String> e in q.entries)
      if (!e.key.startsWith('share_')) e.key: e.value,
  });
  web.window.history.replaceState(
      null,
      '',
      clean.queryParameters.isEmpty
          ? clean.toString().replaceFirst('?', '')
          : clean.toString());
  return text;
}
