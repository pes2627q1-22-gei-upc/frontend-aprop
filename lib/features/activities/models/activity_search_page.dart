import 'activity.dart';

/// A server search page: the total refers to all matches, not loaded cards.
class ActivitySearchPage {
  ActivitySearchPage({
    required Iterable<Activity> activities,
    required this.totalCount,
    this.nextPage,
  }) : activities = List.unmodifiable(activities),
       assert(totalCount >= 0),
       assert(nextPage == null || nextPage >= 0);

  final List<Activity> activities;
  final int totalCount;
  final int? nextPage;
}
