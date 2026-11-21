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
    bool? prompted,
  }) : prompted = prompted ?? completed;

  final ActivityRepository activityRepository;
  List<InterestAnswer> lastAnswers = const [];
  final Map<int, bool> _partialAnswers = {};
  bool completed;
  bool prompted;
  DateTime? _dateTaken;

  @override
  Future<InterestTestStatus> getTestStatus() async => InterestTestStatus(
    completed: completed,
    prompted: prompted || completed || _partialAnswers.isNotEmpty,
    inProgress: _partialAnswers.isNotEmpty,
    answeredCount: _partialAnswers.length,
    dateTaken: _dateTaken,
  );

  @override
  Future<void> markOnboardingPrompted() async {
    prompted = true;
  }

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    final activities = await activityRepository.getActivities();
    return [
      for (final (index, activity) in activities.take(10).indexed)
        if (!_partialAnswers.containsKey(index + 1))
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
  Future<void> submitAnswers(
    List<InterestAnswer> answers, {
    bool partial = false,
  }) async {
    prompted = true;
    if (partial) {
      for (final a in answers) {
        _partialAnswers[a.eventId] = a.likes;
      }
      return;
    }
    final merged = <int, bool>{..._partialAnswers};
    for (final a in answers) {
      merged[a.eventId] = a.likes;
    }
    lastAnswers = List.unmodifiable([
      for (final entry in merged.entries)
        InterestAnswer(eventId: entry.key, likes: entry.value),
    ]);
    _partialAnswers.clear();
    completed = true;
    _dateTaken = DateTime.now().toUtc();
  }
}
