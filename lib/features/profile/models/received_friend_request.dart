enum FriendRequestStatus { pending, accepted, rejected }

/// A received request is identified by both people and its exact sent instant.
/// Names and notification IDs cannot identify a friendship mutation.
class ReceivedFriendRequest {
  ReceivedFriendRequest({
    required this.senderId,
    required this.receiverId,
    required DateTime sentAt,
  }) : sentAt = sentAt.toUtc();

  final String senderId;
  final String receiverId;
  final DateTime sentAt;
  String get id => '$senderId/$receiverId/${sentAt.microsecondsSinceEpoch}';
}

class FriendRequestResolution {
  FriendRequestResolution({required this.request, required this.status}) {
    if (status == FriendRequestStatus.pending) {
      throw ArgumentError('A response must be confirmed');
    }
  }
  final ReceivedFriendRequest request;
  final FriendRequestStatus status;
}
