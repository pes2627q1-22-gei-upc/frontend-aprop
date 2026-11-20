import 'user_summary.dart';

/// The total counts all server matches, including pages not loaded yet.
class UserSearchPage {
  UserSearchPage({
    required Iterable<UserSummary> users,
    required this.totalCount,
    this.nextPage,
  }) : users = List.unmodifiable(users),
       assert(totalCount >= 0),
       assert(nextPage == null || nextPage >= 0);

  final List<UserSummary> users;
  final int totalCount;
  final int? nextPage;
}
