import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The Turnstile check page (web/turnstile.html) framed from this same site.
/// It reports back with postMessage; only messages from that frame and this
/// origin are read. [onResult] gets the token, or null when the check failed.
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
  static int _next = 0;
  final String _viewType = 'sb-turnstile-${_next++}';
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _frame = web.HTMLIFrameElement()
      ..src = Uri(path: 'turnstile.html', queryParameters: widget.query)
          .toString()
      ..title = 'Security check';
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
    if (_done || e.origin != web.window.location.origin) return;
    if (!e.source.strictEquals(_frame.contentWindow).toDart) return;
    final Object? data = e.data.dartify();
    if (data is! Map || data['source'] != 'sb-turnstile') return;
    final Object? token = data['token'];
    _done = true;
    widget.onResult(
        data['type'] == 'token' && token is String && token.isNotEmpty
            ? token
            : null);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
