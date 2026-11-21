import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_settings_repository.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/features/profile/presentation/view_models/blocked_users_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';
import 'remove_friend_test_support.dart';

const juliaTarget = UserSummary(
  id: 'demo-person-julia',
  username: 'juliariera',
  displayName: 'Júlia Riera',
);

void main() {
  test('Reopening a known blocked profile preserves its state and unblock action if refresh fails', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    await repo.blockUser(userId: 'viewer', target: removalPeer);
    repo.onFetchBlocked = () async => throw StateError('offline');
    final profile = PublicProfileViewModel(
      userId: 'peer',
      currentUserId: 'viewer',
      repository: RemovalProfiles(),
      friendshipRepository: repo,
    );
    addTearDown(profile.dispose);
    await profile.load();
    expect(profile.isUserBlocked, isTrue);
    expect(profile.canManageBlocks, isTrue);
    expect(profile.friendship, FriendshipAction.unavailable);
    expect(profile.profile!.plansVisible, isFalse);
    expect(profile.blockError, isNotNull);
  });
  test(
    'A retained notice from a blocked person can still be read and opened',
    () async {
      final repo = ControlledFriendshipRepository(
        DemoFriendshipRepository.marcRequest('demo-laiasoler'),
      );
      addTearDown(repo.dispose);
      final inbox = NotificationsViewModel(
        userId: 'demo-laiasoler',
        repository: DemoNotificationRepository(
          activityRepository: DemoActivityRepository(),
          friendshipRepository: repo,
        ),
        friendshipRepository: repo,
      );
      addTearDown(inbox.dispose);
      await inbox.load();
      await repo.blockUser(
        userId: 'demo-laiasoler',
        target: const UserSummary(
          id: 'demo-person-marc',
          username: 'marcvidal',
          displayName: 'Marc Vidal',
        ),
      );
      expect(await inbox.markAsRead('demo-request-notice'), isTrue);
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .isRead,
        isTrue,
      );
      expect(await inbox.markAsRead('demo-request-notice'), isTrue);
      expect(repo.writes, 0);
    },
  );
  test(
    'Blocking disables old inbox requests; unblocking leaves them resolved',
    () async {
      final repo = ControlledFriendshipRepository(
        DemoFriendshipRepository.marcRequest('demo-laiasoler'),
      );
      addTearDown(repo.dispose);
      final inbox = NotificationsViewModel(
        userId: 'demo-laiasoler',
        repository: DemoNotificationRepository(
          activityRepository: DemoActivityRepository(),
          friendshipRepository: repo,
        ),
        friendshipRepository: repo,
      );
      addTearDown(inbox.dispose);
      await inbox.load();
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.pending,
      );
      await repo.blockUser(
        userId: 'demo-laiasoler',
        target: const UserSummary(
          id: 'demo-person-marc',
          username: 'marcvidal',
          displayName: 'Marc Vidal',
        ),
      );
      expect(inbox.isPersonBlocked('demo-person-marc'), isTrue);
      await inbox.respond('demo-request-notice', accept: true);
      expect(repo.writes, 0);
      await repo.unblockUser(
        userId: 'demo-laiasoler',
        targetId: 'demo-person-marc',
      );
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.rejected,
      );
      await inbox.respond('demo-request-notice', accept: true);
      expect(repo.writes, 0);
    },
  );
  test('Blocked list distinguishes error from empty and retries', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    repo.onFetchBlocked = () async => throw StateError('offline');
    final vm = BlockedUsersViewModel(userId: 'viewer', repository: repo);
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.users, isNull);
    expect(vm.errorMessage, isNotNull);
    repo.onFetchBlocked = null;
    await vm.load();
    expect(vm.users, isEmpty);
    expect(vm.errorMessage, isNull);
  });

  test(
    'Unblock waits for confirmation, keeps row on error and permits retry',
    () async {
      final repo = ControlledFriendshipRepository(
        DemoFriendshipRepository.marcRequest('viewer'),
      );
      addTearDown(repo.dispose);
      await repo.blockUser(userId: 'viewer', target: juliaTarget);
      final vm = BlockedUsersViewModel(userId: 'viewer', repository: repo);
      addTearDown(vm.dispose);
      await vm.load();
      final pending = Completer<void>();
      repo.onUnblock = (_) => pending.future;
      final action = vm.unblock(juliaTarget.id);
      expect(vm.isUnblocking(juliaTarget.id), isTrue);
      expect(vm.users, hasLength(1));
      expect(await vm.unblock(juliaTarget.id), isFalse);
      pending.completeError(StateError('offline'));
      expect(await action, isFalse);
      expect(vm.users, hasLength(1));
      expect(vm.actionError(juliaTarget.id), isNotNull);
      repo.onUnblock = null;
      expect(await vm.unblock(juliaTarget.id), isTrue);
      expect(vm.users, isEmpty);
    },
  );

  test('Blocking updates profile, both real-source counters and settings; unblocking does not restore friendship', () async {
    const user = AppUser(
      id: 'demo-laiasoler',
      email: 'laia@example.test',
      firstName: 'Laia',
      lastName: 'Soler',
      username: 'laiasoler',
      emailVerified: true,
    );
    final repo = DemoFriendshipRepository();
    addTearDown(repo.dispose);
    final activities = DemoActivityRepository();
    final own = ProfileViewModel(
      user: user,
      repository: DemoProfileRepository(
        activityRepository: activities,
        friendshipRepository: repo,
      ),
      friendshipRepository: repo,
    );
    addTearDown(own.dispose);
    final peer = PublicProfileViewModel(
      userId: juliaTarget.id,
      currentUserId: user.id,
      friendshipRepository: repo,
      repository: DemoPublicProfileRepository(
        activityRepository: activities,
        friendshipRepository: repo,
        currentUserId: () => user.id,
      ),
    );
    addTearDown(peer.dispose);
    final settings = ProfileSettingsViewModel(
      userId: user.id,
      repository: DemoProfileSettingsRepository(),
      blockingRepository: repo,
      onSignOut: () async {},
    );
    addTearDown(settings.dispose);
    await Future.wait([own.load(), peer.load(), settings.load()]);
    await drainRemovalChanges();
    expect(own.profile!.friendCount, 14);
    expect(settings.blockedUserCount, 0);
    expect(await peer.setBlocked(true), isTrue);
    await drainRemovalChanges();
    expect(peer.isUserBlocked, isTrue);
    expect(peer.friendship, FriendshipAction.unavailable);
    expect(peer.pastPlans, isNull);
    expect(own.profile!.friendCount, 13);
    expect(peer.profile!.profile.friendCount, 7);
    expect(settings.blockedUserCount, 1);
    expect(await peer.setBlocked(false), isTrue);
    await drainRemovalChanges();
    expect(peer.isUserBlocked, isFalse);
    expect(peer.friendship, FriendshipAction.add);
    expect(settings.blockedUserCount, 0);
    expect(own.profile!.friendCount, 13);
  });

  test(
    'Block failure leaves profile friendship unchanged and can be retried',
    () async {
      final repo = ControlledFriendshipRepository(
        DemoFriendshipRepository.marcRequest('viewer'),
      );
      addTearDown(repo.dispose);
      repo.onFetch = () async => [];
      final profiles = RemovalProfiles();
      final vm = PublicProfileViewModel(
        userId: 'peer',
        currentUserId: 'viewer',
        friendshipRepository: repo,
        repository: profiles,
      );
      addTearDown(vm.dispose);
      await vm.load();
      repo.onBlock = (_) async => throw StateError('offline');
      expect(await vm.setBlocked(true), isFalse);
      expect(vm.friendship, FriendshipAction.friends);
      expect(vm.isUserBlocked, isFalse);
      expect(vm.blockError, isNotNull);
      repo.onBlock = null;
      expect(await vm.setBlocked(true), isTrue);
      await drainRemovalChanges();
      expect(vm.isUserBlocked, isTrue);
      expect(vm.profile!.plansVisible, isFalse);
    },
  );

  test('A blocked-list failure does not hide the profile or pretend it is unblocked', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    repo.onFetchBlocked = () async => throw StateError('offline');
    final vm = PublicProfileViewModel(
      userId: 'peer',
      currentUserId: 'viewer',
      friendshipRepository: repo,
      repository: RemovalProfiles(),
    );
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.profile, isNotNull);
    expect(vm.canManageBlocks, isFalse);
    expect(vm.blockError, isNotNull);
    repo.onFetchBlocked = null;
    await vm.load();
    expect(vm.canManageBlocks, isTrue);
    expect(vm.blockError, isNull);
  });

  test('Blocking rejects the existing incoming request and unblocking never revives it', () async {
    final repo = DemoFriendshipRepository();
    addTearDown(repo.dispose);
    final activities = DemoActivityRepository();
    final vm = PublicProfileViewModel(
      userId: 'demo-person-marc',
      currentUserId: 'viewer',
      friendshipRepository: repo,
      repository: DemoPublicProfileRepository(
        activityRepository: activities,
        friendshipRepository: repo,
        currentUserId: () => 'viewer',
      ),
    );
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.friendship, FriendshipAction.incoming);
    await vm.setBlocked(true);
    await drainRemovalChanges();
    expect(vm.friendship, FriendshipAction.unavailable);
    await vm.setBlocked(false);
    await drainRemovalChanges();
    expect(vm.friendship, FriendshipAction.add);
    expect(await repo.getReceivedRequests('viewer'), isEmpty);
  });

  test('A disposed blocked list ignores a late unblock', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    await repo.blockUser(userId: 'viewer', target: juliaTarget);
    final vm = BlockedUsersViewModel(userId: 'viewer', repository: repo);
    await vm.load();
    final pending = Completer<void>();
    repo.onUnblock = (_) => pending.future;
    final action = vm.unblock(juliaTarget.id);
    vm.dispose();
    pending.complete();
    expect(await action, isFalse);
  });
}
