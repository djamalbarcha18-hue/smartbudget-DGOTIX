import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Reloads the page, which then loads the newest deployed build.
void reloadPage() {
  (globalContext['location']! as JSObject).callMethod<JSAny?>('reload'.toJS);
}
