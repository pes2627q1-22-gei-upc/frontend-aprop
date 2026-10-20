import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';

class FakeActivityRepository implements ActivityRepository {
  Future<Activity?> Function(String id)? findActivity;
  final requestedIds = <String>[];
  int listRequests = 0;

  /// Activitats rebudes per [createActivity].
  final created = <NewActivity>[];

  /// Si no és nul, [createActivity] el llança.
  Object? createError;

  /// Si no és nul, [createActivity] espera que es completi.
  Completer<void>? pendingCreate;

  @override
  Future<List<Activity>> getActivities() async {
    listRequests++;
    return const [];
  }

  @override
  Future<Activity?> getActivityById(String id) {
    requestedIds.add(id);
    return findActivity?.call(id) ?? Future.value(null);
  }

  @override
  Future<Activity> createActivity(NewActivity activity) async {
    created.add(activity);
    await pendingCreate?.future;
    if (createError case final error?) throw error;
    return Activity(
      id: 'created-${created.length}',
      title: activity.title,
      category: activity.category,
      municipality: activity.municipality,
      startsAt: activity.startsAt,
      source: ActivitySource.community,
      imageAsset: activity.imageAsset,
      creator: activity.creator,
      description: activity.description,
      directions: activity.directions,
      price: activity.price,
    );
  }
}
