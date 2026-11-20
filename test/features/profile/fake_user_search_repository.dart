import 'package:aprop/features/profile/models/user_search_page.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/features/profile/repositories/user_search_repository.dart';

class FakeUserSearchRepository implements UserSearchRepository {
  final requests = <({String query, int page})>[];
  List<UserSummary> users = const [];
  Future<UserSearchPage> Function(String query, int page)? onSearch;

  @override
  Future<UserSearchPage> searchUsers(String query, {int page = 0}) async {
    requests.add((query: query, page: page));
    if (onSearch case final search?) return search(query, page);
    return UserSearchPage(users: users, totalCount: users.length);
  }
}
