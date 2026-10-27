/// Editing and history actually supported by the injected source.
class ProfileCapabilities {
  const ProfileCapabilities({
    this.editIdentity = false,
    this.editMunicipality = false,
    this.uploadAvatar = false,
    this.completedPlans = false,
  });
  final bool editIdentity;
  final bool editMunicipality;
  final bool uploadAvatar;
  final bool completedPlans;

  static const demo = ProfileCapabilities(
    editMunicipality: true,
    completedPlans: true,
  );
  static const backend = ProfileCapabilities(
    editIdentity: true,
    uploadAvatar: true,
  );
}
