import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/models/public_profile.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:aprop/features/profile/repositories/public_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements PublicProfileRepository {
  Object? profileError;
  Object? plansError;
  bool plansVisible = true;
  bool? isFriend;
  int planCalls = 0;
  Future<FriendRequestResult> Function()? onSend;
  int sendCalls = 0;

  final _activity = Activity(
    id: 'a1',
    title: 'Concert',
    category: 'Música',
    municipality: 'Girona',
    startsAt: DateTime(2026, 10, 1),
    imageAsset: 'assets/images/jazz_al_parc.jpg',
    source: ActivitySource.community,
  );

  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    if (profileError case final error?) throw error;
    return PublicProfile(
      profile: UserProfile(
        userId: userId,
        displayName: 'Marc Vidal',
        username: 'marcvidal',
        progress: const ProfileProgress(level: null, experience: 0),
      ),
      plansVisible: plansVisible,
      isFriend: isFriend ?? plansVisible,
    );
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) async => [
    _activity,
  ];

  @override
  Future<FriendRequestResult> sendFriendRequest(String userId) async {
    sendCalls++;
    return onSend?.call() ?? FriendRequestResult.sent;
  }

  @override
  Future<List<Activity>> getPastPlans(String userId) async {
    planCalls++;
    if (plansError case final error?) throw error;
    return [_activity];
  }
}

void main() {
  late _FakeRepository repository;
  late PublicProfileViewModel viewModel;

  setUp(() {
    repository = _FakeRepository();
    viewModel = PublicProfileViewModel(userId: 'u2', repository: repository);
  });
  tearDown(() => viewModel.dispose());

  test('Loads the header and both lists when the plans are visible', () async {
    await viewModel.load();

    expect(viewModel.profile?.profile.username, 'marcvidal');
    expect(viewModel.createdActivities, hasLength(1));
    expect(viewModel.pastPlans, hasLength(1));
    expect(viewModel.errorMessage, isNull);
  });

  test('Private plans are never requested', () async {
    repository.plansVisible = false;

    await viewModel.load();
    await viewModel.loadPastPlans();

    expect(repository.planCalls, 0);
    expect(viewModel.pastPlans, isNull);
    expect(viewModel.createdActivities, hasLength(1));
  });

  test('A failed load shows an error and can be retried', () async {
    repository.profileError = Exception('offline');

    await viewModel.load();
    expect(viewModel.profile, isNull);
    expect(viewModel.errorMessage, isNotNull);

    repository.profileError = null;
    await viewModel.load();
    expect(viewModel.profile, isNotNull);
    expect(viewModel.errorMessage, isNull);
  });

  test('A missing person is not an error to retry', () async {
    repository.profileError = const PublicProfileNotFound();

    await viewModel.load();

    expect(viewModel.notFound, isTrue);
    expect(viewModel.errorMessage, isNull);
  });

  test('A failed plans list keeps the header and the created list', () async {
    repository.plansError = Exception('offline');

    await viewModel.load();

    expect(viewModel.profile, isNotNull);
    expect(viewModel.createdActivities, hasLength(1));
    expect(viewModel.pastPlans, isNull);
    expect(viewModel.plansError, isNotNull);
  });

  group('Friend button (#160)', () {
    setUp(() {
      repository
        ..plansVisible = false
        ..isFriend = false;
    });

    test('Friends see «Amics» and cannot send a request', () async {
      repository.isFriend = true;
      await viewModel.load();

      expect(viewModel.friendship, FriendshipAction.friends);
      await viewModel.sendFriendRequest();
      expect(repository.sendCalls, 0);
    });

    test('Without a session the button is hidden', () async {
      // The server only reports friendship to a known requester.
      viewModel.dispose();
      viewModel = PublicProfileViewModel(
        userId: 'u2',
        repository: _UnknownFriendship(repository),
      );
      await viewModel.load();

      expect(viewModel.friendship, isNull);
    });

    test(
      'Sending waits for the server and then shows «Sol·licitud enviada»',
      () async {
        final reply = Completer<FriendRequestResult>();
        repository.onSend = () => reply.future;
        await viewModel.load();
        expect(viewModel.friendship, FriendshipAction.add);

        final sending = viewModel.sendFriendRequest();
        expect(viewModel.friendship, FriendshipAction.sending);
        // A second tap while sending does nothing.
        await viewModel.sendFriendRequest();
        expect(repository.sendCalls, 1);

        reply.complete(FriendRequestResult.sent);
        await sending;
        expect(viewModel.friendship, FriendshipAction.requestSent);

        // Reloading does not forget a request the profile cannot show.
        await viewModel.load();
        expect(viewModel.friendship, FriendshipAction.requestSent);
      },
    );

    test('Server refusals become the matching state', () async {
      for (final (result, expected) in [
        (FriendRequestResult.alreadyPending, FriendshipAction.requestSent),
        (FriendRequestResult.alreadyFriends, FriendshipAction.friends),
        (FriendRequestResult.blocked, FriendshipAction.unavailable),
      ]) {
        final model = PublicProfileViewModel(
          userId: 'u2',
          repository: repository..onSend = () async => result,
        );
        await model.load();
        await model.sendFriendRequest();
        expect(model.friendship, expected, reason: '$result');
        model.dispose();
      }
    });

    test(
      'A failure keeps «Afegeix com a amic» with an error to retry',
      () async {
        repository.onSend = () async => throw Exception('offline');
        await viewModel.load();

        await viewModel.sendFriendRequest();
        expect(viewModel.friendship, FriendshipAction.add);
        expect(viewModel.friendRequestError, isNotNull);

        repository.onSend = null;
        await viewModel.sendFriendRequest();
        expect(viewModel.friendship, FriendshipAction.requestSent);
        expect(viewModel.friendRequestError, isNull);
      },
    );
  });
}

/// The profile of a person when the server does not say if you are friends.
class _UnknownFriendship implements PublicProfileRepository {
  _UnknownFriendship(this.inner);
  final _FakeRepository inner;

  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    final person = await inner.getPublicProfile(userId);
    return PublicProfile(profile: person.profile, plansVisible: false);
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) =>
      inner.getCreatedActivities(userId);

  @override
  Future<List<Activity>> getPastPlans(String userId) =>
      inner.getPastPlans(userId);

  @override
  Future<FriendRequestResult> sendFriendRequest(String userId) =>
      inner.sendFriendRequest(userId);
}
