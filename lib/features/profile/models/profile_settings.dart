enum ProfilePreference {
  showMyPlans,
  reminders,
  social,
  recommendations,
  cancellations,
}

/// Plan-sharing settings; notification preferences have their own snapshot.
class ProfileSettings {
  const ProfileSettings({this.showMyPlans = false});

  final bool showMyPlans;

  bool valueOf(ProfilePreference preference) => switch (preference) {
    ProfilePreference.showMyPlans => showMyPlans,
    _ => throw ArgumentError('Use the notification preferences snapshot'),
  };

  ProfileSettings withPreference(ProfilePreference preference, bool enabled) {
    if (preference != ProfilePreference.showMyPlans) {
      throw ArgumentError('Use the notification preferences snapshot');
    }
    return ProfileSettings(showMyPlans: enabled);
  }
}
