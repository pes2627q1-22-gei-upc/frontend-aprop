import 'package:flutter/material.dart';

import '../../features/activities/models/activity.dart';
import '../../features/activities/presentation/screens/activity_details_screen.dart';
import '../../features/activities/repositories/activity_details_repository.dart';
import '../../features/activities/presentation/view_models/enrollment_view_model.dart';

/// Shared entry point for opening an activity from any app section.
Route<void> activityDetailsRoute({
  required String activityId,
  required ActivityDetailsRepository repository,
  required EnrollmentViewModel enrollmentViewModel,
  bool Function(Activity activity)? canEdit,
  Future<bool> Function(Activity activity)? onEdit,
}) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(
      name: '/activities/${Uri.encodeComponent(activityId)}',
    ),
    builder: (context) => ActivityDetailsScreen(
      activityId: activityId,
      repository: repository,
      enrollmentViewModel: enrollmentViewModel,
      canEdit: canEdit,
      onEdit: onEdit,
    ),
  );
}
