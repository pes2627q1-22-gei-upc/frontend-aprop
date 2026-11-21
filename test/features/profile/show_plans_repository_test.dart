import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_profile_fixture.dart';

http.Response _json(Object? value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'Reads show-plans independently of permission to view your own plans',
    () async {
      final client = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/users/me');
          return _json({
            ...backendProfile(),
            'show-plans': false,
            'plans-visible': true,
          });
        }),
      );
      addTearDown(client.close);
      final settings = await HttpProfileSettingsRepository(apiClient: client)
          .getSettings('user-a');
      expect(settings.showMyPlans, isFalse);
    },
  );

  test('Both directions persist after recreating the repository, with a partial PATCH', () async {
    var visible = true;
    final writes = <Object?>[];
    var tokenReads = 0;
    String? readBearer;
    final client = ApiClient(
      idToken: () async => 'test-${++tokenReads}',
      client: MockClient((request) async {
        expect(request.url.path, '/users/me');
        expect(request.headers.containsKey('X-User-ID'), isFalse);
        if (request.method == 'PATCH') {
          final change = jsonDecode(request.body) as Map<String, Object?>;
          writes.add(change);
          visible = change['show-plans'] as bool;
          // The GET and PATCH of a write keep the same captured bearer.
          expect(request.headers['Authorization'], readBearer);
        } else {
          readBearer = request.headers['Authorization'];
        }
        return _json({...backendProfile(), 'show-plans': visible});
      }),
    );
    addTearDown(client.close);
    for (final target in [false, true]) {
      final repo = HttpProfileSettingsRepository(apiClient: client);
      final result = await repo.updatePreference(
        userId: 'user-a',
        preference: ProfilePreference.showMyPlans,
        enabled: target,
      );
      expect(result.showMyPlans, target);
      expect(
        (await HttpProfileSettingsRepository(apiClient: client)
                .getSettings('user-a'))
            .showMyPlans,
        target,
      );
    }
    expect(writes, [
      {'show-plans': false},
      {'show-plans': true},
    ]);
  });

  test(
    'A PATCH which ignores disabling privacy is not reported as saved',
    () async {
      final client = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient(
          (_) async => _json({...backendProfile(), 'show-plans': true}),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        HttpProfileSettingsRepository(apiClient: client).updatePreference(
          userId: 'user-a',
          preference: ProfilePreference.showMyPlans,
          enabled: false,
        ),
        throwsFormatException,
      );
    },
  );

  test('The PATCH must confirm the same real UUID, even if it repeats the Firebase UID', () async {
    final client = ApiClient(
      idToken: () async => 'test-token',
      client: MockClient(
        (request) async => _json({
          ...backendProfile(),
          if (request.method == 'PATCH') 'id': otherProfileServerId,
          'show-plans': false,
        }),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      HttpProfileSettingsRepository(apiClient: client).updatePreference(
        userId: 'user-a',
        preference: ProfilePreference.showMyPlans,
        enabled: false,
      ),
      throwsFormatException,
    );
  });

  test(
    'No request is sent without a token or after an account mismatch',
    () async {
      var requests = 0;
      var token = '';
      final client = ApiClient(
        idToken: () async => token,
        client: MockClient((request) async {
          requests++;
          expect(request.method, 'GET');
          return _json(backendProfile(account: 'other-account'));
        }),
      );
      addTearDown(client.close);
      final repo = HttpProfileSettingsRepository(apiClient: client);
      await expectLater(
        repo.updatePreference(
          userId: 'user-a',
          preference: ProfilePreference.showMyPlans,
          enabled: false,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(requests, 0);
      token = 'test-token';
      await expectLater(
        repo.updatePreference(
          userId: 'user-a',
          preference: ProfilePreference.showMyPlans,
          enabled: false,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(requests, 1);
    },
  );

  test('Missing or invalid show-plans never becomes a default false', () async {
    for (final value in [null, 'false', 0]) {
      final client = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient(
          (_) async => _json({...backendProfile(), 'show-plans': value}),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        HttpProfileSettingsRepository(apiClient: client).getSettings('user-a'),
        throwsFormatException,
      );
    }
  });

  test(
    'HTTP write errors remain errors and a later retry can succeed',
    () async {
      var fail = true;
      final client = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          if (request.method == 'PATCH' && fail) {
            return _json({'error': 'unavailable'}, 503);
          }
          return _json(backendProfile());
        }),
      );
      addTearDown(client.close);
      final repo = HttpProfileSettingsRepository(apiClient: client);
      Future<ProfileSettings> disable() => repo.updatePreference(
        userId: 'user-a',
        preference: ProfilePreference.showMyPlans,
        enabled: false,
      );
      await expectLater(disable(), throwsA(isA<ApiException>()));
      fail = false;
      expect((await disable()).showMyPlans, isFalse);
    },
  );
}
