import 'geo_point.dart';

/// On és la persona, segons el dispositiu.
class UserPosition {
  const UserPosition({required this.point, required this.accuracyMeters});

  final GeoPoint point;

  /// Radi, en metres, dins del qual hi ha la posició real.
  final double accuracyMeters;
}
