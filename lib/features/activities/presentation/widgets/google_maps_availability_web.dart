import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// A la web, `google.maps` només existeix si el script de Google Maps s'ha
/// carregat (vegeu `web/index.html`).
bool isGoogleMapsAvailable() {
  final google = globalContext['google'];
  return google != null &&
      google.isA<JSObject>() &&
      (google as JSObject).has('maps');
}
