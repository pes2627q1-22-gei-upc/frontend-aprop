import '../../models/user_profile.dart';

extension ProfileLevelLabel on ProfileLevel {
  String get label => switch (this) {
    ProfileLevel.curious => 'Curiós/a',
    ProfileLevel.explorer => 'Explorador/a',
    ProfileLevel.adventurer => 'Aventurer/a',
    ProfileLevel.discoverer => 'Descobridor/a',
    ProfileLevel.ambassador => 'Ambaixador/a',
  };

  String get fullLabel => switch (this) {
    ProfileLevel.curious || ProfileLevel.explorer => label,
    _ => '$label cultural',
  };
}
