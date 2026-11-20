import '../../../core/network/api_client.dart';
import '../models/user_summary.dart';
import '../repositories/friends_repository.dart';

/// `GET /users/{id}/friends` and then `GET /users/{id}` for each friend.
// TODO(DP-065): the API returns only the friends' IDs, so each friend costs
// one more request. If it returned name, username and photo, only this class
// would change.
class HttpFriendsRepository implements FriendsRepository {
  HttpFriendsRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Profiles requested at the same time, as the notices do.
  static const _parallel = 4;

  @override
  Future<List<UserSummary>> getFriends({String? userId}) async {
    final headers = Map<String, String>.unmodifiable(
      await apiClient.buildHeaders(),
    );
    final owner = userId == null ? 'me' : Uri.encodeComponent(userId);
    final decoded = await apiClient.getJson(
      'users/$owner/friends',
      headers: headers,
    );
    if (decoded is! List<Object?> || decoded.any((id) => id is! String)) {
      throw const FormatException('Expected a list of user IDs');
    }
    final ids = decoded.cast<String>().toSet().toList();
    final friends = <String, UserSummary>{};
    for (var offset = 0; offset < ids.length; offset += _parallel) {
      await Future.wait(
        ids.skip(offset).take(_parallel).map((id) async {
          final friend = await _summary(id, headers);
          if (friend != null) friends[id] = friend;
        }),
      );
    }
    // Keep the server's order.
    return List.unmodifiable([for (final id in ids) ?friends[id]]);
  }

  /// Null if the account no longer exists.
  Future<UserSummary?> _summary(String id, Map<String, String> headers) async {
    final Object? decoded;
    try {
      decoded = await apiClient.getJson(
        'users/${Uri.encodeComponent(id)}',
        headers: headers,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
    if (decoded is! Map<String, Object?> ||
        decoded['id'] is! String ||
        (decoded['id'] as String).toLowerCase() != id.toLowerCase()) {
      throw const FormatException('Expected the friend’s profile');
    }
    final username = decoded['username'];
    if (username is! String || username.trim().isEmpty) {
      throw const FormatException('Expected a username');
    }
    final name = decoded['name'];
    final picture = decoded['profile-picture'];
    final uri = picture is String ? Uri.tryParse(picture) : null;
    return UserSummary(
      id: id,
      username: username.trim(),
      displayName: name is String && name.trim().isNotEmpty
          ? name.trim()
          : username.trim(),
      avatarUrl:
          uri != null &&
              {'http', 'https'}.contains(uri.scheme) &&
              uri.host.isNotEmpty
          ? uri.toString()
          : null,
    );
  }
}
