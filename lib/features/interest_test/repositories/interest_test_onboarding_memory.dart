/// Per-account local fallback remembering whether onboarding already prompted
/// the interest test on this device.
///
/// Server-side `prompted` is the primary source of truth across devices; this
/// local store guards against transient network failures or older backends
/// (TODO(DP-080)).
abstract interface class InterestTestOnboardingMemory {
  Future<bool> wasPrompted(String userId);

  Future<void> markPrompted(String userId);
}

/// In-memory implementation used by default in tests and Demo runs.
class InMemoryInterestTestOnboardingMemory
    implements InterestTestOnboardingMemory {
  final Set<String> _promptedUsers = {};

  @override
  Future<bool> wasPrompted(String userId) async =>
      _promptedUsers.contains(userId);

  @override
  Future<void> markPrompted(String userId) async {
    _promptedUsers.add(userId);
  }
}
