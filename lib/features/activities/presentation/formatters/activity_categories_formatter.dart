import '../../models/activity.dart';

/// «Música», o «Música +2» si l'activitat en té més (la primera fa de
/// distintiu, com a les targetes).
String activityCategoriesLabel(Activity activity) {
  final more = activity.categories.length - 1;
  return more > 0 ? '${activity.category} +$more' : activity.category;
}
