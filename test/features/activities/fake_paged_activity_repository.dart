import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';

import 'fake_activity_repository.dart';

class FakePagedActivityRepository extends FakeActivityRepository {
  final pagesRequested = <int>[];
  Future<ActivityPage> Function(int page)? onPage;
  final requestedFilters = <ActivityFilters?>[];

  @override
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) {
    pagesRequested.add(page);
    requestedFilters.add(filters);
    return onPage?.call(page) ??
        super.getActivitiesPage(
          page: page,
          pageSize: pageSize,
          filters: filters,
        );
  }
}
