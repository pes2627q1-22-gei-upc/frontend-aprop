import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../models/interest_question.dart';
import '../repositories/interest_test_repository.dart';

/// `GET` / `POST /preferences/test`, `GET /preferences/test/status`, and
/// `POST /preferences/test/prompted`; the server derives the user from the token.
class HttpInterestTestRepository implements InterestTestRepository {
  HttpInterestTestRepository({required this.apiClient});
  final ApiClient apiClient;

  // TODO(DP-078): Supports extended status fields (`prompted`, `in-progress`,
  // `answered-count`) while staying compatible with older payloads carrying
  // only `completed` and `date-taken`.
  @override
  Future<InterestTestStatus> getTestStatus() async {
    final decoded = await apiClient.getJson('preferences/test/status');
    if (decoded case {'completed': final bool completed}) {
      final rawPrompted = decoded['prompted'];
      final rawInProgress = decoded['in-progress'];
      final rawAnsweredCount = decoded['answered-count'];
      final rawDateTaken = decoded['date-taken'];
      if ((rawPrompted != null && rawPrompted is! bool) ||
          (rawInProgress != null && rawInProgress is! bool) ||
          (rawAnsweredCount != null &&
              (rawAnsweredCount is! int || rawAnsweredCount < 0)) ||
          (rawDateTaken != null && rawDateTaken is! String)) {
        throw const FormatException('Expected test status');
      }
      final dateTaken = rawDateTaken is String
          ? DateTime.tryParse(rawDateTaken)
          : null;
      if (rawDateTaken != null && dateTaken == null) {
        throw const FormatException('Expected test status date');
      }
      final answeredCount = rawAnsweredCount as int? ?? 0;
      final inProgress = rawInProgress as bool? ?? answeredCount > 0;
      final prompted = rawPrompted as bool? ?? (completed || inProgress);
      return InterestTestStatus(
        completed: completed,
        prompted: prompted,
        inProgress: inProgress,
        answeredCount: answeredCount,
        dateTaken: dateTaken,
      );
    }
    throw const FormatException('Expected test status');
  }

  @override
  Future<void> markOnboardingPrompted() async {
    await apiClient.postJson('preferences/test/prompted');
  }

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    final decoded = await apiClient.getJson('preferences/test');
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected test questions');
    }
    return List.unmodifiable(decoded.map(_question));
  }

  @override
  Future<void> submitAnswers(
    List<InterestAnswer> answers, {
    bool partial = false,
  }) async {
    await apiClient.postJson(
      'preferences/test',
      body: {
        'answers': [
          for (final a in answers) {'event-id': a.eventId, 'likes': a.likes},
        ],
        if (partial) 'partial': true,
      },
    );
  }

  InterestQuestion _question(Object? json) {
    if (json is! Map<String, Object?> ||
        json['event-id'] is! int ||
        json['title'] is! String) {
      throw const FormatException('Expected a test question');
    }
    final cover =
        parseActivityCover(json['image-url']) ??
        parseActivityCover(json['images']);
    return InterestQuestion(
      eventId: json['event-id']! as int,
      title: json['title']! as String,
      description: (json['description'] as String? ?? '').trim(),
      imageUrl: cover?.url,
      imageAsset: cover != null && cover.asset.isNotEmpty ? cover.asset : null,
      categories: parseActivityCategories(json['categories']),
    );
  }
}
