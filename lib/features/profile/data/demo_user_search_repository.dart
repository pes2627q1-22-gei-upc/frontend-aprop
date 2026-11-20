import '../models/user_search_page.dart';
import '../repositories/user_search_repository.dart';
import 'demo_public_profile_repository.dart';

/// Searches the same fictional people as the demo public profiles.
class DemoUserSearchRepository implements UserSearchRepository {
  const DemoUserSearchRepository({this.pageSize = 20}) : assert(pageSize > 0);

  final int pageSize;

  @override
  Future<UserSearchPage> searchUsers(String query, {int page = 0}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final trimmed = query.trim();
    if (trimmed.runes.length > userSearchQueryLimit) {
      throw ArgumentError.value(query, 'query', 'Search query is too long');
    }
    if (trimmed.isEmpty) return UserSearchPage(users: [], totalCount: 0);
    final needle = trimmed.toLowerCase();
    final users =
        DemoPublicProfileRepository.searchablePeople
            .where(
              (user) =>
                  user.username.toLowerCase().contains(needle) ||
                  user.displayName.toLowerCase().contains(needle),
            )
            .toList()
          ..sort((a, b) => a.username.compareTo(b.username));
    final start = page * pageSize;
    return UserSearchPage(
      users: users.skip(start).take(pageSize),
      totalCount: users.length,
      nextPage: start + pageSize < users.length ? page + 1 : null,
    );
  }
}
