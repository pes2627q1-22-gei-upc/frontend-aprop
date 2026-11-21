import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../models/interest_question.dart';
import '../repositories/interest_test_repository.dart';

/// `GET` / `POST /preferences/test` and `GET /preferences/test/status`;
/// the server derives the user from the token.
class HttpInterestTestRepository implements InterestTestRepository {
  HttpInterestTestRepository({required this.apiClient});
  final ApiClient apiClient;

  // TODO(DP-066): Backend endpoint added in parallel (`{"completed": bool,
  // "date-taken": RFC3339|null}`); callers must not block the app on error.
  @override
  Future<bool> hasCompletedTest() async {
    final decoded = await apiClient.getJson('preferences/test/status');
    if (decoded case {'completed': final bool completed}) {
      return completed;
    }
    throw const FormatException('Expected test status');
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
  Future<void> submitAnswers(List<InterestAnswer> answers) async {
    await apiClient.postJson(
      'preferences/test',
      body: {
        'answers': [
          for (final a in answers) {'event-id': a.eventId, 'likes': a.likes},
        ],
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
