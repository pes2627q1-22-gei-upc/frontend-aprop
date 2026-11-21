import '../../activities/repositories/activity_repository.dart';
import '../models/interest_question.dart';
import '../repositories/interest_test_repository.dart';

/// Questions from the demo catalogue; answers are kept only during this app run.
class DemoInterestTestRepository implements InterestTestRepository {
  DemoInterestTestRepository({
    required this.activityRepository,
    // TODO(DP-066): Demo accounts default to completed so demo runs and
    // existing app flow tests enter MainShell directly; pass false to
    // exercise onboarding in Demo mode.
    this.completed = true,
  });

  final ActivityRepository activityRepository;
  List<InterestAnswer> lastAnswers = const [];
  bool completed;

  @override
  Future<bool> hasCompletedTest() async => completed;

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    final activities = await activityRepository.getActivities();
    return [
      for (final (index, activity) in activities.take(10).indexed)
        InterestQuestion(
          eventId: index + 1,
          title: activity.title,
          description: activity.description ?? '',
          imageUrl: activity.imageUrl,
          imageAsset: activity.imageAsset,
          categories: activity.categories,
        ),
    ];
  }

  @override
  Future<void> submitAnswers(List<InterestAnswer> answers) async {
    lastAnswers = List.unmodifiable(answers);
    completed = true;
  }
}
