import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Google's «Continue with Google» button (web/google_signin.html) framed from
/// this same site. It reports back with postMessage; only messages from that
/// frame and this origin are read. [onCredential] gets Google's ID token.
class GoogleButtonView extends StatefulWidget {
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
  State<GoogleButtonView> createState() => _GoogleButtonViewState();
}

class _GoogleButtonViewState extends State<GoogleButtonView> {
  static int _next = 0;
  final String _viewType = 'sb-google-${_next++}';
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;

  @override
  void initState() {
    super.initState();
    _frame = web.HTMLIFrameElement()
      ..src = Uri(path: 'google_signin.html', queryParameters: widget.query)
          .toString()
      ..title = 'Google sign-in'
      // Lets Google use the browser's own sign-in prompt where it has one.
      ..allow = 'identity-credentials-get';
    _frame.style
      ..border = 'none'
      ..width = '100%'
      ..height = '100%';
    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int _) => _frame);
    _listener = _onMessage.toJS;
    web.window.addEventListener('message', _listener);
  }

  void _onMessage(web.MessageEvent e) {
    if (e.origin != web.window.location.origin) return;
    if (!e.source.strictEquals(_frame.contentWindow).toDart) return;
    final Object? data = e.data.dartify();
    if (data is! Map || data['source'] != 'sb-google') return;
    final Object? token = data['token'];
    if (data['type'] == 'credential' && token is String && token.isNotEmpty) {
      widget.onCredential(token);
    } else if (data['type'] == 'error') {
      widget.onError();
    }
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
