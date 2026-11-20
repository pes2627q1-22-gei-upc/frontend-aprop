import '../../../core/network/api_client.dart';
import '../models/user_search_page.dart';
import '../models/user_summary.dart';
import '../repositories/user_search_repository.dart';

/// GET /users?q=…&pageNum=…&pageSize=… with the current Firebase token.
class HttpUserSearchRepository implements UserSearchRepository {
  HttpUserSearchRepository({required this.apiClient, this.pageSize = 20}) {
    if (pageSize < 1 || pageSize > 50) {
      throw RangeError.range(pageSize, 1, 50, 'pageSize');
    }
  }

  final ApiClient apiClient;
  final int pageSize;

  @override
  Future<UserSearchPage> searchUsers(String query, {int page = 0}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final trimmed = query.trim();
    if (trimmed.runes.length > userSearchQueryLimit) {
      throw ArgumentError.value(query, 'query', 'Search query is too long');
    }
    if (trimmed.isEmpty) return UserSearchPage(users: [], totalCount: 0);
    final headers = Map<String, String>.unmodifiable(
      await apiClient.buildHeaders(),
    );
    if (!RegExp(r'^Bearer \S+$').hasMatch(headers['Authorization'] ?? '')) {
      throw ApiException('Authentication required', statusCode: 401);
    }
    final decoded = await apiClient.getJson(
      'users',
      headers: headers,
      queryParameters: {
        'q': trimmed,
        'pageNum': '$page',
        'pageSize': '$pageSize',
      },
    );
    if (decoded is! Map<String, Object?> ||
        decoded['query'] != trimmed ||
        decoded['page-num'] != page ||
        decoded['page-size'] != pageSize ||
        decoded['total'] is! int ||
        (decoded['total'] as int) < 0 ||
        decoded['users'] is! List<Object?>) {
      throw const FormatException('Expected a matching user search page');
    }
    final rows = decoded['users'] as List<Object?>;
    final total = decoded['total'] as int;
    if (rows.length > pageSize ||
        rows.length > total ||
        (rows.isEmpty && page * pageSize < total)) {
      throw const FormatException('Inconsistent user search results');
    }
    final users = <UserSummary>[];
    final ids = <String>{};
    for (final row in rows) {
      if (row is! Map<String, Object?>) {
        throw const FormatException('Expected a user summary');
      }
      final id = row['id'];
      final username = row['username'];
      final name = row['name'];
      final picture = row['profile-picture'];
      if (id is! String ||
          !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
              .hasMatch(id) ||
          id == '00000000-0000-0000-0000-000000000000' ||
          !ids.add(id.toLowerCase()) ||
          username is! String ||
          username.trim().isEmpty ||
          name is! String ||
          picture is! String) {
        throw const FormatException('Invalid user summary');
      }
      final avatar = Uri.tryParse(picture.trim());
      users.add(
        UserSummary(
          id: id.toLowerCase(),
          username: username.trim(),
          displayName: name.trim().isEmpty ? username.trim() : name.trim(),
          avatarUrl:
              avatar != null &&
                  {'https', 'http'}.contains(avatar.scheme) &&
                  avatar.host.isNotEmpty &&
                  avatar.userInfo.isEmpty
              ? avatar.toString()
              : null,
        ),
      );
    }
    return UserSearchPage(
      users: users,
      totalCount: total,
      nextPage: (page + 1) * pageSize < total ? page + 1 : null,
    );
  }
}
