import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/interest_test/data/http_interest_test_repository.dart';
import 'package:aprop/features/interest_test/models/interest_question.dart';
import 'package:aprop/features/interest_test/presentation/screens/interest_test_screen.dart';
import 'package:aprop/features/interest_test/presentation/view_models/interest_test_view_model.dart';
import 'package:aprop/features/interest_test/repositories/interest_test_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeInterestTestRepository implements InterestTestRepository {
  FakeInterestTestRepository(this.questions);
  final List<InterestQuestion> questions;
  final submitted = <List<InterestAnswer>>[];
  bool failLoad = false;
  bool failSubmit = false;

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    if (failLoad) throw Exception('load');
    return questions;
  }

  @override
  Future<void> submitAnswers(List<InterestAnswer> answers) async {
    if (failSubmit) throw Exception('submit');
    submitted.add(answers);
  }
}

const _questions = [
  InterestQuestion(eventId: 7, title: 'Concert a la plaça'),
  InterestQuestion(eventId: 9, title: 'Exposició de fotografia'),
];

List<Map<String, Object>> _answersOf(FakeInterestTestRepository repo) => [
  for (final a in repo.submitted.single)
    {'event-id': a.eventId, 'likes': a.likes},
];

void main() {
  group('HttpInterestTestRepository', () {
    test(
      'Loads questions and posts every answer to /preferences/test',
      () async {
        final requests = <http.Request>[];
        final repo = HttpInterestTestRepository(
          apiClient: ApiClient(
            idToken: () async => 'token',
            client: MockClient((request) async {
              requests.add(request);
              final body = request.method == 'GET'
                  ? [
                      {
                        'event-id': 7,
                        'title': 'Concert',
                        'description': 'Música',
                        'images': ' /local.png, https://img.test/a.jpg',
                        'categories': ['musica', ''],
                      },
                    ]
                  : {'user-id': 'x', 'preferences': []};
              return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
            }),
          ),
        );

        final questions = await repo.getQuestions();
        expect(questions.single.eventId, 7);
        expect(questions.single.imageUrl, 'https://img.test/a.jpg');
        expect(questions.single.categories, ['musica']);

        await repo.submitAnswers(const [
          InterestAnswer(eventId: 7, likes: true),
          InterestAnswer(eventId: 8, likes: false),
        ]);
        expect(requests.map((r) => '${r.method} ${r.url.path}'), [
          'GET /preferences/test',
          'POST /preferences/test',
        ]);
        expect(requests.last.headers['Authorization'], 'Bearer token');
        expect(jsonDecode(requests.last.body), {
          'answers': [
            {'event-id': 7, 'likes': true},
            {'event-id': 8, 'likes': false},
          ],
        });
      },
    );

    test(
      'Rejects a malformed question instead of showing an empty test',
      () async {
        final repo = HttpInterestTestRepository(
          apiClient: ApiClient(
            client: MockClient(
              (_) async => http.Response('[{"title": "Sense ID"}]', 200),
            ),
          ),
        );
        expect(repo.getQuestions(), throwsFormatException);
      },
    );
  });

  group('InterestTestViewModel', () {
    test('Sends the answers once the last activity is answered', () async {
      final repo = FakeInterestTestRepository(_questions);
      final model = InterestTestViewModel(repository: repo);
      await model.load();
      expect(model.current?.eventId, 7);

      await model.answer(likes: true);
      expect(repo.submitted, isEmpty);
      await model.answer(likes: false);

      expect(_answersOf(repo), [
        {'event-id': 7, 'likes': true},
        {'event-id': 9, 'likes': false},
      ]);
      expect(model.isCompleted, isTrue);
    });

    test('Keeps the answers after a failed submit and retries them', () async {
      final repo = FakeInterestTestRepository(_questions)..failSubmit = true;
      final model = InterestTestViewModel(repository: repo);
      await model.load();
      await model.answer(likes: true);
      await model.answer(likes: true);
      expect(model.submitError, isNotNull);
      expect(model.isCompleted, isFalse);

      repo.failSubmit = false;
      await model.submit();
      expect(repo.submitted.single, hasLength(2));
      expect(model.isCompleted, isTrue);
    });

    test('Shows an error when the questions cannot load', () async {
      final model = InterestTestViewModel(
        repository: FakeInterestTestRepository(_questions)..failLoad = true,
      );
      await model.load();
      expect(model.errorMessage, isNotNull);
      expect(model.current, isNull);
    });
  });

  group('InterestTestScreen', () {
    Future<FakeInterestTestRepository> pump(WidgetTester tester) async {
      final repo = FakeInterestTestRepository(_questions);
      await tester.pumpWidget(
        MaterialApp(
          home: InterestTestScreen(repository: repo, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('Swiping right likes and swiping left dislikes', (
      tester,
    ) async {
      final repo = await pump(tester);
      expect(find.text('1 de 2'), findsOneWidget);

      await tester.fling(
        find.text('Concert a la plaça'),
        const Offset(600, 0),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.text('2 de 2'), findsOneWidget);

      await tester.fling(
        find.text('Exposició de fotografia'),
        const Offset(-600, 0),
        2000,
      );
      await tester.pumpAndSettle();

      expect(_answersOf(repo), [
        {'event-id': 7, 'likes': true},
        {'event-id': 9, 'likes': false},
      ]);
      expect(find.textContaining('Hem actualitzat'), findsOneWidget);
    });

    testWidgets('Buttons answer without swiping', (tester) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('interest-test-like')));
      await tester.pumpAndSettle();
      expect(_answersOf(repo), [
        {'event-id': 7, 'likes': false},
        {'event-id': 9, 'likes': true},
      ]);
    });
  });
}
