import 'dart:js_interop';
import 'dart:js_interop_unsafe';

String? deviceTimeZoneName() {
  try {
    final JSObject intl = globalContext['Intl']! as JSObject;
    final JSObject format = intl.callMethod<JSObject>('DateTimeFormat'.toJS);
    final JSObject options =
        format.callMethod<JSObject>('resolvedOptions'.toJS);
    final String? zone = (options['timeZone'] as JSString?)?.toDart;
    return (zone == null || zone.isEmpty) ? null : zone;
  } catch (_) {
    return null;
  }
}
