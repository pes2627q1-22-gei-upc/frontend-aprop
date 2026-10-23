import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:aprop/features/auth/data/demo_user_sync_repository.dart';
import 'package:aprop/features/auth/models/auth_failure.dart';

void main() {
  late String? uid;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    uid = 'uid-1';
  });

  DemoUserSyncRepository repository() => DemoUserSyncRepository(
    currentUid: () => uid,
    currentEmail: () => 'pol@aprop.cat',
    preferences: SharedPreferencesAsync(),
  );

  test('Com el backend: sense nom no crea res', () async {
    expect(await repository().sync(), isNull);
  });

  test('Desa el nom el primer cop i després el conserva', () async {
    final created = await repository().sync(username: 'polvidal');
    expect(created?.username, 'polvidal');

    // Un nom diferent s'ignora, com fa el backend amb un usuari existent.
    final again = await repository().sync(username: 'altre');
    expect(again?.username, 'polvidal');
    expect((await repository().sync())?.username, 'polvidal');
  });

  test('Cada compte té el seu nom', () async {
    await repository().sync(username: 'polvidal');
    uid = 'uid-2';
    expect(await repository().sync(), isNull);
  });

  test('Permet provar el nom repetit', () {
    expect(
      repository().sync(username: 'laiasoler'),
      throwsA(AuthFailure.usernameAlreadyInUse),
    );
  });
}
