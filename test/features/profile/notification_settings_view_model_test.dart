import 'dart:async';

import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/profile/models/notification_preferences.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile_repositories.dart';

void main() {
  late FakeProfileSettingsRepository repository;
  late ProfileSettingsViewModel model;
  setUp(() {
    repository = FakeProfileSettingsRepository();
    model = ProfileSettingsViewModel(
      userId: 'a',
      repository: repository,
      onSignOut: () async {},
    );
  });
  tearDown(() => model.dispose());

  test(
    'Notification load failure leaves privacy usable and retry is deduplicated',
    () async {
      repository.onGetNotifications = (_) async => throw StateError('Offline');
      await model.load();
      expect(model.settings, isNotNull);
      expect(model.notificationPreferences, isNull);
      expect(model.notificationsError, isNotNull);
      expect(model.errorMessage, isNull);
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(model.settings!.showMyPlans, isTrue);
      final pending = Completer<NotificationPreferences>();
      repository.onGetNotifications = (_) => pending.future;
      final retrying = model.loadNotificationPreferences();
      await model.loadNotificationPreferences();
      expect(repository.notificationUsers, ['a', 'a']);
      pending.complete(repository.notifications);
      await retrying;
      expect(model.notificationsError, isNull);
      expect(model.preferenceValue(ProfilePreference.social), isTrue);
      expect(model.settings!.showMyPlans, isTrue);
    },
  );

  test('Privacy load failure does not hide or disable known notification preferences', () async {
    repository.onGet = (_) async => throw StateError('Profile unavailable');
    await model.load();
    expect(model.settings, isNull);
    expect(model.errorMessage, isNotNull);
    expect(model.notificationsError, isNull);
    expect(model.canUpdatePreference(ProfilePreference.social), isTrue);
    await model.updatePreference(ProfilePreference.social, false);
    expect(model.preferenceValue(ProfilePreference.social), isFalse);
  });

  test(
    'Writes retain confirmed values and serialize all settings actions',
    () async {
      await model.load();
      final before = model.notificationPreferences!;
      final pending = Completer<NotificationPreferences>();
      repository.onUpdateNotification = (_, _, _) => pending.future;
      final changing = model.updatePreference(ProfilePreference.social, false);
      await model.updatePreference(ProfilePreference.reminders, false);
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      await model.loadNotificationPreferences();
      await model.signOut();
      expect(model.notificationPreferences, same(before));
      expect(model.savingPreference, ProfilePreference.social);
      expect(model.isBusy, isTrue);
      expect(repository.notificationUpdates, hasLength(1));
      expect(repository.updates, isEmpty);
      pending.complete(before.withPreference(ProfilePreference.social, false));
      await changing;
      expect(model.preferenceValue(ProfilePreference.social), isFalse);
      expect(model.preferenceValue(ProfilePreference.reminders), isTrue);
      expect(model.settings!.showMyPlans, isFalse);
    },
  );

  test(
    'An ignored write is retriable and retries the same intent only once',
    () async {
      await model.load();
      repository.onUpdateNotification = (_, _, _) async =>
          repository.notifications;
      await model.updatePreference(ProfilePreference.social, false);
      expect(model.preferenceValue(ProfilePreference.social), isTrue);
      expect(model.preferenceError, isNotNull);
      expect(model.actionError, isNull);
      expect(model.failedPreference, ProfilePreference.social);
      final pending = Completer<NotificationPreferences>();
      repository.onUpdateNotification = (_, _, _) => pending.future;
      final retrying = model.retryPreference();
      await model.retryPreference();
      pending.complete(
        repository.notifications.withPreference(
          ProfilePreference.social,
          false,
        ),
      );
      await retrying;
      expect(repository.notificationUpdates.map((change) => change.enabled), [
        false,
        false,
      ]);
      expect(model.preferenceValue(ProfilePreference.social), isFalse);
      expect(model.preferenceError, isNull);
      expect(model.canRetryPreference, isFalse);
    },
  );

  test('A refresh resolves uncertain writes and preserves privacy', () async {
    repository.settings = const ProfileSettings(showMyPlans: true);
    await model.load();
    repository.onUpdateNotification = (_, _, _) async =>
        throw StateError('Confirmation lost');
    await model.updatePreference(ProfilePreference.social, false);
    repository.notifications = repository.notifications.withPreference(
      ProfilePreference.social,
      false,
    );
    await model.loadNotificationPreferences();
    await model.retryPreference();
    expect(model.preferenceValue(ProfilePreference.social), isFalse);
    expect(model.settings!.showMyPlans, isTrue);
    expect(model.preferenceError, isNull);
    expect(repository.notificationUpdates, hasLength(1));
  });

  test('Refresh failure preserves confirmed switches and exposes a separate load error', () async {
    await model.load();
    final before = model.notificationPreferences;
    repository.onGetNotifications = (_) async => throw StateError('Offline');
    await model.loadNotificationPreferences();
    expect(model.notificationPreferences, same(before));
    expect(model.notificationsError, isNotNull);
    expect(model.preferenceError, isNull);
  });

  test('A confirmed write replaces a failed refresh and clears its stale load error', () async {
    await model.load();
    repository.onGetNotifications = (_) async => throw StateError('Offline');
    await model.loadNotificationPreferences();
    expect(model.notificationsError, isNotNull);
    await model.updatePreference(ProfilePreference.social, false);
    expect(model.preferenceValue(ProfilePreference.social), isFalse);
    expect(model.notificationsError, isNull);
  });

  test('Missing types and unknown values cannot be written', () async {
    await model.updatePreference(ProfilePreference.social, false);
    expect(repository.notificationUpdates, isEmpty);
    repository.notifications = NotificationPreferences({
      ProfilePreference.reminders: false,
    });
    await model.load();
    expect(model.supports(ProfilePreference.social), isFalse);
    await model.updatePreference(ProfilePreference.social, true);
    expect(repository.notificationUpdates, isEmpty);
    expect(model.preferenceValue(ProfilePreference.reminders), isFalse);
  });

  test('Late reads and writes after disposal do not notify or replace account state', () async {
    final pending = Completer<NotificationPreferences>();
    repository.onGetNotifications = (_) => pending.future;
    final disposable = ProfileSettingsViewModel(
      userId: 'old-account',
      repository: repository,
      onSignOut: () async {},
    );
    await disposable.load();
    var notifications = 0;
    disposable.addListener(() => notifications++);
    disposable.dispose();
    pending.complete(repository.notifications);
    await Future<void>.delayed(Duration.zero);
    expect(disposable.notificationPreferences, isNull);
    expect(notifications, 0);

    await model.load();
    final write = Completer<NotificationPreferences>();
    repository.onUpdateNotification = (_, _, _) => write.future;
    final writing = ProfileSettingsViewModel(
      userId: 'old-write',
      repository: repository,
      onSignOut: () async {},
    );
    await writing.load();
    var writeNotifications = 0;
    writing.addListener(() => writeNotifications++);
    final changing = writing.updatePreference(ProfilePreference.social, false);
    final beforeDispose = writeNotifications;
    writing.dispose();
    final other = ProfileSettingsViewModel(
      userId: 'b',
      repository: FakeProfileSettingsRepository(),
      onSignOut: () async {},
    );
    addTearDown(other.dispose);
    await other.load();
    write.complete(
      repository.notifications.withPreference(ProfilePreference.social, false),
    );
    await changing;
    expect(writeNotifications, beforeDispose);
    expect(writing.preferenceValue(ProfilePreference.social), isTrue);
    expect(other.preferenceValue(ProfilePreference.social), isTrue);
  });

  test('Language syncing blocks notification writes and notification writes block language syncing', () async {
    SharedPreferences.setMockInitialValues({});
    final localised = ProfileSettingsViewModel(
      userId: 'a',
      repository: repository,
      onSignOut: () async {},
      localeController: LocaleController(),
    );
    addTearDown(localised.dispose);
    await localised.load();
    final language = Completer<void>();
    repository.onUpdateLanguage = (_) => language.future;
    final syncing = localised.changeLanguage(const Locale('ca'));
    await localised.updatePreference(ProfilePreference.social, false);
    expect(repository.notificationUpdates, isEmpty);
    language.complete();
    await syncing;
    final write = Completer<NotificationPreferences>();
    repository.onUpdateNotification = (_, _, _) => write.future;
    final changing = localised.updatePreference(
      ProfilePreference.social,
      false,
    );
    await localised.changeLanguage(const Locale('es'));
    expect(repository.languages, ['ca']);
    write.complete(
      repository.notifications.withPreference(ProfilePreference.social, false),
    );
    await changing;
    expect(localised.isBusy, isFalse);
  });
}
