enum ProfilePreference {
  showMyPlans,
  reminders,
  friendActivity,
  recommendations,
  friendRequests,
}

/// Preferences only: received notifications and enrollments are separate data.
class ProfileSettings {
  const ProfileSettings({
    this.showMyPlans = false,
    this.reminders = true,
    this.friendActivity = true,
    this.recommendations = false,
    this.friendRequests = true,
  });

  final bool showMyPlans;
  final bool reminders;
  final bool friendActivity;
  final bool recommendations;
  final bool friendRequests;

  bool valueOf(ProfilePreference preference) => switch (preference) {
    ProfilePreference.showMyPlans => showMyPlans,
    ProfilePreference.reminders => reminders,
    ProfilePreference.friendActivity => friendActivity,
    ProfilePreference.recommendations => recommendations,
    ProfilePreference.friendRequests => friendRequests,
  };

  ProfileSettings withPreference(ProfilePreference preference, bool enabled) {
    bool value(ProfilePreference field) =>
        field == preference ? enabled : valueOf(field);
    return ProfileSettings(
      showMyPlans: value(ProfilePreference.showMyPlans),
      reminders: value(ProfilePreference.reminders),
      friendActivity: value(ProfilePreference.friendActivity),
      recommendations: value(ProfilePreference.recommendations),
      friendRequests: value(ProfilePreference.friendRequests),
    );
  }
}
