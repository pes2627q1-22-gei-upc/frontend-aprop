import 'dart:async';

import '../models/received_friend_request.dart';
import '../models/friendship_removal.dart';
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
  final _removals = <(String, String), Future<void>>{};
  final _removed = <String, Set<String>>{};
  final _peerOperations = <(String, String), Future<void>>{};
  final _removalChanges =
      StreamController<({String userId, FriendshipRemoval value})>.broadcast(
        sync: true,
      );
  bool _disposed = false;

  Future<List<ReceivedFriendRequest>> fetchReceived(String userId);
  Future<FriendRequestResolution> sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  );
  Future<void> sendRemoval(String userId, String friendId);

  /// Demo aliases and HTTP UUID casing must share a single relationship key.
  String peerId(String value) => value;

  @override
  Set<String> removedFriends(String userId) =>
      Set.unmodifiable(_removed[userId] ?? const <String>{});

  @override
  bool? confirmedFriendship(String userId, String friendId) {
    final peer = peerId(friendId);
    if (_removed[userId]?.contains(peer) ?? false) return false;
    if (resolutions(userId).any(
      (r) =>
          peerId(r.request.senderId) == peer &&
          r.status == FriendRequestStatus.accepted,
    )) {
      return true;
    }
    return null;
  }

  @override
  void reconcileFriends(String userId, Iterable<String> friendIds) {
    if (_disposed) return;
    for (final id in friendIds) {
      final peer = peerId(id);
      _removed[userId]?.remove(peer);
    }
  }

  @override
  Stream<FriendshipRemoval> watchRemovals(String userId) => _removalChanges
      .stream
      .where((event) => event.userId == userId)
      .map((event) => event.value);

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    if (_disposed) throw StateError('Repository disposed');
    final peer = peerId(friendId);
    if (userId.isEmpty || peer.isEmpty || peer == peerId(userId)) {
      throw ArgumentError('Expected another person');
    }
    if (confirmedFriendship(userId, peer) == false) return;
    final key = (userId, peer);
    final future = _removals.putIfAbsent(
      key,
      () => _forPeer(userId, peer, () async {
        await sendRemoval(userId, peer);
        if (_disposed) return;
        (_removed[userId] ??= {}).add(peer);
        _removalChanges.add((
          userId: userId,
          value: FriendshipRemoval(friendId: peer),
        ));
      }),
    );
    try {
      await future;
    } finally {
      if (identical(_removals[key], future)) _removals.remove(key);
    }
  }

  // Serialize acceptance and removal for one relationship, across screens.
  Future<T> _forPeer<T>(
    String userId,
    String friendId,
    Future<T> Function() action,
  ) async {
    final key = (userId, peerId(friendId));
    final previous = _peerOperations[key];
    final completed = Completer<void>();
    _peerOperations[key] = completed.future;
    try {
      if (previous != null) await previous;
      if (_disposed) throw StateError('Repository disposed');
      return await action();
    } finally {
      completed.complete();
      if (identical(_peerOperations[key], completed.future)) {
        _peerOperations.remove(key);
      }
    }
  }

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
    final received = request;
    return _forPeer(
      userId,
      received.senderId,
      () => _sendResponse(userId, received, accept),
    );
  }

  Future<FriendRequestResolution> _sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  ) async {
    final result = await sendResponse(userId, request, accept);
    if (result.request.id != request.id ||
        result.status !=
            (accept
                ? FriendRequestStatus.accepted
                : FriendRequestStatus.rejected)) {
      throw const FormatException('Unexpected friendship response');
    }
    if (!_disposed) {
      if (result.status == FriendRequestStatus.accepted) {
        _removed[userId]?.remove(peerId(request.senderId));
      }
      (_confirmed[userId] ??= {})[request.id] = result;
      _received[userId] = List.unmodifiable(
        (_received[userId] ?? const <ReceivedFriendRequest>[]).where(
          (r) => r.id != request.id,
        ),
      );
      _changes.add((userId: userId, value: result));
    }
    return result;
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([_changes.close(), _removalChanges.close()]);
  }
}
