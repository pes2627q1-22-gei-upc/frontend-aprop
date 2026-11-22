import 'package:shared_preferences/shared_preferences.dart';

/// Language changes not yet accepted by the server, isolated by account.
class PendingLanguage {
  String _key(String userId) => 'auth.pendingLanguage.$userId';

  Future<String?> read(String userId) async =>
      (await SharedPreferences.getInstance()).getString(_key(userId));

  Future<void> save(String userId, String language) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(userId),
      language,
    );
  }

  /// Avoid erasing a newer choice already stored for this account.
  Future<void> clearIfMatches(String userId, String language) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_key(userId)) == language) {
      await preferences.remove(_key(userId));
    }
  }
}
