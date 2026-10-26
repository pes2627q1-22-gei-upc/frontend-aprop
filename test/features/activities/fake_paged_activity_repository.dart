import 'package:aprop/features/activities/models/activity_page.dart';

import 'fake_activity_repository.dart';

class FakePagedActivityRepository extends FakeActivityRepository {
  final pagesRequested = <int>[];
  Future<ActivityPage> Function(int page)? onPage;

  @override
  Future<ActivityPage> getActivitiesPage({int page = 0, int pageSize = 50}) {
    pagesRequested.add(page);
    return onPage?.call(page) ??
        super.getActivitiesPage(page: page, pageSize: pageSize);
  }
}
