import '../models/user_summary.dart';

/// A person's friends (#54): people with an accepted friend request.
abstract interface class FriendsRepository {
  /// Friends of [userId], or of the signed-in person when it is null. Throws
  /// on failure: an error must never look like an empty list.
  Future<List<UserSummary>> getFriends({String? userId});
}
