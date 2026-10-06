import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:smartbudget/core/env/app_env.dart';

/// The Turnstile check page (web/turnstile.html on the app's site) in a
/// WebView; it reports back through the `TurnstileBridge` channel. The
/// WebView stays on that page. [onResult] gets the token, or null when the
/// check failed.
class TurnstileView extends StatefulWidget {
  const TurnstileView({
    super.key,
    required this.query,
    required this.onResult,
  });

  final Map<String, String> query;
  final ValueChanged<String?> onResult;

  @override
  State<TurnstileView> createState() => _TurnstileViewState();
}

class _TurnstileViewState extends State<TurnstileView> {
  late final Uri _page = Uri.parse(AppEnv.turnstilePageUrl)
      .replace(queryParameters: widget.query);
  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..addJavaScriptChannel('TurnstileBridge', onMessageReceived: _onMessage)
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (NavigationRequest r) {
        final Uri? to = Uri.tryParse(r.url);
        // The page itself, and Cloudflare's checker inside it.
        final bool allowed = to != null &&
            to.scheme == 'https' &&
            ((to.host == _page.host && to.path == _page.path) ||
                (!r.isMainFrame && to.host == 'challenges.cloudflare.com'));
        return allowed
            ? NavigationDecision.navigate
            : NavigationDecision.prevent;
      },
      onWebResourceError: (WebResourceError e) {
        if (e.isForMainFrame ?? true) _finish(null);
      },
    ))
    ..loadRequest(_page);
  bool _done = false;

  void _onMessage(JavaScriptMessage m) {
    Object? data;
    try {
      data = jsonDecode(m.message);
    } catch (_) {
      return;
    }
    if (data is! Map) return;
    final Object? token = data['token'];
    _finish(data['type'] == 'token' && token is String && token.isNotEmpty
        ? token
        : null);
  }

  void _finish(String? token) {
    if (_done) return;
    _done = true;
    widget.onResult(token);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}
