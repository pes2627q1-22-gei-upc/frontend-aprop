import '../../../core/network/api_client.dart';
import '../models/interest_question.dart';
import '../repositories/interest_test_repository.dart';

/// `GET` and `POST /preferences/test`; the server derives the user from the token.
class HttpInterestTestRepository implements InterestTestRepository {
  HttpInterestTestRepository({required this.apiClient});
  final ApiClient apiClient;

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
    final images = json['images'];
    final categories = json['categories'];
    return InterestQuestion(
      eventId: json['event-id']! as int,
      title: json['title']! as String,
      description: json['description'] as String? ?? '',
      // The server stores a comma-separated list; only the first is shown.
      imageUrl: images is String
          ? images
                .split(',')
                .map((url) => url.trim())
                .where((url) => url.startsWith('http'))
                .firstOrNull
          : null,
      categories: categories is List
          ? List.unmodifiable(
              categories.whereType<String>().where((c) => c.isNotEmpty),
            )
          : const [],
    );
  }
}
