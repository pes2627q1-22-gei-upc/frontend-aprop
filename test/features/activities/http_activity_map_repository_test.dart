import 'dart:convert';

import 'package:aprop/features/activities/data/http_activity_map_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const area = GeoBounds(
    southWest: GeoPoint(latitude: 41.35, longitude: 2.1),
    northEast: GeoPoint(latitude: 41.45, longitude: 2.23),
  );

  late List<http.Request> requests;

  /// Esdeveniment com el que retorna `GET /events/map`.
  Map<String, Object?> event([Map<String, Object?> changes = const {}]) => {
    'id': 1282,
    'code': 20230102001,
    'title': 'Música a la plaça',
    'description': ' Concerts gratuïts cada dissabte. ',
    'free': true,
    'place': 'Sala Salamandra',
    'address': 'Av. del Carrilet, 235',
    'latitude': 41.36015,
    'longitude': 2.1093738,
    'municipality':
        'agenda:ubicacions/barcelona/barcelones/l-hospitalet-de-llobregat',
    'start-date': '2026-11-07T00:00:00Z',
    'is-official': true,
    'has-friends': false,
    ...changes,
  };

  HttpActivityMapRepository repository(
    http.Response Function(http.Request request) respond,
  ) {
    requests = [];
    return HttpActivityMapRepository(
      baseUrl: Uri.parse('http://10.0.2.2:8080/'),
      client: MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  // Com el backend: JSON en UTF-8 sense indicar el joc de caràcters.
  http.Response json(Object? body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  test('Demana la zona visible i en llegeix les activitats', () async {
    final activities = await repository((_) => json([event()]))
        .getActivitiesInArea(area);

    final url = requests.single.url;
    expect(url.path, '/events/map');
    expect(url.queryParameters, {
      'minLat': '41.35',
      'maxLat': '41.45',
      'minLng': '2.1',
      'maxLng': '2.23',
    });

    final activity = activities.single;
    expect(activity.id, '1282');
    expect(activity.title, 'Música a la plaça');
    expect(activity.municipality, 'L’Hospitalet de Llobregat');
    expect(activity.source, ActivitySource.culturalAgenda);
    expect(activity.creator, isNull);
    expect(
      activity.location,
      const GeoPoint(latitude: 41.36015, longitude: 2.1093738),
    );
    expect(activity.startsAt, DateTime(2026, 11, 7));
    expect(activity.description, 'Concerts gratuïts cada dissabte.');
    expect(activity.directions, 'Sala Salamandra · Av. del Carrilet, 235');
    expect(activity.price, 0);
    // El mapa no rep categories.
    expect(activity.category, 'Activitat');
  });

  test('Converteix l’etiqueta del municipi en el seu nom', () async {
    Future<String> municipality(String? tag) async {
      final activities = await repository(
        (_) => json([
          event({'municipality': tag}),
        ]),
      ).getActivitiesInArea(area);
      return activities.single.municipality;
    }

    expect(
      await municipality(
        'agenda:ubicacions/barcelona/baix-llobregat/sant-andreu-de-la-barca',
      ),
      'Sant Andreu de la Barca',
    );
    expect(
      await municipality('agenda:ubicacions/lleida/alt-urgell/la-seu-d-urgell'),
      'La Seu d’Urgell',
    );
    // Sense municipi, es mostra el lloc.
    expect(await municipality(''), 'Sala Salamandra');
  });

  test('Una activitat d’usuari sense coordenades ni preu', () async {
    final activities = await repository(
      (_) => json([
        event({
          'is-official': false,
          'latitude': 0,
          'longitude': 0,
          'free': false,
        }),
      ]),
    ).getActivitiesInArea(area);

    final activity = activities.single;
    expect(activity.source, ActivitySource.community);
    expect(activity.creator?.name, 'un usuari');
    expect(activity.location, isNull);
    expect(activity.price, isNull);
  });

  test('Si el backend no respon bé, llança un error', () {
    expect(
      repository((_) => json({'error': 'boom'}, 500)).getActivitiesInArea(area),
      throwsA(isA<StateError>()),
    );
  });

  group('Fitxa', () {
    test('Llegeix l’activitat amb la seva categoria', () async {
      final activity = await repository(
        (_) => json(
          event({
            'is-official': null,
            'categories': ['agenda:categories/arts-visuals'],
          }),
        ),
      ).getActivityById('1282');

      expect(requests.single.url.path, '/events/1282');
      expect(activity?.category, 'Arts visuals');
      // Sense `is-official`, és oficial perquè té codi de l'Agenda Cultural.
      expect(activity?.source, ActivitySource.culturalAgenda);
    });

    test('Retorna null si no existeix', () async {
      final repo = repository((_) => json({'error': 'not found'}, 404));

      expect(await repo.getActivityById('999'), isNull);
      // Un ID que no és del backend ni es demana.
      expect(await repo.getActivityById('demo-jazz'), isNull);
      expect(requests, hasLength(1));
    });
  });

  group('Token de la sessió', () {
    late List<http.Request> sent;

    HttpActivityMapRepository withToken(String? token) {
      sent = [];
      return HttpActivityMapRepository(
        baseUrl: Uri.parse('http://10.0.2.2:8080'),
        idToken: () async => token,
        client: MockClient((request) async {
          sent.add(request);
          // El mapa rep una llista; la fitxa, un sol esdeveniment.
          final body = request.url.path.endsWith('/map') ? [event()] : event();
          return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
        }),
      );
    }

    test("L'envia a cada petició quan n'hi ha", () async {
      final repository = withToken('firebase-token');

      await repository.getActivitiesInArea(area);
      await repository.getActivityById('1282');

      expect(
        sent.map((request) => request.headers['Authorization']),
        everyElement('Bearer firebase-token'),
      );
    });

    test('Sense sessió (demostració) no envia cap capçalera', () async {
      await withToken(null).getActivitiesInArea(area);

      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });
  });
}
