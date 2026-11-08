import '../../activities/repositories/activity_repository.dart';
import '../models/interest_question.dart';
import '../repositories/interest_test_repository.dart';

/// Questions from the demo catalogue; answers are kept only during this app run.
class DemoInterestTestRepository implements InterestTestRepository {
  DemoInterestTestRepository({required this.activityRepository});
  final ActivityRepository activityRepository;
  List<InterestAnswer> lastAnswers = const [];

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
  Future<void> submitAnswers(List<InterestAnswer> answers) async =>
      lastAnswers = List.unmodifiable(answers);
}
