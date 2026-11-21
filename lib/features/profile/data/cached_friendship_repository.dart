import 'dart:async';

import '../models/received_friend_request.dart';
import '../repositories/friendship_repository.dart';

/// Coalesces concurrent actions across screens and publishes only confirmations.
abstract class CachedFriendshipRepository implements FriendshipRepository {
  final _changes =
      StreamController<
        ({String userId, FriendRequestResolution value})
      >.broadcast(sync: true);
  final _received = <String, List<ReceivedFriendRequest>>{};
  final _confirmed = <String, Map<String, FriendRequestResolution>>{};
  final _loads = <String, Future<List<ReceivedFriendRequest>>>{};
  final _writes = <(String, String), Future<FriendRequestResolution>>{};
  bool _disposed = false;

  Future<List<ReceivedFriendRequest>> fetchReceived(String userId);
  Future<FriendRequestResolution> sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  );

  @override
  Future<List<ReceivedFriendRequest>> getReceivedRequests(String userId) async {
    if (_disposed) throw StateError('Repository disposed');
    final future = _loads.putIfAbsent(userId, () => fetchReceived(userId));
    try {
      final result = await future;
      final pending = List<ReceivedFriendRequest>.unmodifiable(
        result.where((r) => !_confirmedFor(userId).containsKey(r.id)),
      );
      if (!_disposed) _received[userId] = pending;
      return pending;
    } finally {
      if (identical(_loads[userId], future)) _loads.remove(userId);
    }
  }

  Map<String, FriendRequestResolution> _confirmedFor(String userId) =>
      _confirmed[userId] ?? const {};

  @override
  List<FriendRequestResolution> resolutions(String userId) =>
      List.unmodifiable(_confirmedFor(userId).values);

  @override
  Stream<FriendRequestResolution> watchChanges(String userId) =>
      _changes.stream.where((e) => e.userId == userId).map((e) => e.value);

  @override
  Future<FriendRequestResolution> respond({
    required String userId,
    required String requestId,
    required bool accept,
  }) async {
    if (_disposed) throw StateError('Repository disposed');
    final confirmed = _confirmedFor(userId)[requestId];
    if (confirmed != null) return confirmed;
    final key = (userId, requestId);
    final future = _writes.putIfAbsent(
      key,
      () => _respond(userId, requestId, accept),
    );
    try {
      return await future;
    } finally {
      if (identical(_writes[key], future)) _writes.remove(key);
    }
  }

  Future<FriendRequestResolution> _respond(
    String userId,
    String requestId,
    bool accept,
  ) async {
    var request = _received[userId]
        ?.where((r) => r.id == requestId)
        .firstOrNull;
    request ??= (await getReceivedRequests(userId))
        .where((r) => r.id == requestId)
        .firstOrNull;
    if (request == null) throw StateError('Received request not found');
    final result = await sendResponse(userId, request, accept);
    if (result.request.id != request.id ||
        result.status !=
            (accept
                ? FriendRequestStatus.accepted
                : FriendRequestStatus.rejected)) {
      throw const FormatException('Unexpected friendship response');
    }
    if (!_disposed) {
      (_confirmed[userId] ??= {})[requestId] = result;
      _received[userId] = List.unmodifiable(
        (_received[userId] ?? const <ReceivedFriendRequest>[]).where(
          (r) => r.id != requestId,
        ),
      );
      _changes.add((userId: userId, value: result));
    }
    return result;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _changes.close();
  }
}
