import 'package:flutter/material.dart';

import '../../features/activities/presentation/screens/activity_details_screen.dart';
import '../../features/activities/repositories/activity_repository.dart';

/// Shared entry point for opening an activity from any app section.
Route<void> activityDetailsRoute({
  required String activityId,
  required ActivityRepository repository,
}) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(
      name: '/activities/${Uri.encodeComponent(activityId)}',
    ),
    builder: (context) =>
        ActivityDetailsScreen(activityId: activityId, repository: repository),
  );
}
