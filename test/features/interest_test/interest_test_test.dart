import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/core/widgets/content_image.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/interest_test/data/demo_interest_test_repository.dart';
import 'package:aprop/features/interest_test/data/http_interest_test_repository.dart';
import 'package:aprop/features/interest_test/data/shared_preferences_interest_test_onboarding_memory.dart';
import 'package:aprop/features/interest_test/models/interest_question.dart';
import 'package:aprop/features/interest_test/presentation/screens/interest_test_screen.dart';
import 'package:aprop/features/interest_test/presentation/view_models/interest_test_view_model.dart';
import 'package:aprop/features/interest_test/repositories/interest_test_onboarding_memory.dart';
import 'package:aprop/features/interest_test/repositories/interest_test_repository.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeInterestTestRepository implements InterestTestRepository {
  FakeInterestTestRepository(
    this.questions, {
    this.completed = true,
    bool? prompted,
    this.failStatus = false,
  }) : prompted = prompted ?? completed;

  final List<InterestQuestion> questions;
  final submitted = <List<InterestAnswer>>[];
  final partialSubmitted = <List<InterestAnswer>>[];
  final Map<int, bool> partialAnswers = {};
  bool completed;
  bool prompted;
  bool failStatus;
  bool failLoad = false;
  bool failSubmit = false;
  bool failPartialSubmit = false;
  int statusCalls = 0;
  int promptedCalls = 0;
  int questionCalls = 0;

  @override
  Future<InterestTestStatus> getTestStatus() async {
    statusCalls++;
    if (failStatus) throw ApiException('unavailable', statusCode: 503);
    return InterestTestStatus(
      completed: completed,
      prompted: prompted || completed || partialAnswers.isNotEmpty,
      inProgress: partialAnswers.isNotEmpty,
      answeredCount: partialAnswers.length,
    );
  }

  @override
  Future<void> markOnboardingPrompted() async {
    promptedCalls++;
    prompted = true;
  }

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    questionCalls++;
    if (failLoad) throw Exception('load');
    return [
      for (final q in questions)
        if (!partialAnswers.containsKey(q.eventId)) q,
    ];
  }

  @override
  Future<void> submitAnswers(
    List<InterestAnswer> answers, {
    bool partial = false,
  }) async {
    if (partial) {
      if (failPartialSubmit || failSubmit) throw Exception('partial-submit');
      partialSubmitted.add(List.unmodifiable(answers));
      for (final a in answers) {
        partialAnswers[a.eventId] = a.likes;
      }
      prompted = true;
      return;
    }
    if (failSubmit) throw Exception('submit');
    final merged = <int, bool>{...partialAnswers};
    for (final a in answers) {
      merged[a.eventId] = a.likes;
    }
    submitted.add([
      for (final entry in merged.entries)
        InterestAnswer(eventId: entry.key, likes: entry.value),
    ]);
    partialAnswers.clear();
    completed = true;
    prompted = true;
  }
}

const _questions = [
  InterestQuestion(
    eventId: 7,
    title: 'Concert a la plaça',
    description: 'Una tarda de música en directe per a tots els públics.',
    categories: ['Musica', 'Concerts'],
  ),
  InterestQuestion(
    eventId: 9,
    title: 'Exposició de fotografia',
    description: 'Recorregut fotogràfic pel territori català.',
    categories: ['Exposicions'],
  ),
];

List<Map<String, Object>> _answersOf(
  FakeInterestTestRepository repo, [
  int index = 0,
]) => [
  for (final a in repo.submitted[index])
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
                        'description': '  Música en directe  ',
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
        expect(questions.single.description, 'Música en directe');
        expect(questions.single.imageUrl, 'https://img.test/a.jpg');
        expect(questions.single.imageAsset, isNull);
        expect(questions.single.categories, ['Música']);

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
      'Resolves relative Gencat /content/dam/ covers and keeps commas in URLs',
      () async {
        final repo = HttpInterestTestRepository(
          apiClient: ApiClient(
            client: MockClient(
              (_) async => http.Response.bytes(
                utf8.encode(
                  jsonEncode([
                    {
                      'event-id': 1,
                      'title': 'Dansa',
                      'images': '/content/dam/agenda/ca/Empordà festival.jpg,/content/dam/agenda/ca/other.jpg',
                      'categories': const <String>[],
                    },
                    {
                      'event-id': 2,
                      'title': 'Comma query',
                      'images': 'https://cdn.example.test/cover.jpg?crop=10,20, /content/dam/agenda/ca/second.jpg',
                      'categories': const <String>[],
                    },
                    {
                      'event-id': 3,
                      'title': 'Prefer image-url',
                      'image-url': 'https://s3.example.test/custom.jpg',
                      'images': '/content/dam/agenda/ca/fallback.jpg',
                      'categories': const <String>[],
                    },
                    {
                      'event-id': 4,
                      'title': 'Unsupported cover',
                      'images': 'javascript:alert(1), relative.jpg',
                      'categories': const <String>[],
                    },
                  ]),
                ),
                200,
              ),
            ),
          ),
        );

        final questions = await repo.getQuestions();
        expect(
          questions[0].imageUrl,
          'https://agenda.cultura.gencat.cat/content/dam/agenda/ca/Empord%C3%A0%20festival.jpg',
        );
        expect(
          questions[1].imageUrl,
          'https://cdn.example.test/cover.jpg?crop=10,20',
        );
        expect(questions[2].imageUrl, 'https://s3.example.test/custom.jpg');
        expect(questions[3].imageUrl, isNull);
        expect(questions[3].imageAsset, isNull);
      },
    );

    test('Prettifies agenda category and ambit tags, drops empty ones and deduplicates', () async {
      final repo = HttpInterestTestRepository(
        apiClient: ApiClient(
          client: MockClient(
            (_) async => http.Response.bytes(
              utf8.encode(
                jsonEncode([
                  {
                    'event-id': 10,
                    'title': 'Espectacle',
                    'images': '',
                    'categories': [
                      '',
                      '  ',
                      'agenda:categories/',
                      'agenda:ambits/',
                      'agenda:categories/dansa',
                      'agenda:ambits/espectacles',
                      'agenda:categories/arts-visuals',
                      'agenda:ambits/dansa',
                    ],
                  },
                ]),
              ),
              200,
            ),
          ),
        ),
      );

      final questions = await repo.getQuestions();
      expect(questions.single.categories, [
        'Dansa',
        'Espectacles',
        'Arts visuals',
      ]);
    });

    test(
      'Checks status via GET /preferences/test/status and marks prompted',
      () async {
        final requests = <http.Request>[];
        var responseBody = <String, Object?>{
          'completed': false,
          'prompted': false,
          'in-progress': false,
          'answered-count': 0,
          'date-taken': null,
        };
        final repo = HttpInterestTestRepository(
          apiClient: ApiClient(
            idToken: () async => 'token',
            client: MockClient((request) async {
              requests.add(request);
              if (request.url.path == '/preferences/test/prompted') {
                return http.Response('', 204);
              }
              return http.Response.bytes(
                utf8.encode(jsonEncode(responseBody)),
                200,
              );
            }),
          ),
        );

        final initial = await repo.getTestStatus();
        expect(initial.completed, isFalse);
        expect(initial.prompted, isFalse);
        expect(initial.inProgress, isFalse);
        expect(initial.answeredCount, 0);
        expect(initial.shouldPromptOnboarding, isTrue);
        expect(requests.single.method, 'GET');
        expect(requests.single.url.path, '/preferences/test/status');
        expect(requests.single.headers['Authorization'], 'Bearer token');

        await repo.markOnboardingPrompted();
        expect(requests.last.method, 'POST');
        expect(requests.last.url.path, '/preferences/test/prompted');

        responseBody = {
          'completed': false,
          'prompted': true,
          'in-progress': true,
          'answered-count': 5,
          'date-taken': null,
        };
        final paused = await repo.getTestStatus();
        expect(paused.completed, isFalse);
        expect(paused.prompted, isTrue);
        expect(paused.inProgress, isTrue);
        expect(paused.answeredCount, 5);
        expect(paused.shouldPromptOnboarding, isFalse);

        // Older backend response without new fields still parses cleanly.
        responseBody = {
          'completed': true,
          'date-taken': '2026-11-21T10:30:00Z',
        };
        final legacy = await repo.getTestStatus();
        expect(legacy.completed, isTrue);
        expect(legacy.prompted, isTrue);
        expect(legacy.inProgress, isFalse);
        expect(legacy.answeredCount, 0);
        expect(legacy.dateTaken, DateTime.utc(2026, 11, 21, 10, 30));
      },
    );

    test('Sends partial: true flag when saving partial progress', () async {
      final requests = <http.Request>[];
      final repo = HttpInterestTestRepository(
        apiClient: ApiClient(
          idToken: () async => 'token',
          client: MockClient((request) async {
            requests.add(request);
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'user-id': 'x',
                  'date-taken': '2026-11-21T10:30:00Z',
                  'preferences': const <Object>[],
                  'partial': true,
                  'answered-count': 1,
                }),
              ),
              200,
            );
          }),
        ),
      );

      await repo.submitAnswers(const [
        InterestAnswer(eventId: 7, likes: true),
      ], partial: true);
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/preferences/test');
      expect(jsonDecode(requests.single.body), {
        'answers': [
          {'event-id': 7, 'likes': true},
        ],
        'partial': true,
      });
    });

    test(
      'Rejects malformed status payloads and propagates HTTP errors',
      () async {
        for (final body in [
          <Object?>[],
          <String, Object?>{'date-taken': null},
          <String, Object?>{'completed': 'yes'},
          <String, Object?>{'completed': false, 'prompted': 'no'},
          <String, Object?>{'completed': false, 'answered-count': -1},
        ]) {
          final repo = HttpInterestTestRepository(
            apiClient: ApiClient(
              client: MockClient(
                (_) async =>
                    http.Response.bytes(utf8.encode(jsonEncode(body)), 200),
              ),
            ),
          );
          await expectLater(repo.getTestStatus(), throwsFormatException);
        }

        final failing = HttpInterestTestRepository(
          apiClient: ApiClient(
            client: MockClient(
              (_) async => http.Response('{"error":"not found"}', 404),
            ),
          ),
        );
        await expectLater(
          failing.getTestStatus(),
          throwsA(isA<ApiException>()),
        );
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

    test(
      'Passes active language query parameter on GET /preferences/test only',
      () async {
        final requests = <http.Request>[];
        var currentLang = 'en';
        final repo = HttpInterestTestRepository(
          apiClient: ApiClient(
            idToken: () async => 'token',
            language: () => currentLang,
            client: MockClient((request) async {
              requests.add(request);
              if (request.url.path == '/preferences/test/status') {
                return http.Response.bytes(
                  utf8.encode(
                    jsonEncode({'completed': false, 'date-taken': null}),
                  ),
                  200,
                );
              }
              if (request.method == 'POST') {
                return http.Response.bytes(
                  utf8.encode(jsonEncode({'user-id': 'x', 'preferences': []})),
                  200,
                );
              }
              return http.Response.bytes(
                utf8.encode(
                  jsonEncode([
                    {
                      'event-id': 7,
                      'title': 'Jazz Concert',
                      'description': 'Live music',
                      'images': '',
                      'categories': const <String>[],
                    },
                  ]),
                ),
                200,
              );
            }),
          ),
        );

        await repo.getTestStatus();
        final enQuestions = await repo.getQuestions();
        currentLang = 'es';
        await repo.getQuestions();
        await repo.submitAnswers(const [
          InterestAnswer(eventId: 7, likes: true),
        ]);

        expect(enQuestions.single.title, 'Jazz Concert');
        expect(requests[0].url.queryParameters, isEmpty);
        expect(requests[1].url.queryParameters, {'lang': 'en'});
        expect(requests[2].url.queryParameters, {'lang': 'es'});
        expect(requests[3].url.queryParameters, isEmpty);
      },
    );
  });

  group('DemoInterestTestRepository', () {
    test('Tracks completion, partial progress and resume locally', () async {
      final activities = DemoActivityRepository();
      final defaultRepo = DemoInterestTestRepository(
        activityRepository: activities,
      );
      final defaultStatus = await defaultRepo.getTestStatus();
      expect(defaultStatus.completed, isTrue);
      expect(defaultStatus.shouldPromptOnboarding, isFalse);

      final freshRepo = DemoInterestTestRepository(
        activityRepository: activities,
        completed: false,
      );
      expect((await freshRepo.getTestStatus()).shouldPromptOnboarding, isTrue);
      final questions = await freshRepo.getQuestions();
      expect(questions.length, greaterThanOrEqualTo(2));

      // Partial save excludes answered question on next getQuestions.
      await freshRepo.submitAnswers([
        InterestAnswer(eventId: questions.first.eventId, likes: true),
      ], partial: true);
      final paused = await freshRepo.getTestStatus();
      expect(paused.completed, isFalse);
      expect(paused.prompted, isTrue);
      expect(paused.inProgress, isTrue);
      expect(paused.answeredCount, 1);

      final remaining = await freshRepo.getQuestions();
      expect(
        remaining.any((q) => q.eventId == questions.first.eventId),
        isFalse,
      );
      expect(remaining.length, questions.length - 1);

      // Final submit merges partial + new answers and clears partial state.
      await freshRepo.submitAnswers([
        InterestAnswer(eventId: remaining.first.eventId, likes: false),
      ]);
      final done = await freshRepo.getTestStatus();
      expect(done.completed, isTrue);
      expect(done.inProgress, isFalse);
      expect(done.answeredCount, 0);
      expect(freshRepo.lastAnswers, hasLength(2));
    });
  });

  group('SharedPreferencesInterestTestOnboardingMemory', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Persists prompted flag per user id across instances', () async {
      const memoryA = SharedPreferencesInterestTestOnboardingMemory();
      const memoryB = SharedPreferencesInterestTestOnboardingMemory();

      expect(await memoryA.wasPrompted('uid-1'), isFalse);
      await memoryA.markPrompted('uid-1');

      expect(await memoryB.wasPrompted('uid-1'), isTrue);
      expect(await memoryB.wasPrompted('uid-2'), isFalse);
    });
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

    test('Reload resets completed state and previous answers', () async {
      final repo = FakeInterestTestRepository(_questions);
      final model = InterestTestViewModel(repository: repo);
      await model.load();
      await model.answer(likes: true);
      await model.answer(likes: false);
      expect(model.isCompleted, isTrue);

      await model.load();
      expect(model.isCompleted, isFalse);
      expect(model.answeredCount, 0);
      expect(model.current?.eventId, 7);
    });

    test(
      'Saves partial progress and resumes from remaining questions',
      () async {
        final repo = FakeInterestTestRepository(_questions, completed: false);
        final model = InterestTestViewModel(repository: repo);
        await model.load();
        expect(model.totalCount, 2);

        await model.answer(likes: true);
        expect(model.hasUnsavedAnswers, isTrue);

        final saved = await model.savePartialProgress();
        expect(saved, isTrue);
        expect(repo.partialSubmitted, hasLength(1));
        expect(repo.partialSubmitted.single.single.eventId, 7);
        expect(model.hasUnsavedAnswers, isFalse);
        expect(model.isCompleted, isFalse);

        // Reopening with a fresh ViewModel resumes from question 2 of 2.
        final resumed = InterestTestViewModel(repository: repo);
        await resumed.load();
        expect(resumed.previouslyAnsweredCount, 1);
        expect(resumed.answeredCount, 1);
        expect(resumed.totalCount, 2);
        expect(resumed.current?.eventId, 9);

        await resumed.answer(likes: false);
        expect(resumed.isCompleted, isTrue);
        expect(_answersOf(repo), [
          {'event-id': 7, 'likes': true},
          {'event-id': 9, 'likes': false},
        ]);
      },
    );

    test('Keeps unsaved answers when partial save fails', () async {
      final repo = FakeInterestTestRepository(_questions, completed: false)
        ..failPartialSubmit = true;
      final model = InterestTestViewModel(repository: repo);
      await model.load();
      await model.answer(likes: true);

      final saved = await model.savePartialProgress();
      expect(saved, isFalse);
      expect(model.partialSaveError, isNotNull);
      expect(model.hasUnsavedAnswers, isTrue);

      repo.failPartialSubmit = false;
      expect(await model.savePartialProgress(), isTrue);
      expect(repo.partialSubmitted.single.single.eventId, 7);
    });
  });

  group('InterestTestScreen', () {
    Future<FakeInterestTestRepository> pump(
      WidgetTester tester, {
      List<InterestQuestion> questions = _questions,
      VoidCallback? onBack,
      VoidCallback? onSkip,
      VoidCallback? onDone,
      VoidCallback? onCompleted,
      bool failLoad = false,
      Locale locale = const Locale('ca'),
    }) async {
      final repo = FakeInterestTestRepository(questions)..failLoad = failLoad;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: InterestTestScreen(
            repository: repo,
            onBack: onBack,
            onSkip: onSkip,
            onDone: onDone,
            onCompleted: onCompleted,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('Swiping right likes and swiping left dislikes', (
      tester,
    ) async {
      var completedCalls = 0;
      final repo = await pump(
        tester,
        onBack: () {},
        onCompleted: () => completedCalls++,
      );
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('interest-test-skip')), findsNothing);

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
      expect(completedCalls, 1);
      expect(find.textContaining('Hem actualitzat'), findsOneWidget);
      expect(find.text('Tornar a la configuració'), findsOneWidget);
    });

    testWidgets('Buttons answer without swiping', (tester) async {
      final repo = await pump(tester, onBack: () {});
      await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('interest-test-like')));
      await tester.pumpAndSettle();
      expect(_answersOf(repo), [
        {'event-id': 7, 'likes': false},
        {'event-id': 9, 'likes': true},
      ]);
    });

    testWidgets(
      'Renders compact 16:9 high-quality image, truncates long descriptions with localized Llegir més toggle and hides it for short text',
      (tester) async {
        // 390x844 logical phone at 2x DPR.
        tester.view.physicalSize = const Size(780, 1688);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final longDescription = List.filled(
          40,
          'Text llarg de descripció cultural.',
        ).join(' ');
        await pump(
          tester,
          onBack: () {},
          questions: [
            InterestQuestion(
              eventId: 11,
              title: 'Festival de dansa',
              description: longDescription,
              categories: const ['Dansa', 'Espectacles'],
            ),
            const InterestQuestion(
              eventId: 12,
              title: 'Concert breu',
              description: 'Descripció curta.',
              categories: ['Musica'],
            ),
          ],
        );

        expect(find.widgetWithText(Chip, 'Dansa'), findsOneWidget);
        expect(find.widgetWithText(Chip, 'Espectacles'), findsOneWidget);
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);

        // Image is compact (<= 196 px) with high filter quality and cacheWidth.
        final imageBox = tester.getSize(
          find.byKey(const ValueKey('interest-test-card-image')),
        );
        expect(imageBox.height, lessThanOrEqualTo(196));
        expect(imageBox.height, greaterThanOrEqualTo(96));
        final contentImage = tester.widget<ContentImage>(
          find.byType(ContentImage),
        );
        expect(contentImage.fit, BoxFit.cover);
        expect(contentImage.filterQuality, FilterQuality.high);
        expect(contentImage.cacheWidth, isNotNull);

        // Long description starts truncated at 5 lines with "Llegir més" toggle.
        var descriptionWidget = tester.widget<Text>(find.text(longDescription));
        expect(descriptionWidget.maxLines, 5);
        expect(descriptionWidget.overflow, TextOverflow.ellipsis);
        final readMoreFinder = find.byKey(
          const ValueKey('interest-test-read-more'),
        );
        expect(find.text('Llegir més'), findsOneWidget);

        // Expanding removes line cap and switches toggle label to "Llegir menys".
        await tester.ensureVisible(readMoreFinder);
        await tester.pumpAndSettle();
        await tester.tap(readMoreFinder);
        await tester.pumpAndSettle();
        descriptionWidget = tester.widget<Text>(find.text(longDescription));
        expect(descriptionWidget.maxLines, isNull);
        expect(find.text('Llegir menys'), findsOneWidget);

        // Collapsing restores truncation.
        await tester.ensureVisible(readMoreFinder);
        await tester.pumpAndSettle();
        await tester.tap(readMoreFinder);
        await tester.pumpAndSettle();
        descriptionWidget = tester.widget<Text>(find.text(longDescription));
        expect(descriptionWidget.maxLines, 5);
        expect(find.text('Llegir més'), findsOneWidget);

        // Next card with short description does not show "Llegir més".
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        expect(find.text('Descripció curta.'), findsOneWidget);
        expect(readMoreFinder, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Read more / Read less toggle is localized in Spanish and English',
      (tester) async {
        final longDescription = List.filled(
          40,
          'Descripción cultural suficientemente larga para superar cinco líneas.',
        ).join(' ');
        final q = [
          InterestQuestion(
            eventId: 21,
            title: 'Teatro',
            description: longDescription,
          ),
        ];

        await pump(
          tester,
          onBack: () {},
          questions: q,
          locale: const Locale('es'),
        );
        expect(find.text('Leer más'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-read-more')));
        await tester.pumpAndSettle();
        expect(find.text('Leer menos'), findsOneWidget);

        await pump(
          tester,
          onBack: () {},
          questions: q,
          locale: const Locale('en'),
        );
        expect(find.text('Read more'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-read-more')));
        await tester.pumpAndSettle();
        expect(find.text('Read less'), findsOneWidget);
      },
    );

    testWidgets(
      'Onboarding mode exposes localized Més tard action that saves partial progress and Continue on completion',
      (tester) async {
        var skipped = 0;
        var done = 0;
        final repo = await pump(
          tester,
          onSkip: () => skipped++,
          onDone: () => done++,
          locale: const Locale('ca'),
        );
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.text('Més tard'), findsOneWidget);

        // Answer 1 question and tap "Més tard" -> saves partial progress.
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();
        expect(skipped, 1);
        expect(repo.partialSubmitted, hasLength(1));
        expect(repo.partialSubmitted.single.single.eventId, 7);
        expect(repo.partialSubmitted.single.single.likes, isTrue);

        // Answer remaining question: skip hides and Continue finishes.
        await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('interest-test-skip')), findsNothing);
        expect(find.text('Continua'), findsOneWidget);
        await tester.tap(find.text('Continua'));
        await tester.pumpAndSettle();
        expect(done, 1);
        expect(_answersOf(repo), [
          {'event-id': 7, 'likes': true},
          {'event-id': 9, 'likes': false},
        ]);
      },
    );

    testWidgets(
      'Later action stays available in Spanish/English and on load failure',
      (tester) async {
        var skipped = 0;
        await pump(
          tester,
          onSkip: () => skipped++,
          failLoad: true,
          locale: const Locale('es'),
        );
        expect(find.text('Más tarde'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        expect(skipped, 1);

        await pump(tester, onSkip: () {}, locale: const Locale('en'));
        expect(find.text('Later'), findsOneWidget);
      },
    );

    testWidgets(
      'Failed partial save shows SnackBar with leave-without-saving escape hatch',
      (tester) async {
        var skipped = 0;
        final repo = await pump(
          tester,
          onSkip: () => skipped++,
          locale: const Locale('ca'),
        );
        repo.failPartialSubmit = true;

        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();

        expect(skipped, 0);
        expect(find.text('Sortir sense desar'), findsOneWidget);

        await tester.tap(find.text('Sortir sense desar'));
        await tester.pumpAndSettle();
        expect(skipped, 1);
      },
    );
  });

  group('Onboarding gating and retake flow', () {
    Future<DemoAuthRepository> signedInAuth() async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      return auth;
    }

    Future<void> pumpApp(
      WidgetTester tester, {
      required DemoAuthRepository auth,
      required FakeInterestTestRepository interestTestRepository,
      InterestTestOnboardingMemory? onboardingMemory,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          interestTestRepository: interestTestRepository,
          interestTestOnboardingMemory: onboardingMemory,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Auto-appears once for a new unprompted account, persists prompted state across restarts and never re-appears on later logins',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(
          _questions,
          completed: false,
          prompted: false,
        );
        final memory = InMemoryInterestTestOnboardingMemory();

        await pumpApp(
          tester,
          auth: auth,
          interestTestRepository: repo,
          onboardingMemory: memory,
        );

        expect(repo.statusCalls, 1);
        expect(repo.promptedCalls, 1);
        expect(repo.prompted, isTrue);
        expect(find.text('Test d’interessos'), findsOneWidget);
        expect(find.text('Més tard'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);

        // Signing out and back in does not re-open onboarding.
        await auth.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Inicia sessió'), findsOneWidget);

        await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Test d’interessos'), findsNothing);

        // Simulating a full app restart (new APropApp + fresh local memory)
        // still respects server-side prompted = true and enters MainShell.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          auth: auth,
          interestTestRepository: repo,
          onboardingMemory: InMemoryInterestTestOnboardingMemory(),
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Test d’interessos'), findsNothing);
      },
    );

    testWidgets(
      'Existing account already marked prompted (even if uncompleted) never auto-opens onboarding on login',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(
          _questions,
          completed: false,
          prompted: true,
        );

        await pumpApp(tester, auth: auth, interestTestRepository: repo);

        expect(repo.statusCalls, 1);
        expect(repo.promptedCalls, 0);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Test d’interessos'), findsNothing);
      },
    );

    testWidgets(
      'Pausing onboarding with Més tard saves partial progress and resuming from Settings skips answered events',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(
          _questions,
          completed: false,
          prompted: false,
        );

        await pumpApp(tester, auth: auth, interestTestRepository: repo);

        // Answer 1st event and tap Més tard.
        expect(find.text('1 de 2'), findsOneWidget);
        expect(find.text('Concert a la plaça'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(repo.partialAnswers, {7: true});
        expect(repo.completed, isFalse);

        // Open Settings > Account > Test d'interessos: resumes at 2 de 2 without repeating event 7.
        await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Configuració'));
        await tester.pumpAndSettle();

        final testTile = find.byKey(const ValueKey('profile-interest-test'));
        final settingsScroll = find.descendant(
          of: find.byKey(const PageStorageKey('profile-settings-scroll')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          testTile,
          200,
          scrollable: settingsScroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(testTile);
        await tester.pumpAndSettle();

        expect(find.text('2 de 2'), findsOneWidget);
        expect(find.text('Exposició de fotografia'), findsOneWidget);
        expect(find.text('Concert a la plaça'), findsNothing);

        // Complete the remaining event.
        await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
        await tester.pumpAndSettle();

        expect(repo.completed, isTrue);
        expect(repo.partialAnswers, isEmpty);
        expect(_answersOf(repo), [
          {'event-id': 7, 'likes': true},
          {'event-id': 9, 'likes': false},
        ]);
      },
    );

    testWidgets(
      'Completing onboarding submits answers and enters the app via Continua',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(_questions, completed: false);

        await pumpApp(tester, auth: auth, interestTestRepository: repo);

        expect(find.text('Test d’interessos'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
        await tester.pumpAndSettle();

        expect(repo.submitted, hasLength(1));
        expect(find.text('Continua'), findsOneWidget);

        await tester.tap(find.text('Continua'));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);
      },
    );

    testWidgets('Status failure never blocks entry into the app', (
      tester,
    ) async {
      final auth = await signedInAuth();
      final repo = FakeInterestTestRepository(
        _questions,
        completed: false,
        failStatus: true,
      );

      await pumpApp(tester, auth: auth, interestTestRepository: repo);

      expect(repo.statusCalls, 1);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Test d’interessos'), findsNothing);
    });

    testWidgets(
      'Retaking from Profile > Settings starts fresh every time, supports Més tard and posts updated answers',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(_questions, completed: true);

        await pumpApp(tester, auth: auth, interestTestRepository: repo);

        // Already completed: lands straight in MainShell.
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Configuració'));
        await tester.pumpAndSettle();

        final retakeTile = find.byKey(const ValueKey('profile-interest-test'));
        final settingsScroll = find.descendant(
          of: find.byKey(const PageStorageKey('profile-settings-scroll')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          retakeTile,
          200,
          scrollable: settingsScroll,
        );
        await tester.pumpAndSettle();

        // First retake.
        await tester.tap(retakeTile);
        await tester.pumpAndSettle();
        expect(find.text('1 de 2'), findsOneWidget);
        expect(find.text('Més tard'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();

        expect(repo.submitted, hasLength(1));
        expect(_answersOf(repo, 0), [
          {'event-id': 7, 'likes': true},
          {'event-id': 9, 'likes': true},
        ]);
        expect(find.text('Tornar a la configuració'), findsOneWidget);
        await tester.tap(find.text('Tornar a la configuració'));
        await tester.pumpAndSettle();

        // Second retake must start fresh with no stale completed state.
        await tester.ensureVisible(retakeTile);
        await tester.pumpAndSettle();
        await tester.tap(retakeTile);
        await tester.pumpAndSettle();

        expect(find.text('1 de 2'), findsOneWidget);
        expect(find.text('Tornar a la configuració'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();

        expect(repo.submitted, hasLength(2));
        expect(_answersOf(repo, 1), [
          {'event-id': 7, 'likes': false},
          {'event-id': 9, 'likes': true},
        ]);
        expect(repo.questionCalls, 2);
      },
    );
  });
}
