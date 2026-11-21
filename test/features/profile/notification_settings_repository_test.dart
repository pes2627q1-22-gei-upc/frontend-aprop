import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_profile_fixture.dart';

const _catalogue = [
  {'id': 17, 'name': 'Social'},
  {'id': 29, 'name': 'Recordatori'},
  {'id': 53, 'name': 'Recomanacio'},
  {'id': 103, 'name': 'Cancelacio'},
  {'id': 919, 'name': 'FutureType'},
];

http.Response _json(Object? value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _settings(Object? allowed) => {
  'id': 42,
  'show-plans': false,
  'language': 'ca',
  'notification-before': '3 days',
  'allowed-notif-types': allowed,
};

ApiClient _client(
  Future<http.Response> Function(http.Request) handler, {
  Future<String?> Function()? token,
}) => ApiClient(
  idToken: token ?? () async => 'test-token',
  client: MockClient(handler),
);

void main() {
  test('Loads generated IDs and real booleans, including all-disabled and immutable snapshots', () async {
    var allowed = [17, 29, 103];
    final client = _client(
      (request) async => switch (request.url.path) {
        '/users/me' => _json(backendProfile()),
        '/users/me/settings' => _json(_settings(allowed)),
        '/notificationtypes' => _json(_catalogue),
        _ => throw StateError('Unexpected request'),
      },
    );
    addTearDown(client.close);
    final repo = HttpProfileSettingsRepository(apiClient: client);
    final result = await repo.getNotificationPreferences('user-a');
    expect(result.values, {
      ProfilePreference.social: true,
      ProfilePreference.reminders: true,
      ProfilePreference.recommendations: false,
      ProfilePreference.cancellations: true,
    });
    expect(() => result.values.clear(), throwsUnsupportedError);
    allowed = [];
    expect(
      (await repo.getNotificationPreferences('user-a')).values.values,
      everyElement(isFalse),
    );
  });

  test(
    'A change preserves other types, future IDs and unrelated account settings',
    () async {
      var allowed = [17, 29, 103, 919];
      final writes = <Object?>[];
      final client = _client((request) async {
        if (request.url.path == '/users/me') {
          if (request.method == 'PATCH') {
            final change = jsonDecode(request.body) as Map<String, Object?>;
            writes.add(change);
            allowed = (change['allowed-notif-types'] as List).cast<int>();
          }
          return _json(backendProfile());
        }
        if (request.url.path == '/notificationtypes') return _json(_catalogue);
        return _json(_settings(allowed));
      });
      addTearDown(client.close);
      final repo = HttpProfileSettingsRepository(apiClient: client);
      final result = await repo.updateNotificationPreference(
        userId: 'user-a',
        preference: ProfilePreference.recommendations,
        enabled: true,
      );
      expect(result.valueOf(ProfilePreference.recommendations), isTrue);
      expect(result.valueOf(ProfilePreference.social), isTrue);
      expect(writes, [
        {
          'allowed-notif-types': [17, 29, 53, 103, 919],
        },
      ]);
      expect(
        (await HttpProfileSettingsRepository(apiClient: client)
                .getNotificationPreferences('user-a'))
            .values,
        result.values,
      );
      expect((await repo.getSettings('user-a')).showMyPlans, isFalse);
    },
  );

  test(
    'Every real type can be disabled, sending an empty set for the last one',
    () async {
      var allowed = [17, 29, 53, 103];
      final writes = <Object?>[];
      final client = _client((request) async {
        if (request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          allowed = (body['allowed-notif-types'] as List).cast<int>();
          writes.add(body);
        }
        return _json(switch (request.url.path) {
          '/users/me' => backendProfile(),
          '/notificationtypes' => _catalogue,
          _ => _settings(allowed),
        });
      });
      addTearDown(client.close);
      final repo = HttpProfileSettingsRepository(apiClient: client);
      for (final preference in [
        ProfilePreference.social,
        ProfilePreference.reminders,
        ProfilePreference.recommendations,
        ProfilePreference.cancellations,
      ]) {
        final result = await repo.updateNotificationPreference(
          userId: 'user-a',
          preference: preference,
          enabled: false,
        );
        expect(result.valueOf(preference), isFalse);
      }
      expect(writes.last, {'allowed-notif-types': []});
      expect(
        (await repo.getNotificationPreferences('user-a')).values.values,
        everyElement(isFalse),
      );
    },
  );

  test('Updates re-read the set instead of overwriting changes since the previous load', () async {
    var allowed = [17, 29, 103];
    final client = _client((request) async {
      if (request.method == 'PATCH') {
        allowed = (jsonDecode(request.body)['allowed-notif-types'] as List)
            .cast<int>();
      }
      return _json(switch (request.url.path) {
        '/users/me' => backendProfile(),
        '/notificationtypes' => _catalogue,
        _ => _settings(allowed),
      });
    });
    addTearDown(client.close);
    final repo = HttpProfileSettingsRepository(apiClient: client);
    await repo.getNotificationPreferences('user-a');
    allowed.addAll([53, 919]); // Another confirmed server change.
    await repo.updateNotificationPreference(
      userId: 'user-a',
      preference: ProfilePreference.cancellations,
      enabled: false,
    );
    expect(allowed, [17, 29, 53, 919]);
  });

  test('Malformed allowed lists are errors, never default switches', () async {
    for (final allowed in [
      null,
      '17',
      [0],
      ['17'],
      [17, 17],
    ]) {
      final client = _client(
        (request) async => _json(switch (request.url.path) {
          '/users/me' => backendProfile(),
          '/notificationtypes' => _catalogue,
          _ => _settings(allowed),
        }),
      );
      addTearDown(client.close);
      await expectLater(
        HttpProfileSettingsRepository(apiClient: client)
            .getNotificationPreferences('user-a'),
        throwsFormatException,
      );
    }
  });

  test(
    'Invalid, duplicate and ambiguous catalogues are not guessed from IDs',
    () async {
      for (final catalogue in [
        null,
        [],
        [
          {'id': 17, 'name': ''},
        ],
        [
          {'id': 17, 'name': 'Social'},
          {'id': 17, 'name': 'Recordatori'},
        ],
        [
          {'id': 17, 'name': 'Social'},
          {'id': 18, 'name': 'social'},
        ],
      ]) {
        final client = _client(
          (request) async => _json(switch (request.url.path) {
            '/users/me' => backendProfile(),
            '/notificationtypes' => catalogue,
            _ => _settings([17]),
          }),
        );
        addTearDown(client.close);
        await expectLater(
          HttpProfileSettingsRepository(apiClient: client)
              .getNotificationPreferences('user-a'),
          throwsFormatException,
        );
      }
    },
  );

  test('A partial catalogue exposes only supported controls and cannot write a missing type', () async {
    var writes = 0;
    final client = _client((request) async {
      if (request.method == 'PATCH') writes++;
      return _json(switch (request.url.path) {
        '/users/me' => backendProfile(),
        '/notificationtypes' => [
          {'id': 29, 'name': 'Recordatori'},
        ],
        _ => _settings([29]),
      });
    });
    addTearDown(client.close);
    final repo = HttpProfileSettingsRepository(apiClient: client);
    expect((await repo.getNotificationPreferences('user-a')).values, {
      ProfilePreference.reminders: true,
    });
    await expectLater(
      repo.updateNotificationPreference(
        userId: 'user-a',
        preference: ProfilePreference.social,
        enabled: false,
      ),
      throwsUnsupportedError,
    );
    expect(writes, 0);
  });

  test(
    'All steps keep the captured bearer even when the token provider changes',
    () async {
      var tokenReads = 0;
      var allowed = [17];
      final client = _client((request) async {
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers.containsKey('X-User-ID'), isFalse);
        if (request.method == 'PATCH') allowed = [];
        return _json(switch (request.url.path) {
          '/users/me' => backendProfile(),
          '/notificationtypes' => _catalogue,
          _ => _settings(allowed),
        });
      }, token: () async => 'token-${++tokenReads}');
      addTearDown(client.close);
      await HttpProfileSettingsRepository(apiClient: client)
          .updateNotificationPreference(
            userId: 'user-a',
            preference: ProfilePreference.social,
            enabled: false,
          );
    },
  );

  test('An account mismatch stops before settings or write requests', () async {
    final requests = <String>[];
    final client = _client((request) async {
      requests.add('${request.method} ${request.url.path}');
      return _json(backendProfile(account: 'different-account'));
    });
    addTearDown(client.close);
    await expectLater(
      HttpProfileSettingsRepository(apiClient: client)
          .updateNotificationPreference(
            userId: 'user-a',
            preference: ProfilePreference.social,
            enabled: false,
          ),
      throwsA(isA<ApiException>()),
    );
    expect(requests, ['GET /users/me']);
  });

  test('A successful PATCH that did not persist is rejected by read-back (backend DP-079)', () async {
    final client = _client(
      (request) async => _json(switch (request.url.path) {
        '/users/me' => backendProfile(),
        '/notificationtypes' => _catalogue,
        _ => _settings([
          17,
        ]), // Models the early return when Language is present.
      }),
    );
    addTearDown(client.close);
    await expectLater(
      HttpProfileSettingsRepository(apiClient: client)
          .updateNotificationPreference(
            userId: 'user-a',
            preference: ProfilePreference.social,
            enabled: false,
          ),
      throwsFormatException,
    );
  });

  test(
    'Confirmation must preserve future IDs and the same settings record',
    () async {
      for (final changeOwner in [false, true]) {
        var written = false;
        final client = _client((request) async {
          if (request.method == 'PATCH') written = true;
          return _json(switch (request.url.path) {
            '/users/me' => backendProfile(),
            '/notificationtypes' => _catalogue,
            _ => {
              ..._settings(written ? (changeOwner ? [919] : []) : [17, 919]),
              if (written && changeOwner) 'id': 43,
            },
          });
        });
        addTearDown(client.close);
        await expectLater(
          HttpProfileSettingsRepository(apiClient: client)
              .updateNotificationPreference(
                userId: 'user-a',
                preference: ProfilePreference.social,
                enabled: false,
              ),
          throwsFormatException,
        );
      }
    },
  );

  test('A failed confirmation stays a failure even if the server applied the write', () async {
    var written = false;
    final client = _client((request) async {
      if (request.method == 'PATCH') written = true;
      if (request.url.path == '/users/me/settings' && written) {
        return _json({'error': 'offline'}, 503);
      }
      return _json(switch (request.url.path) {
        '/users/me' => backendProfile(),
        '/notificationtypes' => _catalogue,
        _ => _settings([17]),
      });
    });
    addTearDown(client.close);
    await expectLater(
      HttpProfileSettingsRepository(apiClient: client)
          .updateNotificationPreference(
            userId: 'user-a',
            preference: ProfilePreference.social,
            enabled: false,
          ),
      throwsA(isA<ApiException>()),
    );
    expect(written, isTrue);
  });
}
