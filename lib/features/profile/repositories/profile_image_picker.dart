import '../models/profile_avatar.dart';

abstract interface class ProfileImagePicker {
  /// Null means that the user cancelled. Does not upload anything.
  Future<ProfileAvatar?> pickAvatar();

  /// Detects an interrupted Android selection; never uploads recovered files
  /// without a fresh user action, including after an account change.
  Future<bool> hadInterruptedSelection();
}
