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
      expect(model.actionError, isNotNull);
      repository.onUpdate = null;
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(model.actionError, isNull);
      expect(model.settings!.showMyPlans, isTrue);
      await model.updatePreference(ProfilePreference.showMyPlans, true);
      expect(repository.updates, hasLength(2));
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
