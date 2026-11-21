import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_failure.dart';
import '../models/user_profile.dart';
import '../repositories/user_sync_repository.dart';

/// Fa el paper del backend mentre no hi ha servidor: desa el nom d'usuari de
/// cada compte en aquest dispositiu.
///
/// No pot saber els noms dels altres usuaris; només rebutja els de
/// [reservedUsernames], per poder provar l'error de nom repetit.
class DemoUserSyncRepository implements UserSyncRepository {
  DemoUserSyncRepository({
    required this._currentUid,
    required this._currentEmail,
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const reservedUsernames = {'laiasoler'};

  final String? Function() _currentUid;
  final String? Function() _currentEmail;
  final SharedPreferencesAsync _preferences;

  /// Sense backend: s'esborra el nom desat i el compte de Firebase l'esborra
  /// l'app.
  @override
  Future<bool> deleteAccount() async {
    final uid = _currentUid();
    if (uid != null) await _preferences.remove('auth.username.$uid');
    return false;
  }

  @override
  Future<UserProfile?> sync({String? username}) async {
    final uid = _currentUid();
    if (uid == null) throw StateError('No hi ha cap sessió iniciada.');

    final key = 'auth.username.$uid';
    final saved = await _preferences.getString(key);

    // Com el backend: un usuari que ja existeix conserva el seu nom.
    if (saved == null) {
      if (username == null) return null;
      if (reservedUsernames.contains(username)) {
        throw AuthFailure.usernameAlreadyInUse;
      }
      await _preferences.setString(key, username);
    }

    return UserProfile(
      id: uid,
      username: saved ?? username!,
      email: _currentEmail() ?? '',
      name: await _preferences.getString('auth.name.$uid') ?? '',
      created: saved == null,
    );
  }

  @override
  Future<UserProfile> updateName(String name) async {
    final uid = _currentUid();
    if (uid == null) throw StateError('No hi ha cap sessió iniciada.');

    await _preferences.setString('auth.name.$uid', name);
    return UserProfile(
      id: uid,
      username: await _preferences.getString('auth.username.$uid') ?? '',
      email: _currentEmail() ?? '',
      name: name,
    );
  }

  @override
  Future<void> updateLanguage(String language) async {
    final uid = _currentUid();
    if (uid == null) return;
    await _preferences.setString('auth.language.$uid', language);
  }
}
