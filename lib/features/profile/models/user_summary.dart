/// Public information needed to identify a person in search results.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.avatarAsset,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? avatarAsset;
}
