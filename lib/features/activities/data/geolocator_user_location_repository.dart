import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../models/user_position.dart';
import '../repositories/user_location_repository.dart';

/// Ubicació del dispositiu amb `geolocator`: el GPS a Android i iOS i
/// `navigator.geolocation` a la web.
// TODO(DP-049): paquet nou, pendent de validar amb l'equip.
class GeolocatorUserLocationRepository implements UserLocationRepository {
  const GeolocatorUserLocationRepository();

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _access(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _access(permission);
  }

  @override
  Stream<UserPosition> watchPosition() {
    return Geolocator.getPositionStream(
      // Cada 10 m n'hi ha prou per al punt del mapa i gasta menys bateria.
      locationSettings: const LocationSettings(distanceFilter: 10),
    ).map(
      (position) => UserPosition(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        accuracyMeters: position.accuracy,
      ),
    );
  }

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  static LocationAccess _access(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.denied,
      };
}
