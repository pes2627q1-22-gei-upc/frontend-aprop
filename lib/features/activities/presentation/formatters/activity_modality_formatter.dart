import '../../models/activity.dart';

/// «Presencial», «En línia» o «Presencial i en línia».
String activityModalityLabel(ActivityModality modality) => switch (modality) {
  ActivityModality.inPerson => 'Presencial',
  ActivityModality.online => 'En línia',
  ActivityModality.mixed => 'Presencial i en línia',
};
