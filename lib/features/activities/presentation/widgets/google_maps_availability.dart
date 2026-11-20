import 'google_maps_availability_stub.dart'
    if (dart.library.js_interop) 'google_maps_availability_web.dart'
    as platform;

/// Si Google Maps es pot dibuixar (DP-061). A la web depèn que s'hagi carregat el
/// script de Google Maps (sense clau no es carrega); al mòbil, sempre.
// TODO(DP-061): al mòbil no es detecta una clau que falti.
bool get isGoogleMapsAvailable => platform.isGoogleMapsAvailable();
