import 'dart:math' as math;

import '../../models/activity.dart';
import '../../models/geo_bounds.dart';
import '../../models/geo_point.dart';

/// Distància, en píxels lògics de pantalla, per sota de la qual dos marcadors
/// s'ajunten en un grup. Hi caben els cercles de fins a quatre xifres.
// TODO(DP-022): valor triat a ull; cal validar-lo amb l'equip.
const mapGroupRadius = 64.0;

/// Espai mínim, en píxels lògics, entre dos marcadors que no s'han ajuntat.
const _markerGap = 4.0;

/// Meitat de l'amplada del marcador d'una sola activitat (36 px).
const _singleMarkerRadius = 18.0;

/// Text del número d'un grup: sempre el total exacte.
String mapGroupLabel(int count) => '$count';

/// Diàmetre, en píxels lògics, del cercle d'un grup: creix amb les xifres
/// perquè el número exacte hi càpiga.
double mapGroupDiameter(String label) => switch (label.length) {
  1 => 40,
  2 => 44,
  3 => 50,
  4 => 58,
  _ => 66,
};

/// Meitat de la mida del marcador amb què es dibuixa un grup de [count].
double _markerRadius(int count) => count == 1
    ? _singleMarkerRadius
    : mapGroupDiameter(mapGroupLabel(count)) / 2;

/// Diferència de latitud o longitud (uns 30 m) per sota de la qual les
/// activitats d'un grup es consideren al mateix lloc.
const _samePlaceDegrees = 0.0003;

/// Si totes les activitats d'un grup són pràcticament al mateix punt (com un
/// mateix teatre), apropar-s'hi no les separaria mai.
// TODO(DP-034): llindar triat a ull; cal validar-lo amb l'equip.
bool isSamePlace(GeoBounds bounds) =>
    (bounds.northEast.latitude - bounds.southWest.latitude).abs() <
        _samePlaceDegrees &&
    (bounds.northEast.longitude - bounds.southWest.longitude).abs() <
        _samePlaceDegrees;

/// Un marcador del mapa: una activitat sola o un grup d'activitats que, amb
/// el zoom actual, quedarien l'una sobre l'altra.
class ActivityMapGroup {
  ActivityMapGroup(List<Activity> activities)
    : assert(activities.isNotEmpty),
      activities = List.unmodifiable(activities);

  /// Amb ubicació, en l'ordre en què s'han agrupat.
  final List<Activity> activities;

  bool get isSingle => activities.length == 1;

  /// Identificador estable del marcador. Cada activitat és en un sol grup, així
  /// que el primer identificador ja el distingeix.
  String get id => isSingle
      ? activities.single.id
      : 'grup:${activities.first.id}:${activities.length}';

  /// Punt mitjà de les activitats del grup.
  GeoPoint get center {
    var latitude = 0.0;
    var longitude = 0.0;
    for (final activity in activities) {
      latitude += activity.location!.latitude;
      longitude += activity.location!.longitude;
    }
    return GeoPoint(
      latitude: latitude / activities.length,
      longitude: longitude / activities.length,
    );
  }

  /// Zona mínima que conté totes les activitats del grup.
  GeoBounds get bounds {
    final first = activities.first.location!;
    var south = first.latitude;
    var north = first.latitude;
    var west = first.longitude;
    var east = first.longitude;
    for (final activity in activities.skip(1)) {
      final point = activity.location!;
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }
    return GeoBounds(
      southWest: GeoPoint(latitude: south, longitude: west),
      northEast: GeoPoint(latitude: north, longitude: east),
    );
  }
}

/// Agrupa les activitats amb ubicació que, amb el [zoom] del mapa, quedarien
/// a menys de [radius] píxels l'una de l'altra. Fa el mateix a la web i al
/// mòbil, i el resultat no depèn de l'ordre de la llista.
///
/// Primer, cada activitat va al primer grup el centre del qual (la primera
/// activitat del grup) és prou a prop; si no n'hi ha cap, en comença un de
/// nou. Després, com que cada grup es dibuixa al seu punt mitjà i amb una mida
/// que depèn del número, s'ajunten els que es tocarien: els marcadors mai no
/// queden l'un sobre l'altre.
List<ActivityMapGroup> groupActivitiesForMap(
  List<Activity> activities,
  double zoom, {
  double radius = mapGroupRadius,
}) {
  final located = [
    for (final activity in activities)
      if (activity.location != null) activity,
  ]..sort((a, b) => a.id.compareTo(b.id));

  final scale = 256 * math.pow(2, zoom).toDouble();
  final seeds = <math.Point<double>>[];
  final members = <List<Activity>>[];
  for (final activity in located) {
    final point = _toWorldPixels(activity.location!, scale);
    final index = seeds.indexWhere((seed) => seed.distanceTo(point) < radius);
    if (index == -1) {
      seeds.add(point);
      members.add([activity]);
    } else {
      members[index].add(activity);
    }
  }
  _mergeOverlapping(members, scale);
  return [for (final group in members) ActivityMapGroup(group)];
}

/// Ajunta els grups de [members] que, dibuixats al seu punt mitjà, es
/// tocarien. Es repeteix fins que no se'n toca cap, perquè un grup que creix
/// es pot acostar a un altre.
void _mergeOverlapping(List<List<Activity>> members, double scale) {
  final centers = [
    for (final group in members) _toWorldPixels(_centerOf(group), scale),
  ];
  var merged = true;
  while (merged) {
    merged = false;
    for (var i = 0; i < members.length; i++) {
      for (var j = i + 1; j < members.length; j++) {
        final minimum =
            _markerRadius(members[i].length) +
            _markerRadius(members[j].length) +
            _markerGap;
        if (centers[i].distanceTo(centers[j]) >= minimum) continue;
        // El primer és el que té l'identificador més baix: el grup el manté.
        members[i].addAll(members.removeAt(j));
        centers.removeAt(j);
        centers[i] = _toWorldPixels(_centerOf(members[i]), scale);
        merged = true;
        j = i;
      }
    }
  }
}

GeoPoint _centerOf(List<Activity> group) => ActivityMapGroup(group).center;

/// Posició en píxels del món a l'escala del zoom (projecció de Mercator, la
/// mateixa que fa servir Google Maps).
math.Point<double> _toWorldPixels(GeoPoint point, double scale) {
  final sinLatitude = math
      .sin(point.latitude * math.pi / 180)
      .clamp(-0.9999, 0.9999);
  return math.Point(
    (point.longitude + 180) / 360 * scale,
    (0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
        scale,
  );
}
