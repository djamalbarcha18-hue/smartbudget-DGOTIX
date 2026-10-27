import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void guardUnload(bool Function() pending) {
  try {
    globalContext.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'beforeunload'.toJS,
      ((JSObject event) {
        if (!pending()) return;
        // Both forms: older browsers read returnValue.
        event.callMethod<JSAny?>('preventDefault'.toJS);
        event['returnValue'] = ''.toJS;
      }).toJS,
    );
  } catch (_) {
    // No warning, nothing else lost.
  }
}
