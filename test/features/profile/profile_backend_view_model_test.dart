import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/data/profile_json_mapper.dart';
import 'package:aprop/features/profile/models/profile_avatar.dart';
import 'package:aprop/features/profile/models/profile_capabilities.dart';
import 'package:aprop/features/profile/models/profile_failure.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backend_profile_fixture.dart' as backend;
import 'fake_profile_repositories.dart';
import 'profile_test_data.dart';

void main() {
  late FakeProfileRepository repository;
  late FakeProfileImagePicker picker;
  late ProfileViewModel model;
  setUp(() {
    repository = FakeProfileRepository()
      ..sourceCapabilities = ProfileCapabilities.backend
      ..profile = profileFromJson(backend.backendProfile(), profileUser);
    picker = FakeProfileImagePicker();
    model = ProfileViewModel(
      user: profileUser,
      repository: repository,
      imagePicker: picker,
    );
  });
  tearDown(() => model.dispose());

  test('Created activities fail independently and retry without losing identity or prior results', () async {
    repository.onCreated = (_) async => throw StateError('Offline');
    await model.load();
    expect(model.profile!.username, 'maria');
    expect(model.errorMessage, isNull);
    expect(model.createdError, isNotNull);
    expect(model.hasLoadedCreated, isFalse);
    repository.onCreated = (_) async => sampleProfile().createdActivities;
    await model.loadCreatedActivities();
    final before = model.profile!.createdActivities;
    expect(before, isNotEmpty);
    expect(model.hasLoadedCreated, isTrue);
    repository.onCreated = (_) async => throw StateError('Offline');
    await model.loadCreatedActivities();
    expect(model.profile!.createdActivities, before);
    expect(model.createdError, isNotNull);
  });

  test(
    'An in-flight collection refresh cannot erase a confirmed edit',
    () async {
      await model.load();
      final collection = Completer<List<Activity>>();
      repository.onCreated = (_) => collection.future;
      final loading = model.loadCreatedActivities();
      await model.loadCreatedActivities();
      expect(repository.createdUsers, hasLength(2));
      expect(
        await model.saveDetails(
          biography: 'Cinema',
          municipality: 'Ignored',
          name: 'Maria Casals',
          username: 'maria_c',
        ),
        isTrue,
      );
      collection.complete(sampleProfile().createdActivities);
      await loading;
      expect(model.profile!.username, 'maria_c');
      expect(model.profile!.createdActivities, isNotEmpty);
      expect(repository.updates.single.municipality, isEmpty);
    },
  );

  test('Identity uses byte limits and reports a duplicate username without replacing confirmed data', () async {
    await model.load();
    expect(
      await model.saveDetails(biography: 'é' * 251, municipality: ''),
      isFalse,
    );
    expect(
      await model.saveDetails(biography: '', municipality: '', name: 'é' * 51),
      isFalse,
    );
    expect(
      await model.saveDetails(
        biography: '',
        municipality: '',
        username: 'has spaces',
      ),
      isFalse,
    );
    expect(repository.updates, isEmpty);
    repository.onUpdate = (_, _, _) async => throw ProfileFailure.usernameInUse;
    expect(
      await model.saveDetails(
        biography: 'New',
        municipality: '',
        username: 'taken',
      ),
      isFalse,
    );
    expect(model.saveError, contains('ja està ocupat'));
    expect(model.profile!.username, 'maria');
    repository.onUpdate = null;
    expect(
      await model.saveDetails(
        biography: 'New',
        municipality: '',
        username: 'available',
      ),
      isTrue,
    );
    expect(model.profile!.username, 'available');
    expect(model.saveError, isNull);
  });

  test(
    'Photo cancellation and picker errors do not upload or change the profile',
    () async {
      await model.load();
      final before = model.profile;
      expect(await model.changeAvatar(), isFalse);
      expect(repository.uploads, isEmpty);
      expect(model.avatarError, isNull);
      picker.onPick = () async =>
          throw const AvatarSelectionException('Foto massa gran');
      expect(await model.changeAvatar(), isFalse);
      expect(model.avatarError, 'Foto massa gran');
      expect(model.profile, same(before));
      expect(repository.uploads, isEmpty);
    },
  );

  test('Photo writes wait for confirmation, serialize mutations and preserve created events', () async {
    repository.onCreated = (_) async => sampleProfile().createdActivities;
    await model.load();
    picker.onPick = () async =>
        ProfileAvatar(bytes: [1], filename: 'avatar.png');
    final upload = Completer<UserProfile>();
    repository.onUpload = (_) => upload.future;
    final before = model.profile;
    final changing = model.changeAvatar();
    await Future<void>.delayed(Duration.zero);
    expect(model.isChangingAvatar, isTrue);
    expect(model.profile, same(before));
    expect(await model.changeAvatar(), isFalse);
    expect(
      await model.saveDetails(biography: 'New', municipality: ''),
      isFalse,
    );
    upload.complete(
      profileFromJson({
        ...backend.backendProfile(),
        'profile-picture': 'https://images.example.test/new.png',
      }, profileUser),
    );
    expect(await changing, isTrue);
    expect(model.profile!.avatarUrl, endsWith('/new.png'));
    expect(model.profile!.createdActivities, before!.createdActivities);
    expect(repository.uploads, hasLength(1));
  });

  test('A failed upload preserves the old image and can be retried', () async {
    await model.load();
    final before = model.profile!.avatarUrl;
    picker.onPick = () async =>
        ProfileAvatar(bytes: [1], filename: 'avatar.png');
    repository.onUpload = (_) async => throw StateError('Offline');
    expect(await model.changeAvatar(), isFalse);
    expect(model.profile!.avatarUrl, before);
    expect(model.avatarError, isNotNull);
    repository.onUpload = null;
    expect(await model.changeAvatar(), isTrue);
    expect(model.avatarError, isNull);
  });

  test('Late picker replies cannot upload after account disposal', () async {
    final disposable = ProfileViewModel(
      user: profileUser,
      repository: repository,
      imagePicker: picker,
    );
    await disposable.load();
    final selected = Completer<ProfileAvatar?>();
    picker.onPick = () => selected.future;
    final changing = disposable.changeAvatar();
    disposable.dispose();
    selected.complete(ProfileAvatar(bytes: [1], filename: 'avatar.png'));
    expect(await changing, isFalse);
    expect(repository.uploads, isEmpty);
  });

  test('Interrupted selections require an explicit new choice and never auto-upload', () async {
    picker.onRecovery = () async => true;
    await model.checkInterruptedAvatarSelection();
    await model.checkInterruptedAvatarSelection();
    expect(picker.recoveries, 1);
    expect(model.avatarError, contains('Torna-la a triar'));
    expect(picker.picks, 0);
    expect(repository.uploads, isEmpty);
    await model.load();
    await model.changeAvatar();
    expect(model.avatarError, isNull);
  });
}
