import 'user_profile.dart';

/// Another person's profile as the signed-in user may see it.
class PublicProfile {
  const PublicProfile({
    required this.profile,
    required this.plansVisible,
    this.isFriend,
  });

  /// Header data and counters; `profile.userId` is the person's ID.
  final UserProfile profile;

  /// Whether their plans can be shown (CA3): the server says so only when
  /// you are friends and the person has «Mostrar els meus plans» on.
  final bool plansVisible;

  /// Null when the server does not say (for example, without a session).
  final bool? isFriend;
}
