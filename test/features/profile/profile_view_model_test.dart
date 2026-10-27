import 'dart:async';

import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_repositories.dart';
import 'profile_test_data.dart';

void main() {
  late FakeProfileRepository repository;
  late ProfileViewModel model;
  setUp(() {
    repository = FakeProfileRepository();
    model = ProfileViewModel(user: profileUser, repository: repository);
  });
  tearDown(() => model.dispose());

  test(
    'Loads its account once while pending and exposes the confirmed profile',
    () async {
      final pending = Completer<UserProfile>();
      repository.onGet = (_) => pending.future;
      final loading = model.load();
      await model.load();
      expect(repository.users, ['user-a']);
      expect(model.isLoading, isTrue);
      pending.complete(repository.profile);
      await loading;
      expect(model.profile!.displayName, repository.profile.displayName);
      expect(
        model.profile!.createdActivities,
        repository.profile.createdActivities,
      );
      expect(model.isLoading, isFalse);
    },
  );

  test(
    'Failed refresh preserves the last profile and can be retried',
    () async {
      await model.load();
      final before = model.profile;
      repository.onGet = (_) async => throw StateError('Offline');
      await model.load();
      expect(model.profile, same(before));
      expect(model.errorMessage, isNotNull);
      repository.onGet = null;
      await model.load();
      expect(model.errorMessage, isNull);
    },
  );

  test(
    'Saving waits for confirmation and serializes writes and refreshes',
    () async {
      await model.load();
      final pending = Completer<UserProfile>();
      repository.onUpdate = (_, _, _) => pending.future;
      final before = model.profile;
      final saving = model.saveDetails(
        biography: '  Cinema  ',
        municipality: '  Vic  ',
      );
      expect(model.isSaving, isTrue);
      expect(model.profile, same(before));
      expect(
        await model.saveDetails(biography: 'Other', municipality: ''),
        isFalse,
      );
      await model.load();
      expect(repository.updates, hasLength(1));
      expect(repository.users, hasLength(1));
      expect(repository.updates.single.biography, 'Cinema');
      pending.complete(
        before!.withDetails(biography: 'Cinema', municipality: 'Vic'),
      );
      expect(await saving, isTrue);
      expect(model.profile!.municipality, 'Vic');
    },
  );

  test(
    'Invalid details do not write and a failed save retains data for retry',
    () async {
      await model.load();
      expect(
        await model.saveDetails(biography: 'x' * 501, municipality: ''),
        isFalse,
      );
      expect(repository.updates, isEmpty);
      expect(model.saveError, isNotNull);
      repository.onUpdate = (_, _, _) async => throw StateError('Offline');
      expect(
        await model.saveDetails(biography: 'New', municipality: ''),
        isFalse,
      );
      expect(model.profile!.biography, 'Teatre i concerts');
      repository.onUpdate = null;
      expect(
        await model.saveDetails(biography: 'New', municipality: ''),
        isTrue,
      );
      expect(model.saveError, isNull);
    },
  );

  test('Late load cannot notify a disposed model', () async {
    final pending = Completer<UserProfile>();
    repository.onGet = (_) => pending.future;
    final disposable = ProfileViewModel(
      user: profileUser,
      repository: repository,
    );
    var notifications = 0;
    disposable.addListener(() => notifications++);
    final loading = disposable.load();
    disposable.dispose();
    pending.complete(repository.profile);
    await loading;
    await disposable.load();
    expect(disposable.profile, isNull);
    expect(notifications, 1);
  });

  test('Late save cannot replace disposed account state', () async {
    final disposable = ProfileViewModel(
      user: profileUser,
      repository: repository,
    );
    await disposable.load();
    final pending = Completer<UserProfile>();
    repository.onUpdate = (_, _, _) => pending.future;
    final saving = disposable.saveDetails(
      biography: 'New',
      municipality: 'Vic',
    );
    disposable.dispose();
    pending.complete(
      repository.profile.withDetails(biography: 'New', municipality: 'Vic'),
    );
    expect(await saving, isFalse);
    expect(disposable.profile!.biography, 'Teatre i concerts');
  });
}
