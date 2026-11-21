import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:aprop/features/profile/data/http_public_profile_repository.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../activities/backend_event_fixture.dart';
import 'backend_profile_fixture.dart';

void main() {
  test('Confirmed sharing and friendship permissions control refreshed public plans, not the owner setting', () async {
    var share = true; // The API value wins over client defaults.
    var friends = true;
    var eventReads = 0;
    final writes = <Object?>[];
    final client = ApiClient(
      idToken: () async => 'owner-fixture',
      client: MockClient((request) async {
        Object? response;
        if (request.url.path == '/users/me') {
          if (request.method == 'PATCH') {
            final change = jsonDecode(request.body) as Map<String, Object?>;
            writes.add(change);
            share = change['show-plans'] as bool;
          }
          response = {
            ...backendProfile(),
            'show-plans': share,
            'plans-visible': true,
          };
        } else {
          throw StateError('Unexpected owner endpoint: ${request.url.path}');
        }
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
    final viewerClient = ApiClient(
      idToken: () async => 'viewer-fixture',
      client: MockClient((request) async {
        Object? response;
        expect(request.headers['Authorization'], 'Bearer viewer-fixture');
        switch (request.url.path) {
          case '/users/$profileServerId':
            response = {
              ...backendProfile(),
              'show-plans': share,
              'is-friend': friends,
              'plans-visible': friends && share,
            };
          case '/users/$profileServerId/created-events':
            response = [];
          case '/users/$profileServerId/events':
            // An HTTP fixture: this assertion is not a claim of server-side authorization.
            expect(friends && share, isTrue);
            eventReads++;
            response = [backendEvent(1)];
          default:
            throw StateError('Unexpected viewer endpoint: ${request.url.path}');
        }
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
    addTearDown(client.close);
    addTearDown(viewerClient.close);
    final settings = ProfileSettingsViewModel(
      userId: 'user-a',
      repository: HttpProfileSettingsRepository(apiClient: client),
      onSignOut: () async {},
    );
    final viewer = PublicProfileViewModel(
      userId: profileServerId,
      currentUserId: otherProfileServerId,
      repository: HttpPublicProfileRepository(
        apiClient: viewerClient,
        now: () => DateTime(2030),
      ),
    );
    addTearDown(settings.dispose);
    addTearDown(viewer.dispose);
    await settings.load();
    expect(settings.settings!.showMyPlans, isTrue);
    await viewer.load();
    expect(viewer.pastPlans, hasLength(1));
    expect(eventReads, 1);

    await settings.updatePreference(ProfilePreference.showMyPlans, false);
    await viewer.load();
    expect(viewer.profile!.plansVisible, isFalse);
    expect(viewer.pastPlans, isNull);
    expect(
      eventReads,
      1,
    ); // A previously loaded list is cleared and not fetched.
    expect(
      (await HttpProfileSettingsRepository(apiClient: client)
              .getSettings('user-a'))
          .showMyPlans,
      isFalse,
    );

    await settings.updatePreference(ProfilePreference.showMyPlans, true);
    friends = false;
    await viewer.load();
    expect(viewer.pastPlans, isNull);
    expect(
      eventReads,
      1,
    ); // Sharing alone does not grant permission to a stranger.

    friends = true;
    await viewer.load();
    expect(viewer.pastPlans, hasLength(1));
    expect(eventReads, 2);
    expect(writes, [
      {'show-plans': false},
      {'show-plans': true},
    ]);
  });
}
