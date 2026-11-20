import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';

/// «Presencial», «En línia» o «Presencial i en línia».
String activityModalityLabel(ActivityModality modality) => switch (modality) {
  ActivityModality.inPerson => currentL10n.modalityInPerson,
  ActivityModality.online => currentL10n.modalityOnline,
  ActivityModality.mixed => currentL10n.modalityMixed,
};
