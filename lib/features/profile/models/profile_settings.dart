enum ProfilePreference {
  showMyPlans,
  reminders,
  social,
  recommendations,
  cancellations,
}

/// Plan-sharing and language settings; delivery preferences have their own snapshot.
class ProfileSettings {
  const ProfileSettings({this.showMyPlans = false, this.language});

  final bool showMyPlans;

  /// Stored account UI language (`ca`, `es` or `en`), or `null` when absent.
  final String? language;

  bool valueOf(ProfilePreference preference) => switch (preference) {
    ProfilePreference.showMyPlans => showMyPlans,
    _ => throw ArgumentError('Use the notification preferences snapshot'),
  };

  ProfileSettings withPreference(ProfilePreference preference, bool enabled) {
    if (preference != ProfilePreference.showMyPlans) {
      throw ArgumentError('Use the notification preferences snapshot');
    }
    return ProfileSettings(showMyPlans: enabled, language: language);
  }

  ProfileSettings withLanguage(String? language) =>
      ProfileSettings(showMyPlans: showMyPlans, language: language);
}
