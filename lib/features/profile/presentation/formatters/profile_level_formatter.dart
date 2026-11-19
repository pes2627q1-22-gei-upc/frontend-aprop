import '../../models/user_profile.dart';
import '../../../../core/l10n/locale_controller.dart';

extension ProfileLevelLabel on ProfileLevel {
  String get label => switch (this) {
    ProfileLevel.curious => currentL10n.levelCurious,
    ProfileLevel.explorer => currentL10n.levelExplorer,
    ProfileLevel.adventurer => currentL10n.levelAdventurer,
    ProfileLevel.discoverer => currentL10n.levelDiscoverer,
    ProfileLevel.ambassador => currentL10n.levelAmbassador,
  };

  String get fullLabel => switch (this) {
    ProfileLevel.curious || ProfileLevel.explorer => label,
    _ => currentL10n.levelCultural(label),
  };
}
