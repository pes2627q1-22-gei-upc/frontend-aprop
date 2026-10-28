import '../models/activity.dart';

/// El que necessita la fitxa: una activitat pel seu ID. El compleixen el
/// catàleg (`ActivityRepository`) i el mapa (`ActivityMapRepository`).
abstract interface class ActivityDetailsRepository {
  /// Returns null when the activity does not exist.
  Future<Activity?> getActivityById(String id);
}
