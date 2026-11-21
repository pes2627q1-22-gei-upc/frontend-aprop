import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/interest_test/data/demo_interest_test_repository.dart';
import 'package:aprop/features/interest_test/data/http_interest_test_repository.dart';
import 'package:aprop/features/interest_test/models/interest_question.dart';
import 'package:aprop/features/interest_test/presentation/screens/interest_test_screen.dart';
import 'package:aprop/features/interest_test/presentation/view_models/interest_test_view_model.dart';
import 'package:aprop/features/interest_test/repositories/interest_test_repository.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeInterestTestRepository implements InterestTestRepository {
  FakeInterestTestRepository(
    this.questions, {
    this.completed = true,
    this.failStatus = false,
  });

  final List<InterestQuestion> questions;
  final submitted = <List<InterestAnswer>>[];
  bool completed;
  bool failStatus;
  bool failLoad = false;
  bool failSubmit = false;
  int statusCalls = 0;
  int questionCalls = 0;

  @override
  Future<bool> hasCompletedTest() async {
    statusCalls++;
    if (failStatus) throw ApiException('unavailable', statusCode: 503);
    return completed;
  }

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    questionCalls++;
    if (failLoad) throw Exception('load');
    return questions;
  }

  @override
  Future<void> submitAnswers(List<InterestAnswer> answers) async {
    if (failSubmit) throw Exception('submit');
    submitted.add(answers);
    completed = true;
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
        expect(questions.single.categories, ['Musica']);

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

    test('Checks completion status via GET /preferences/test/status', () async {
      final requests = <http.Request>[];
      var responseBody = <String, Object?>{
        'completed': false,
        'date-taken': null,
      };
      final repo = HttpInterestTestRepository(
        apiClient: ApiClient(
          idToken: () async => 'token',
          client: MockClient((request) async {
            requests.add(request);
            return http.Response.bytes(
              utf8.encode(jsonEncode(responseBody)),
              200,
            );
          }),
        ),
      );

      expect(await repo.hasCompletedTest(), isFalse);
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/preferences/test/status');
      expect(requests.single.headers['Authorization'], 'Bearer token');

      responseBody = {'completed': true, 'date-taken': '2026-11-21T10:30:00Z'};
      expect(await repo.hasCompletedTest(), isTrue);
    });

    test(
      'Rejects malformed status payloads and propagates HTTP errors',
      () async {
        for (final body in [
          <Object?>[],
          <String, Object?>{'date-taken': null},
          <String, Object?>{'completed': 'yes'},
        ]) {
          final repo = HttpInterestTestRepository(
            apiClient: ApiClient(
              client: MockClient(
                (_) async =>
                    http.Response.bytes(utf8.encode(jsonEncode(body)), 200),
              ),
            ),
          );
          await expectLater(repo.hasCompletedTest(), throwsFormatException);
        }

        final failing = HttpInterestTestRepository(
          apiClient: ApiClient(
            client: MockClient(
              (_) async => http.Response('{"error":"not found"}', 404),
            ),
          ),
        );
        await expectLater(
          failing.hasCompletedTest(),
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
  });

  group('DemoInterestTestRepository', () {
    test('Tracks completion locally and defaults to completed', () async {
      final activities = DemoActivityRepository();
      final defaultRepo = DemoInterestTestRepository(
        activityRepository: activities,
      );
      expect(await defaultRepo.hasCompletedTest(), isTrue);

      final freshRepo = DemoInterestTestRepository(
        activityRepository: activities,
        completed: false,
      );
      expect(await freshRepo.hasCompletedTest(), isFalse);
      final questions = await freshRepo.getQuestions();
      expect(questions, isNotEmpty);

      await freshRepo.submitAnswers([
        InterestAnswer(eventId: questions.first.eventId, likes: true),
      ]);
      expect(await freshRepo.hasCompletedTest(), isTrue);
      expect(freshRepo.lastAnswers, hasLength(1));
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
      'Renders readable categories, truncates long descriptions and shows placeholder without image',
      (tester) async {
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
          ],
        );

        expect(find.widgetWithText(Chip, 'Dansa'), findsOneWidget);
        expect(find.widgetWithText(Chip, 'Espectacles'), findsOneWidget);
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);

        final descriptionWidget = tester.widget<Text>(
          find.text(longDescription),
        );
        expect(descriptionWidget.maxLines, 3);
        expect(descriptionWidget.overflow, TextOverflow.ellipsis);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Onboarding mode exposes localized skip action and Continue on completion',
      (tester) async {
        var skipped = 0;
        var done = 0;
        await pump(
          tester,
          onSkip: () => skipped++,
          onDone: () => done++,
          locale: const Locale('ca'),
        );
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.text('Ara no'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();
        expect(skipped, 1);

        // Complete the test in onboarding mode: skip hides and Continue finishes.
        await tester.tap(find.byKey(const ValueKey('interest-test-like')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('interest-test-dislike')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('interest-test-skip')), findsNothing);
        expect(find.text('Continua'), findsOneWidget);
        await tester.tap(find.text('Continua'));
        await tester.pumpAndSettle();
        expect(done, 1);
      },
    );

    testWidgets(
      'Skip action stays available in Spanish/English and on load failure',
      (tester) async {
        var skipped = 0;
        await pump(
          tester,
          onSkip: () => skipped++,
          failLoad: true,
          locale: const Locale('es'),
        );
        expect(find.text('Ahora no'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        expect(skipped, 1);

        await pump(tester, onSkip: () {}, locale: const Locale('en'));
        expect(find.text('Not now'), findsOneWidget);
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
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          interestTestRepository: interestTestRepository,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Shows onboarding automatically when not completed, skips with Ara no and does not force again this run',
      (tester) async {
        final auth = await signedInAuth();
        final repo = FakeInterestTestRepository(_questions, completed: false);

        await pumpApp(tester, auth: auth, interestTestRepository: repo);

        expect(repo.statusCalls, 1);
        expect(find.text('Test d’interessos'), findsOneWidget);
        expect(find.text('Ara no'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        await tester.tap(find.byKey(const ValueKey('interest-test-skip')));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);

        // Signing out and back in as the same user in this run does not re-open onboarding.
        await auth.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Inicia sessió'), findsOneWidget);

        await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Test d’interessos'), findsNothing);
        expect(repo.statusCalls, 1);
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
      'Retaking from Profile > Settings starts fresh every time and posts updated answers',
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
        expect(find.byKey(const ValueKey('interest-test-skip')), findsNothing);

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
