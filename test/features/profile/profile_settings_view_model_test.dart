import 'dart:async';

import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:aprop/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile_repositories.dart';

void main() {
  late FakeProfileSettingsRepository repository;
  late ProfileSettingsViewModel model;
  Future<void> Function() signOut = () async {};
  setUp(() {
    repository = FakeProfileSettingsRepository();
    signOut = () async {};
    model = ProfileSettingsViewModel(
      userId: 'user-a',
      repository: repository,
      onSignOut: () => signOut(),
    );
  });
  tearDown(() => model.dispose());

  test('Only the latest language change sets the result', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();
    final localised = ProfileSettingsViewModel(
      userId: 'user-a',
      repository: repository,
      localeController: controller,
      onSignOut: () async {},
    );
    addTearDown(localised.dispose);
    final first = Completer<void>();
    repository.onUpdateLanguage = (language) =>
        language == 'es' ? first.future : null;
    final older = localised.changeLanguage(const Locale('es'));
    await localised.changeLanguage(const Locale('en'));
    first.completeError(Exception('late failure'));
    await older;
    expect(localised.actionError, isNull);
  });

  test(
    'Loading is account scoped, deduplicated and failures can be retried',
    () async {
      final pending = Completer<ProfileSettings>();
      repository.onGet = (_) => pending.future;
      final loading = model.load();
      await model.load();
      expect(repository.users, ['user-a']);
      expect(model.isLoading, isTrue);
      pending.completeError(StateError('Offline'));
      await loading;
      expect(model.settings, isNull);
      expect(model.errorMessage, isNotNull);
      repository.onGet = null;
      await model.load();
      expect(model.errorMessage, isNull);
    },
  );

  test(
    'Toggles await confirmation and cannot overwrite overlapping writes',
    () async {
      await model.load();
      final before = model.settings;
      final pending = Completer<ProfileSettings>();
      repository.onUpdate = (_, _, _) => pending.future;
      final saving = model.updatePreference(
        ProfilePreference.showMyPlans,
        true,
      );
      await model.updatePreference(ProfilePreference.reminders, false);
      await model.load();
      expect(repository.updates, hasLength(1));
      expect(model.settings, same(before));
      expect(model.isBusy, isTrue);
      pending.complete(
        before!.withPreference(ProfilePreference.showMyPlans, true),
      );
      await saving;
      expect(model.settings!.showMyPlans, isTrue);
      expect(model.settings!.reminders, isTrue);
    },
  );

  test(
    'Failed writes retain previous values and retry clears the error',
    () async {
      await model.load();
      repository.onUpdate = (_, _, _) async => throw StateError('Offline');
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(model.settings!.showMyPlans, isFalse);
      expect(model.preferenceError, isNotNull);
      repository.onUpdate = null;
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(model.preferenceError, isNull);
      expect(model.settings!.showMyPlans, isTrue);
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(repository.updates, hasLength(2));
    },
  );

  test('Disabling stays on until confirmed, then retries the same failed intent once', () async {
    repository.settings = const ProfileSettings(showMyPlans: true);
    await model.load();
    final pending = Completer<ProfileSettings>();
    repository.onUpdate = (_, _, _) => pending.future;
    final changing = model.updatePreference(
      ProfilePreference.showMyPlans,
      false,
    );
    expect(model.settings!.showMyPlans, isTrue);
    expect(model.savingPreference, ProfilePreference.showMyPlans);
    pending.completeError(StateError('Offline'));
    await changing;
    expect(model.failedPreference, ProfilePreference.showMyPlans);
    expect(model.canRetryPreference, isTrue);
    expect(model.actionError, isNull);
    final retry = Completer<ProfileSettings>();
    repository.onUpdate = (_, _, _) => retry.future;
    final retrying = model.retryPreference();
    await model.retryPreference();
    await model.updatePreference(ProfilePreference.showMyPlans, true);
    await model.signOut();
    expect(repository.updates.map((c) => c.enabled), [false, false]);
    expect(model.isSigningOut, isFalse);
    retry.complete(const ProfileSettings(showMyPlans: false));
    await retrying;
    expect(model.settings!.showMyPlans, isFalse);
    expect(model.preferenceError, isNull);
    expect(model.failedPreference, isNull);
    expect(model.canRetryPreference, isFalse);
  });

  test(
    'A response not confirming the requested value is a retriable failure',
    () async {
      repository.settings = const ProfileSettings(showMyPlans: true);
      await model.load();
      repository.onUpdate = (_, _, _) async =>
          const ProfileSettings(showMyPlans: true);
      await model.updatePreference(ProfilePreference.showMyPlans, false);
      expect(model.settings!.showMyPlans, isTrue);
      expect(model.preferenceError, isNotNull);
      expect(model.canRetryPreference, isTrue);
    },
  );

  test(
    'A successful refresh resolves an uncertain write and clears its retry',
    () async {
      await model.load();
      repository.onUpdate = (_, _, _) async =>
          throw StateError('Connection lost after write');
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      repository.settings = const ProfileSettings(showMyPlans: true);
      await model.load();
      await model.retryPreference();
      expect(model.settings!.showMyPlans, isTrue);
      expect(model.preferenceError, isNull);
      expect(model.canRetryPreference, isFalse);
      expect(repository.updates, hasLength(1));
    },
  );

  test('Unknown and unsupported privacy settings cannot be written', () async {
    await model.updatePreference(ProfilePreference.showMyPlans, true);
    expect(repository.updates, isEmpty);
    await model.load();
    repository.supportedPreferences = {};
    await model.updatePreference(ProfilePreference.showMyPlans, true);
    expect(repository.updates, isEmpty);
  });

  test(
    'A disposed model ignores a late failed privacy write and cannot retry it',
    () async {
      final disposable = ProfileSettingsViewModel(
        userId: 'old',
        repository: repository,
        onSignOut: () async {},
      );
      await disposable.load();
      final pending = Completer<ProfileSettings>();
      repository.onUpdate = (_, _, _) => pending.future;
      var notifications = 0;
      disposable.addListener(() => notifications++);
      final changing = disposable.updatePreference(
        ProfilePreference.showMyPlans,
        true,
      );
      final before = notifications;
      disposable.dispose();
      pending.completeError(StateError('Late failure'));
      await changing;
      await disposable.retryPreference();
      expect(notifications, before);
      expect(disposable.preferenceError, isNull);
      expect(repository.updates, hasLength(1));
    },
  );

  test(
    'Language and privacy writes do not overlap in either direction',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController();
      final localised = ProfileSettingsViewModel(
        userId: 'user-a',
        repository: repository,
        localeController: controller,
        onSignOut: () async {},
      );
      addTearDown(localised.dispose);
      await localised.load();
      final language = Completer<void>();
      repository.onUpdateLanguage = (_) => language.future;
      final changingLanguage = localised.changeLanguage(const Locale('ca'));
      await localised.updatePreference(ProfilePreference.showMyPlans, true);
      expect(repository.updates, isEmpty);
      language.complete();
      await changingLanguage;
      final privacy = Completer<ProfileSettings>();
      repository.onUpdate = (_, _, _) => privacy.future;
      final changingPrivacy = localised.updatePreference(
        ProfilePreference.showMyPlans,
        true,
      );
      await localised.changeLanguage(const Locale('es'));
      expect(repository.languages, ['ca']);
      privacy.complete(const ProfileSettings(showMyPlans: true));
      await changingPrivacy;
      expect(localised.isBusy, isFalse);
    },
  );

  test('Sign-out is awaited, deduplicated and errors allow retry', () async {
    final pending = Completer<void>();
    var calls = 0;
    signOut = () {
      calls++;
      return pending.future;
    };
    final leaving = model.signOut();
    await model.signOut();
    expect(model.isSigningOut, isTrue);
    expect(calls, 1);
    pending.completeError(StateError('Offline'));
    await leaving;
    expect(model.actionError, isNotNull);
    signOut = () async {
      calls++;
    };
    await model.signOut();
    expect(model.actionError, isNull);
    expect(calls, 2);
  });

  test('Sign-out remains possible when preferences cannot load', () async {
    repository.onGet = (_) async => throw StateError('Offline');
    await model.load();
    var called = false;
    signOut = () async {
      called = true;
    };
    await model.signOut();
    expect(called, isTrue);
  });

  test('A disposed screen ignores late preference responses', () async {
    final disposable = ProfileSettingsViewModel(
      userId: 'old',
      repository: repository,
      onSignOut: () async {},
    );
    await disposable.load();
    final pending = Completer<ProfileSettings>();
    repository.onUpdate = (_, _, _) => pending.future;
    final saving = disposable.updatePreference(
      ProfilePreference.showMyPlans,
      true,
    );
    disposable.dispose();
    pending.complete(const ProfileSettings(showMyPlans: true));
    await saving;
    expect(disposable.settings!.showMyPlans, isFalse);
    await disposable.updatePreference(ProfilePreference.showMyPlans, true);
    expect(repository.updates, hasLength(1));
  });
}
