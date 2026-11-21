import 'user_summary.dart';

/// A block owned by the signed-in account, never the other direction.
class BlockedUser {
  const BlockedUser({required this.user, required this.blockedAt});
  final UserSummary user;
  final DateTime blockedAt;
}
