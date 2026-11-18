import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';

class FakeActivityRepository implements ActivityRepository {
  Future<Activity?> Function(String id)? findActivity;
  final requestedIds = <String>[];
  int listRequests = 0;
  Future<List<String>> Function()? onCategories;

  /// Resposta de [getActivities].
  List<Activity> activities = const [];

  /// Activitats rebudes per [createActivity].
  final created = <NewActivity>[];

  /// Si no és nul, [createActivity] el llança.
  Object? createError;

  /// Si no és nul, [createActivity] espera que es completi.
  Completer<void>? pendingCreate;

  @override
  Future<List<Activity>> getActivities() async {
    listRequests++;
    return activities;
  }

  @override
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) async {
    final catalogue = await getActivities();
    final source = filters?.applyTo(catalogue) ?? catalogue;
    return ActivityPage(
      items: source.skip(page * pageSize).take(pageSize),
      hasMore: (page + 1) * pageSize < source.length,
    );
  }

  @override
  Future<List<String>> getFilterCategories() async =>
      onCategories == null ? activityFilterCategories : await onCategories!();

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
      location: activity.location,
      price: activity.price,
    );
  }

  /// Canvis rebuts per [updateActivity], amb l'ID.
  final updated = <(String, NewActivity)>[];

  /// Si no és nul, [updateActivity] el llança.
  Object? updateError;

  @override
  Future<Activity> updateActivity(String id, NewActivity activity) async {
    updated.add((id, activity));
    if (updateError case final error?) throw error;
    return Activity(
      id: id,
      title: activity.title,
      category: activity.category,
      municipality: activity.municipality,
      startsAt: activity.startsAt,
      endsAt: activity.endsAt,
      source: ActivitySource.community,
      imageAsset: activity.imageAsset,
      creator: activity.creator,
      description: activity.description,
      directions: activity.directions,
      location: activity.location,
      price: activity.price,
    );
  }
}
