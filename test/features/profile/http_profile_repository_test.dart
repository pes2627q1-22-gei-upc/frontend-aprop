import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_profile_repository.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:aprop/features/profile/models/profile_avatar.dart';
import 'package:aprop/features/profile/models/profile_failure.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../activities/backend_event_fixture.dart';
import 'backend_profile_fixture.dart';
import 'profile_test_data.dart';

http.Response profileJson(Object? body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  ApiClient api(
    Future<http.Response> Function(http.Request) handle, {
    Future<String?> Function()? token,
  }) => ApiClient(
    idToken: token ?? () async => 'profile-token',
    client: MockClient(handle),
  );

  test('Loads the authoritative profile without invented municipality, history or XP rules', () async {
    final requests = <String>[];
    final repo = HttpProfileRepository(
      apiClient: api((request) async {
        requests.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer profile-token');
        expect(request.headers.containsKey('X-User-ID'), isFalse);
        return profileJson(backendProfile());
      }),
    );
    final profile = await repo.getProfile(profileUser);
    expect(requests, ['/users/me']);
    expect(profile.displayName, 'Maria Soler');
    expect(profile.username, 'maria');
    expect(profile.avatarUrl, 'https://images.example.test/avatar.png');
    expect(profile.displayedPlanCount, 9);
    expect(profile.completedPlans, isEmpty);
    expect(profile.municipality, isEmpty);
    expect(profile.progress.experience, 340);
    expect(profile.progress.level, isNull);
    expect(profile.progress.serverLevel, 2);
    expect(profile.progress.nextLevelTarget, isNull);
    expect(repo.capabilities.editMunicipality, isFalse);
    expect(repo.capabilities.completedPlans, isFalse);
  });

  test('Created activities use the authenticated endpoint and preserve remote covers', () async {
    final repo = HttpProfileRepository(
      apiClient: api((request) async {
        if (request.url.path == '/users/me') {
          return profileJson(backendProfile());
        }
        expect(request.url.path, '/users/me/created-events');
        return profileJson([
          {
            ...backendEvent(7),
            'is-official': false,
            'creator': profileServerId,
            'images': 'https://images.example.test/event.jpg',
          },
        ]);
      }),
    );
    final created = await repo.getCreatedActivities(profileUser);
    expect(created.single.id, '7');
    expect(created.single.imageUrl, 'https://images.example.test/event.jpg');
    expect(() => created.clear(), throwsUnsupportedError);
  });

  test('Created list failures, malformed rows and foreign creators do not become empty lists', () async {
    for (final response in [
      profileJson({'error': 'offline'}, 503),
      profileJson(null),
      profileJson([null]),
      profileJson([
        {
          ...backendEvent(7),
          'is-official': false,
          'creator': otherProfileServerId,
        },
      ]),
    ]) {
      final repo = HttpProfileRepository(
        apiClient: api(
          (request) async => request.url.path == '/users/me'
              ? profileJson(backendProfile())
              : response,
        ),
      );
      await expectLater(
        repo.getCreatedActivities(profileUser),
        throwsA(anyOf(isA<ApiException>(), isA<FormatException>())),
      );
    }
  });

  test('updateLanguage sends PATCH users/me with the language code', () async {
    final writes = <Map<String, Object?>>[];
    final repo = HttpProfileSettingsRepository(
      apiClient: api((request) async {
        if (request.method == 'GET') return profileJson(backendProfile());
        expect(request.method, 'PATCH');
        expect(request.url.path, '/users/me');
        writes.add(jsonDecode(request.body) as Map<String, Object?>);
        return profileJson(backendProfile());
      }),
    );
    await repo.updateLanguage(userId: profileUser.id, language: 'es');
    expect(writes.single, {'language': 'es'});
  });

  test('getSettings reads the account language when valid and ignores invalid/missing values', () async {
    Future<String?> readLang(Map<String, Object?> extra) async {
      final repo = HttpProfileSettingsRepository(
        apiClient: api(
          (_) async => profileJson({...backendProfile(), ...extra}),
        ),
      );
      return (await repo.getSettings(profileUser.id)).language;
    }

    expect(await readLang({'language': 'en'}), 'en');
    expect(await readLang({'language': ' ES '}), 'es');
    expect(await readLang({'language': 'fr'}), isNull);
    expect(await readLang({}), isNull);
  });

  test('Created activities are requested with the current language', () async {
    String? lang;
    final repo = HttpProfileRepository(
      apiClient: ApiClient(
        idToken: () async => 'profile-token',
        language: () => 'en',
        client: MockClient((request) async {
          if (request.url.path == '/users/me/created-events') {
            lang = request.url.queryParameters['lang'];
            return profileJson([]);
          }
          return profileJson(backendProfile());
        }),
      ),
    );
    await repo.getCreatedActivities(profileUser);
    expect(lang, 'en');
  });

  test(
    'Updates supported fields and returns the server-confirmed identity',
    () async {
      final writes = <Map<String, Object?>>[];
      final repo = HttpProfileRepository(
        apiClient: api((request) async {
          if (request.method == 'GET') return profileJson(backendProfile());
          expect(request.method, 'PATCH');
          expect(request.url.path, '/users/me');
          final body = jsonDecode(request.body) as Map<String, Object?>;
          writes.add(body);
          return profileJson({...backendProfile(), ...body});
        }),
      );
      final updated = await repo.updateDetails(
        user: profileUser,
        biography: '  Cinema  ',
        municipality: '',
        name: ' Maria Casals ',
        username: ' maria_c ',
      );
      expect(writes.single, {
        'biography': 'Cinema',
        'name': 'Maria Casals',
        'username': 'maria_c',
      });
      expect(updated.displayName, 'Maria Casals');
      expect(updated.username, 'maria_c');
      await expectLater(
        repo.updateDetails(
          user: profileUser,
          biography: 'Bio',
          municipality: 'Vic',
        ),
        throwsUnsupportedError,
      );
      expect(writes, hasLength(1));
    },
  );

  test('A duplicate username is exposed as a domain failure', () async {
    final repo = HttpProfileRepository(
      apiClient: api(
        (request) async => request.method == 'GET'
            ? profileJson(backendProfile())
            : profileJson({'error': 'username taken'}, 409),
      ),
    );
    await expectLater(
      repo.updateDetails(
        user: profileUser,
        biography: 'Bio',
        municipality: '',
        username: 'taken',
      ),
      throwsA(ProfileFailure.usernameInUse),
    );
  });

  test('Avatar is multipart and confirms the returned URL without a secondary list request', () async {
    var posts = 0;
    final repo = HttpProfileRepository(
      apiClient: api((request) async {
        if (request.method == 'GET') return profileJson(backendProfile());
        posts++;
        expect(request.url.path, '/users/me/avatar');
        expect(
          request.headers['Content-Type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(request.body, contains('name="avatar"; filename="photo.png"'));
        expect(request.headers['Authorization'], 'Bearer profile-token');
        return profileJson({
          ...backendProfile(),
          'profile-picture': 'https://images.example.test/new.png',
        });
      }),
    );
    final profile = await repo.uploadAvatar(
      user: profileUser,
      avatar: ProfileAvatar(bytes: [1, 2, 3], filename: 'photo.png'),
    );
    expect(profile.avatarUrl, 'https://images.example.test/new.png');
    expect(posts, 1);
  });

  test('No session, malformed profiles and a different account are errors, not fallback data', () async {
    var calls = 0;
    final missingToken = HttpProfileRepository(
      apiClient: api((_) async {
        calls++;
        return profileJson({});
      }, token: () async => null),
    );
    await expectLater(
      missingToken.getProfile(profileUser),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 0);
    for (final payload in [
      null,
      {...backendProfile(), 'id': 7},
      {...backendProfile(), 'plans-count': null},
      {...backendProfile(), 'firebase-uid': 'another-account'},
      {...backendProfile(), 'experience': -1},
    ]) {
      final repo = HttpProfileRepository(
        apiClient: api((_) async => profileJson(payload)),
      );
      await expectLater(
        repo.getProfile(profileUser),
        throwsA(anyOf(isA<ApiException>(), isA<FormatException>())),
      );
    }
  });

  test('An operation retains its token and refuses a different account before writing', () async {
    var token = 'first-token';
    var writes = 0;
    final repo = HttpProfileRepository(
      apiClient: api((request) async {
        if (request.method == 'GET') {
          token = 'second-token';
          return profileJson(backendProfile());
        }
        writes++;
        expect(request.headers['Authorization'], 'Bearer first-token');
        return profileJson(backendProfile());
      }, token: () async => token),
    );
    await repo.updateDetails(
      user: profileUser,
      biography: 'Bio',
      municipality: '',
    );
    expect(writes, 1);
    final other = HttpProfileRepository(
      apiClient: api((request) async {
        if (request.method != 'GET') writes++;
        return profileJson(backendProfile(account: 'someone-else'));
      }),
    );
    await expectLater(
      other.updateDetails(
        user: profileUser,
        biography: 'Bio',
        municipality: '',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(writes, 1);
  });

  test('Avatar checks the complete multipart limit and rejects unusable upload responses', () async {
    var posts = 0;
    final repo = HttpProfileRepository(
      apiClient: api((request) async {
        if (request.method == 'POST') {
          posts++;
          return profileJson({...backendProfile(), 'profile-picture': ''});
        }
        return profileJson(backendProfile());
      }),
    );
    await expectLater(
      repo.uploadAvatar(
        user: profileUser,
        avatar: ProfileAvatar(
          bytes: List.filled(ProfileAvatar.maxBytes - 100, 0),
          filename: 'image.png',
        ),
      ),
      throwsA(isA<AvatarSelectionException>()),
    );
    expect(posts, 0);
    await expectLater(
      repo.uploadAvatar(
        user: profileUser,
        avatar: ProfileAvatar(bytes: [1], filename: 'image.png'),
      ),
      throwsFormatException,
    );
    expect(posts, 1);
    expect(
      () => ProfileAvatar(bytes: [1], filename: 'image.heic'),
      throwsA(isA<AvatarSelectionException>()),
    );
  });

  test('Privacy persists only the supported setting and never falls back to local defaults', () async {
    var show = false;
    var writes = 0;
    final settings = HttpProfileSettingsRepository(
      apiClient: api((request) async {
        if (request.method == 'PATCH') {
          writes++;
          expect(jsonDecode(request.body), {'show-plans': true});
          show = true;
        }
        return profileJson({
          ...backendProfile(),
          'show-plans': show,
          'plans-visible': true,
        });
      }),
    );
    expect((await settings.getSettings(profileUser.id)).showMyPlans, isFalse);
    expect(
      (await settings.updatePreference(
        userId: profileUser.id,
        preference: ProfilePreference.showMyPlans,
        enabled: true,
      )).showMyPlans,
      isTrue,
    );
    expect((await settings.getSettings(profileUser.id)).showMyPlans, isTrue);
    await expectLater(
      settings.updatePreference(
        userId: profileUser.id,
        preference: ProfilePreference.reminders,
        enabled: false,
      ),
      throwsUnsupportedError,
    );
    expect(writes, 1);
    final offline = HttpProfileSettingsRepository(
      apiClient: api((_) async => profileJson({'error': 'offline'}, 503)),
    );
    await expectLater(
      offline.getSettings(profileUser.id),
      throwsA(isA<ApiException>()),
    );
  });
}
