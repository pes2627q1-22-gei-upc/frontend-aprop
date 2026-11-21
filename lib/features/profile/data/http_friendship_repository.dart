import '../../../core/network/api_client.dart';
import '../models/received_friend_request.dart';
import 'cached_friendship_repository.dart';
import 'profile_api.dart';
import '../../../core/network/utc_timestamp.dart';

class HttpFriendshipRepository extends CachedFriendshipRepository {
  HttpFriendshipRepository({required this.apiClient});
  final ApiClient apiClient;

  @override
  String peerId(String value) => value.toLowerCase();

  @override
  Future<void> sendRemoval(String userId, String friendId) async {
    final target = _uuid(friendId);
    final session = await ProfileApi(apiClient).own(userId);
    if (target == (session.profile['id']! as String).toLowerCase()) {
      throw ArgumentError('Cannot remove yourself');
    }
    // The 200 response confirms the write; its free-form message is not state.
    await apiClient.postJson(
      'users/${Uri.encodeComponent(target)}/unfriend',
      headers: session.headers,
    );
  }

  @override
  Future<List<ReceivedFriendRequest>> fetchReceived(String userId) async {
    final session = await ProfileApi(apiClient).own(userId);
    final owner = (session.profile['id']! as String).toLowerCase();
    final decoded = await apiClient.getJson(
      'users/me/friend-requests',
      headers: session.headers,
    );
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected received requests');
    }
    final requests = [
      for (final row in decoded) _request(row, owner, 'Pending'),
    ];
    if (requests.map((r) => r.id).toSet().length != requests.length) {
      throw const FormatException('Duplicate request');
    }
    return List.unmodifiable(requests);
  }

  @override
  Future<FriendRequestResolution> sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  ) async {
    final session = await ProfileApi(apiClient).own(userId);
    final owner = (session.profile['id']! as String).toLowerCase();
    if (request.receiverId != owner) {
      throw const FormatException('Request recipient changed');
    }
    final date = Uri.encodeComponent(request.sentAt.toIso8601String());
    final state = accept ? 'Accepted' : 'Rejected';
    final decoded = await apiClient.postJson(
      'users/${Uri.encodeComponent(request.senderId)}/friend-requests/$date/${accept ? 'accept' : 'deny'}',
      headers: session.headers,
    );
    final confirmed = _request(decoded, owner, state);
    if (confirmed.id != request.id) {
      throw const FormatException('Unexpected resolved request');
    }
    return FriendRequestResolution(
      request: confirmed,
      status: accept
          ? FriendRequestStatus.accepted
          : FriendRequestStatus.rejected,
    );
  }

  ReceivedFriendRequest _request(Object? value, String owner, String state) {
    if (value is! Map<String, Object?> || value['state'] != state) {
      throw const FormatException('Unexpected request state');
    }
    final sender = _uuid(value['sender-id']);
    final receiver = _uuid(value['receiver-id']);
    if (receiver != owner || sender == receiver) {
      throw const FormatException('Unexpected request participants');
    }
    return ReceivedFriendRequest(
      senderId: sender,
      receiverId: receiver,
      sentAt: utcTimestamp(value['date-sent']),
    );
  }

  String _uuid(Object? value) {
    if (value is! String ||
        !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
            .hasMatch(value) ||
        value == '00000000-0000-0000-0000-000000000000') {
      throw const FormatException('Expected real user UUID');
    }
    return value.toLowerCase();
  }
}
