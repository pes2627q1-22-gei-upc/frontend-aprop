import 'dart:async';

import '../models/received_friend_request.dart';
import '../models/friendship_removal.dart';
import '../models/blocked_user.dart';
import '../models/user_summary.dart';
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
  final _blocked = <String, List<BlockedUser>>{};
  final _blockLoads = <String, Future<List<BlockedUser>>>{};
  final _blockWrites = <(String, String), Future<BlockedUser>>{};
  final _unblockWrites = <(String, String), Future<void>>{};
  final _blockRevisions = <String, int>{};
  final _blockOverrides =
      <String, Map<String, ({int revision, BlockedUser? value})>>{};
  final _blockChanges = StreamController<String>.broadcast(sync: true);

  Future<List<BlockedUser>> fetchBlocked(String userId);
  Future<BlockedUser> sendBlock(String userId, UserSummary target);
  Future<void> sendUnblock(String userId, String targetId);

  @override
  List<BlockedUser>? cachedBlockedUsers(String userId) => _blocked[userId];

  @override
  bool? isBlocked(String userId, String targetId) {
    final id = peerId(targetId);
    final snapshot = _blocked[userId];
    if (snapshot != null) {
      return snapshot.any((entry) => peerId(entry.user.id) == id);
    }
    final override = _blockOverrides[userId]?[id];
    return override == null ? null : override.value != null;
  }

  @override
  Stream<void> watchBlocks(String userId) =>
      _blockChanges.stream.where((id) => id == userId).map((_) {});

  @override
  Future<List<BlockedUser>> getBlockedUsers(String userId) async {
    if (_disposed) throw StateError('Repository disposed');
    final future = _blockLoads.putIfAbsent(userId, () => _loadBlocked(userId));
    try {
      return await future;
    } finally {
      if (identical(_blockLoads[userId], future)) _blockLoads.remove(userId);
    }
  }

  Future<List<BlockedUser>> _loadBlocked(String userId) async {
    final revision = _blockRevisions[userId] ?? 0;
    final result = await fetchBlocked(userId);
    final records = {for (final entry in result) peerId(entry.user.id): entry};
    for (final change in (_blockOverrides[userId] ?? {}).entries) {
      if (change.value.revision <= revision) continue;
      if (change.value.value case final blocked?) {
        records[change.key] = blocked;
      } else {
        records.remove(change.key);
      }
    }
    final snapshot = _orderedBlocked(records.values);
    if (!_disposed) {
      final previous = _blocked[userId];
      final previousIds = {
        for (final entry in previous ?? const <BlockedUser>[])
          peerId(entry.user.id),
      };
      final nextIds = records.keys.toSet();
      if (previousIds.length != nextIds.length ||
          !previousIds.containsAll(nextIds)) {
        _blockRevisions[userId] = (_blockRevisions[userId] ?? 0) + 1;
      }
      _blocked[userId] = snapshot;
      for (final entry in snapshot) {
        if (!(previous?.any(
              (old) => peerId(old.user.id) == peerId(entry.user.id),
            ) ??
            false)) {
          _cancelBlockedRequests(userId, peerId(entry.user.id));
          _recordRemoval(userId, peerId(entry.user.id));
        }
      }
      _blockChanges.add(userId);
    }
    return snapshot;
  }

  List<BlockedUser> _orderedBlocked(Iterable<BlockedUser> entries) {
    final items = entries.toList()
      ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
    return List.unmodifiable(items);
  }

  void _recordBlock(String userId, String targetId, BlockedUser? value) {
    final revision = (_blockRevisions[userId] ?? 0) + 1;
    _blockRevisions[userId] = revision;
    (_blockOverrides[userId] ??= {})[targetId] = (
      revision: revision,
      value: value,
    );
    final previous = _blocked[userId];
    if (previous != null) {
      _blocked[userId] = _orderedBlocked([
        for (final entry in previous)
          if (peerId(entry.user.id) != targetId) entry,
        ?value,
      ]);
    }
    if (value != null) {
      _cancelBlockedRequests(userId, targetId);
      _recordRemoval(userId, targetId);
    }
    _blockChanges.add(userId);
  }

  @override
  Future<BlockedUser> blockUser({
    required String userId,
    required UserSummary target,
  }) async {
    if (_disposed) throw StateError('Repository disposed');
    final id = peerId(target.id);
    if (userId.isEmpty || id.isEmpty || id == peerId(userId)) {
      throw ArgumentError('Expected another person');
    }
    final key = (userId, id);
    final future = _blockWrites.putIfAbsent(
      key,
      () => _forPeer(userId, id, () async {
        final blocked = await sendBlock(userId, target);
        if (peerId(blocked.user.id) != id) {
          throw const FormatException('Block belongs to another person');
        }
        if (!_disposed) _recordBlock(userId, id, blocked);
        return blocked;
      }),
    );
    try {
      return await future;
    } finally {
      if (identical(_blockWrites[key], future)) _blockWrites.remove(key);
    }
  }

  @override
  Future<void> unblockUser({
    required String userId,
    required String targetId,
  }) async {
    if (_disposed) throw StateError('Repository disposed');
    final id = peerId(targetId);
    if (userId.isEmpty || id.isEmpty || id == peerId(userId)) {
      throw ArgumentError('Expected another person');
    }
    final key = (userId, id);
    final future = _unblockWrites.putIfAbsent(
      key,
      () => _forPeer(userId, id, () async {
        await sendUnblock(userId, id);
        if (!_disposed) _recordBlock(userId, id, null);
      }),
    );
    try {
      await future;
    } finally {
      if (identical(_unblockWrites[key], future)) _unblockWrites.remove(key);
    }
  }

  void _cancelBlockedRequests(String userId, String targetId) {
    for (final request in [
      ...?_received[userId],
      ..._confirmedFor(userId).values.map((r) => r.request),
    ]) {
      if (peerId(request.senderId) != targetId) continue;
      (_confirmed[userId] ??= {})[request.id] = FriendRequestResolution(
        request: request,
        status: FriendRequestStatus.rejected,
      );
    }
    _received[userId] = List.unmodifiable(
      (_received[userId] ?? const <ReceivedFriendRequest>[]).where(
        (r) => peerId(r.senderId) != targetId,
      ),
    );
  }

  void _recordRemoval(String userId, String id) {
    (_removed[userId] ??= {}).add(id);
    _removalChanges.add((
      userId: userId,
      value: FriendshipRemoval(friendId: id),
    ));
  }

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
      if (isBlocked(userId, peer) == true) continue;
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
        _recordRemoval(userId, peer);
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
    final blockRevision = _blockRevisions[userId] ?? 0;
    final future = _loads.putIfAbsent(userId, () => fetchReceived(userId));
    try {
      final result = await future;
      if (!_disposed && blockRevision != (_blockRevisions[userId] ?? 0)) {
        if (identical(_loads[userId], future)) _loads.remove(userId);
        return await getReceivedRequests(userId);
      }
      final pending = List<ReceivedFriendRequest>.unmodifiable(
        result.where(
          (r) =>
              !_confirmedFor(userId).containsKey(r.id) &&
              isBlocked(userId, r.senderId) != true,
        ),
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
    if (isBlocked(userId, request.senderId) == true) {
      throw StateError('Blocked relationship');
    }
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
    await Future.wait([
      _changes.close(),
      _removalChanges.close(),
      _blockChanges.close(),
    ]);
  }
}
