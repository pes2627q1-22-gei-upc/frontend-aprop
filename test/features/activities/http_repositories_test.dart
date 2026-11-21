import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/data/http_discovery_repository.dart';
import 'package:aprop/features/activities/data/http_enrollment_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/assistant/data/http_assistant_repository.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../notifications/backend_notification_fixture.dart';

void main() {
  http.Response jsonResponse(Object? body, [int status = 200]) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json'},
      );

  Map<String, Object?> sampleEventJson({
    int id = 101,
    String title = 'Concert de Jazz a Girona',
    bool isOfficial = true,
  }) => {
    'id': id,
    'code': isOfficial ? 2026101 : 0,
    'is-official': isOfficial,
    'title': title,
    'description': 'Concert en directe a l’Auditori.',
    'free': true,
    'place': 'Auditori de Girona',
    'address': 'Pg. de la Devesa, 35',
    'latitude': 41.9831,
    'longitude': 2.8169,
    'municipality': 'agenda:ubicacions/girona/girones/girona',
    'start-date': '2026-11-14T19:30:00Z',
    'categories': ['agenda:categories/musica'],
  };

  group('HttpActivityRepository', () {
    test('Llista, consulta detall i crea esdeveniments no oficials', () async {
      final requests = <http.Request>[];
      final apiClient = ApiClient(
        idToken: () async => 'token-1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' && request.url.path == '/events') {
            return jsonResponse([sampleEventJson()]);
          }
          if (request.method == 'GET' && request.url.path == '/events/101') {
            return jsonResponse(sampleEventJson());
          }
          if (request.method == 'POST' && request.url.path == '/events') {
            final payload = jsonDecode(request.body) as Map<String, Object?>;
            return jsonResponse({
              ...sampleEventJson(
                id: 505,
                title: payload['title'] as String,
                isOfficial: false,
              ),
            }, 201);
          }
          return jsonResponse({'error': 'not found'}, 404);
        }),
      );

      final repo = HttpActivityRepository(apiClient: apiClient);

      final list = await repo.getActivities();
      expect(list, hasLength(1));
      expect(list.single.id, '101');
      expect(list.single.title, 'Concert de Jazz a Girona');
      expect(list.single.category, 'Música');
      expect(list.single.municipality, 'Girona');

      final detail = await repo.getActivityById('101');
      expect(detail?.id, '101');
      expect(await repo.getActivityById('999'), isNull);

      final created = await repo.createActivity(
        NewActivity(
          title: 'Trobada acústica',
          description: 'Jam session oberta.',
          categories: ['Música'],
          startsAt: DateTime(2026, 11, 20, 18),
          municipality: 'Barcelona',
          imageAsset: 'assets/images/jazz_al_parc.jpg',
          creator: const ActivityCreator(
            name: 'Laia Soler',
            userId: 'uid-1',
            isFriend: false,
          ),
          location: const GeoPoint(latitude: 41.38, longitude: 2.17),
          price: 0,
        ),
      );

      expect(created.id, '505');
      expect(created.title, 'Trobada acústica');
      expect(created.source, ActivitySource.community);
      expect(created.creator?.userId, 'uid-1');
    });

    group('Crear (POST /events)', () {
      late Map<String, Object?> sent;

      HttpActivityRepository repository() => HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            sent = jsonDecode(
              utf8.decode(request.bodyBytes),
            ) as Map<String, Object?>;
            return jsonResponse(
              sampleEventJson(id: 506, isOfficial: false),
              201,
            );
          }),
        ),
      );

      NewActivity newActivity({
        double? price,
        String? directions,
        DateTime? endsAt,
      }) => NewActivity(
        title: 'Taller de ceràmica',
        description: 'Per a tots els nivells.',
        categories: ['agenda:categories/exposicions'],
        startsAt: DateTime(2026, 11, 7, 0, 30),
        endsAt: endsAt,
        municipality: 'Sant Cugat del Vallès',
        imageAsset: 'assets/images/jazz_al_parc.jpg',
        creator: const ActivityCreator(
          name: 'Pol Vidal',
          userId: 'uid-1',
          isFriend: false,
        ),
        directions: directions,
        price: price,
      );

      test('Envia l’hora d’aquí sense canviar de dia i l’etiqueta', () async {
        await repository().createActivity(
          newActivity(price: 0, directions: 'Entrada pel pati'),
        );

        // Passada a UTC, les 00.30 h serien el dia 6.
        expect(sent['start-date'], '2026-11-07T00:30:00.000Z');
        expect(sent['categories'], ['agenda:categories/exposicions']);
        expect(sent['free'], isTrue);
        // Les indicacions només a l'adreça: lloc i adreça s'ajunten en llegir.
        expect(sent['address'], 'Entrada pel pati');
        expect(sent.containsKey('place'), isFalse);
      });

      test('Sense preu, no diu que sigui gratuïta', () async {
        await repository().createActivity(newActivity());

        expect(sent.containsKey('free'), isFalse);
        expect(sent['address'], '');
      });

      test('Sense data de fi, acaba el dia que comença', () async {
        await repository().createActivity(newActivity());

        expect(sent['end-date'], sent['start-date']);
      });

      test('Envia la data de fi amb l’hora d’aquí', () async {
        await repository().createActivity(
          newActivity(endsAt: DateTime(2026, 11, 8, 0, 15)),
        );

        expect(sent['end-date'], '2026-11-08T00:15:00.000Z');
      });
    });

    test('Editar: envia PUT /events/{id} i torna la data de fi', () async {
      late http.Request received;
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            received = request;
            final payload = jsonDecode(request.body) as Map<String, Object?>;
            return jsonResponse({
              ...sampleEventJson(
                id: 506,
                title: payload['title'] as String,
                isOfficial: false,
              ),
              'start-date': payload['start-date'],
              'end-date': payload['end-date'],
            });
          }),
        ),
      );

      final updated = await repository.updateActivity(
        '506',
        NewActivity(
          title: 'Taller nou',
          description: 'Ara a la tarda.',
          categories: ['agenda:categories/exposicions'],
          startsAt: DateTime(2026, 12, 7, 18),
          endsAt: DateTime(2026, 12, 7, 20),
          imageAsset: 'assets/images/jazz_al_parc.jpg',
          creator: const ActivityCreator(name: 'Pol Vidal', isFriend: false),
        ),
      );

      expect(received.method, 'PUT');
      expect(received.url.path, '/events/506');
      expect(updated.id, '506');
      expect(updated.title, 'Taller nou');
      expect(updated.startsAt, DateTime(2026, 12, 7, 18));
      expect(updated.endsAt, DateTime(2026, 12, 7, 20));
    });

    test('Sense data de fi diferent de l’inici, no n’hi ha', () async {
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient(
            (request) async => jsonResponse({
              ...sampleEventJson(),
              'end-date': '2026-11-14T19:30:00Z',
            }),
          ),
        ),
      );

      final activity = await repository.getActivityById('101');

      expect(activity!.endsAt, isNull);
    });
    group('Informació extra', () {
      Future<Activity> read(Map<String, Object?> extra) async {
        final repository = HttpActivityRepository(
          apiClient: ApiClient(
            client: MockClient(
              (request) async => jsonResponse({...sampleEventJson(), ...extra}),
            ),
          ),
        );
        return (await repository.getActivityById('101'))!;
      }

      test('Llegeix totes les categories, l’horari i la modalitat', () async {
        final activity = await read({
          'categories': [
            'agenda:categories/teatre',
            'agenda:categories/exposicions',
          ],
          'schedule': ' 19.30 h ',
          'modality': 'Online and Face-to-Face',
          'permanent': true,
          'tickets': '10 €',
          'email': 'info@example.cat',
          'phone': '972 00 00 00',
        });

        expect(activity.categories, ['Teatre', 'Exposicions']);
        expect(activity.category, 'Teatre');
        expect(activity.schedule, '19.30 h');
        expect(activity.modality, ActivityModality.mixed);
        expect(activity.isPermanent, isTrue);
        expect(activity.tickets, '10 €');
        expect(activity.email, 'info@example.cat');
        expect(activity.phone, '972 00 00 00');
      });

      test('Sense aquests camps, no s’inventa res', () async {
        final activity = await read({});

        expect(activity.schedule, isNull);
        expect(activity.modality, isNull);
        expect(activity.isPermanent, isFalse);
        expect(activity.links, isEmpty);
        expect(activity.website, isNull);
      });

      test('Separa els enllaços relacionats i en llegeix els noms', () async {
        final activity = await read({
          'url': 'https://auditori.cat/concert',
          'related-urls':
              'https://example.cat/a?x=1,2, https://www.programa.cat/b',
          'url-names': 'Programa de mà, Web del festival',
          'activity-url': 'no és un enllaç',
        });

        expect(activity.website, 'https://auditori.cat/concert');
        expect(activity.onlineUrl, isNull);
        expect(activity.links.map((link) => (link.name, link.url)), [
          ('Programa de mà', 'https://example.cat/a?x=1,2'),
          ('Web del festival', 'https://www.programa.cat/b'),
        ]);
      });

      test('Si els noms no hi quadren, fa servir el domini', () async {
        final activity = await read({
          'related-urls': 'https://www.programa.cat/b, https://example.cat/a',
          'url-names': 'Programa, de mà, i més',
        });

        expect(activity.links.map((link) => link.name), [
          'programa.cat',
          'example.cat',
        ]);
      });

      test('Envia les categories, l’horari, la modalitat i l’enllaç', () async {
        late Map<String, Object?> sent;
        final repository = HttpActivityRepository(
          apiClient: ApiClient(
            client: MockClient((request) async {
              sent = jsonDecode(request.body) as Map<String, Object?>;
              return jsonResponse(
                sampleEventJson(id: 506, isOfficial: false),
                201,
              );
            }),
          ),
        );

        final created = await repository.createActivity(
          NewActivity(
            title: 'Xerrada',
            description: 'En directe.',
            categories: [
              'agenda:categories/conferencies',
              'agenda:categories/teatre',
            ],
            startsAt: DateTime(2026, 11, 7, 18),
            imageAsset: 'assets/images/jazz_al_parc.jpg',
            creator: const ActivityCreator(name: 'Pol Vidal', isFriend: false),
            schedule: '18.00 h · Durada: 1 h',
            modality: ActivityModality.online,
            isPermanent: true,
            onlineUrl: 'https://meet.example.cat/xerrada',
          ),
        );

        expect(sent['categories'], [
          'agenda:categories/conferencies',
          'agenda:categories/teatre',
        ]);
        expect(sent['schedule'], '18.00 h · Durada: 1 h');
        expect(sent['modality'], 'Online');
        expect(sent['permanent'], isTrue);
        expect(sent['activity-url'], 'https://meet.example.cat/xerrada');
        // Si la resposta no ho torna, es manté el que s'ha enviat.
        expect(created.schedule, '18.00 h · Durada: 1 h');
        expect(created.modality, ActivityModality.online);
        expect(created.onlineUrl, 'https://meet.example.cat/xerrada');
      });
    });

    test(
      'Categories: les de l’Agenda Cultural, ordenades i llegibles',
      () async {
        final repo = HttpActivityRepository(
          apiClient: ApiClient(
            client: MockClient((request) async {
              expect(request.url.path, '/categories');
              return jsonResponse([
                {'id': 1, 'name': 'agenda:categories/teatre'},
                {'id': 13, 'name': ''},
                {'id': 20, 'name': 'agenda:categories/cultura-digital'},
                {'id': 27, 'name': 'agenda:ambits/musica'},
                {'id': 34, 'name': 'Música'},
              ]);
            }),
          ),
        );

        final categories = await repo.getCreationCategories();

        expect(categories.map((c) => c.label), ['Cultura digital', 'Teatre']);
        // Es desa l'etiqueta, perquè l'activitat quedi a la categoria que ja
        // existeix en lloc de crear-ne una de nova.
        expect(categories.map((c) => c.value), [
          'agenda:categories/cultura-digital',
          'agenda:categories/teatre',
        ]);
      },
    );
  });

  group('HttpEnrollmentRepository', () {
    test('Sincronitza inscripcions, inscriu i cancel·la inscripció', () async {
      final apiClient = ApiClient(
        client: MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path == '/users/uid-1/events') {
            return jsonResponse([sampleEventJson(id: 101)]);
          }
          if (request.method == 'POST' &&
              request.url.path == '/events/202/signup') {
            return jsonResponse({
              'user-id': 'uid-1',
              'event-id': 202,
              'created': true,
            }, 201);
          }
          if (request.method == 'DELETE' &&
              request.url.path == '/events/101/signup') {
            return jsonResponse({
              'user-id': 'uid-1',
              'event-id': 101,
              'enrolled': false,
              'deleted': true,
            }, 200);
          }
          if (request.method == 'GET' &&
              request.url.path == '/events/202/signup') {
            return jsonResponse({
              'event-id': 202,
              'is-enrolled': true,
              'enrolled-count': 15,
            }, 200);
          }
          return jsonResponse({'error': 'unexpected'}, 400);
        }),
      );

      final repo = HttpEnrollmentRepository(apiClient: apiClient);
      addTearDown(repo.dispose);

      final emitted = <Set<String>>[];
      final sub = repo.watchEnrolledActivityIds('uid-1').listen(emitted.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, {'101'});

      await repo.enroll(userId: 'uid-1', activityId: '202');
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, {'101', '202'});

      await repo.unenroll(userId: 'uid-1', activityId: '101');
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, {'202'});

      final status = await repo.getEnrollmentStatus('202');
      expect(status.isEnrolled, isTrue);
      expect(status.enrolledCount, 15);
    });
  });

  group('HttpDiscoveryRepository & HttpAssistantRepository', () {
    test('Cerca esdeveniments i envia consultes al xatbot', () async {
      final apiClient = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          if (request.url.path == '/events/search') {
            return jsonResponse({
              'query': request.url.queryParameters['q'],
              'total': 1,
              'page-num': 0,
              'page-size': 20,
              'events': [sampleEventJson(id: 101)],
            });
          }
          if (request.url.path == '/assistant/messages') {
            return jsonResponse({
              'conversation-started-at': '2026-10-25T18:00:00Z',
              'user-message': {
                'sent-at': '2026-10-25T18:00:00Z',
                'sender': 'user',
                'text': 'Concerts a Girona',
                'by-voice': false,
              },
              'assistant-message': {
                'sent-at': '2026-10-25T18:00:02Z',
                'sender': 'assistant',
                'text': 'Et recomano aquest concert a Girona:',
                'by-voice': false,
                'interpretation': {
                  'category': 'Música',
                  'municipality': 'Girona',
                  'date-range': 'del 14/11/2026 al 15/11/2026',
                },
                'recommended-events': [sampleEventJson(id: 101)],
              },
            }, 201);
          }
          return jsonResponse([]);
        }),
      );

      final discovery = HttpDiscoveryRepository(apiClient: apiClient);
      final searchResults = (await discovery.searchActivitiesPage('Girona'))
          .activities;
      expect(searchResults, hasLength(1));
      expect(searchResults.single.id, '101');

      final assistant = HttpAssistantRepository(apiClient: apiClient);
      final reply = await assistant.sendMessage('Concerts a Girona');
      expect(reply.sender, AssistantMessageSender.assistant);
      expect(reply.text, 'Et recomano aquest concert a Girona:');
      expect(reply.interpretation?.municipality, 'Girona');
      expect(reply.recommendedActivities, hasLength(1));
      expect(reply.recommendedActivities.single.id, '101');
    });
  });

  group('HttpNotificationRepository', () {
    test('Consulta i marca els avisos com a llegits', () async {
      final notice = {
        ...backendNotification(9, event: 101),
        'notification-date': '2026-10-25T10:00:00Z',
      };
      final apiClient = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.headers.containsKey('X-User-ID'), isFalse);
          if (request.method == 'GET' && request.url.path == '/users/me') {
            return jsonResponse(backendOwnProfile(firebaseId: 'uid-1'));
          }
          if (request.url.path == '/notifications/user/$backendUserId') {
            return jsonResponse([notice]);
          }
          if (request.url.path == '/notificationtypes') {
            return jsonResponse(backendNotificationTypes);
          }
          if (request.url.path == '/notifications/9') {
            return jsonResponse(notice);
          }
          if (request.url.path == '/events/101') {
            return jsonResponse(sampleEventJson(id: 101));
          }
          if (request.url.path == '/notifications/9/read') {
            return jsonResponse({'message': 'notification 9 read'});
          }
          return jsonResponse({'error': 'not found'}, 404);
        }),
      );
      addTearDown(apiClient.close);
      final activityRepo = HttpActivityRepository(apiClient: apiClient);
      final notifRepo = HttpNotificationRepository(
        apiClient: apiClient,
        activityRepository: activityRepo,
      );
      final notifs = await notifRepo.getNotifications('uid-1');
      expect(notifs, hasLength(1));
      expect(notifs.single.id, '9');
      expect(notifs.single.activity?.id, '101');
      await notifRepo.markAsRead(userId: 'uid-1', notificationId: '9');
    });
  });
}
