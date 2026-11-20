import '../models/user_search_page.dart';

/// Maximum number of Unicode code points accepted by GET /users.
const userSearchQueryLimit = 100;

abstract interface class UserSearchRepository {
  /// Zero-based search by username or name. Blank queries return an empty page
  /// without listing everyone. Throws on failure; an error is never an empty
  /// result. The backend applies account visibility and blocking rules.
  Future<UserSearchPage> searchUsers(String query, {int page = 0});
}
