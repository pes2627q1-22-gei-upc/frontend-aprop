import 'package:aprop/features/activities/models/activity.dart';

import '../activities/fake_activity_repository.dart';

const agendaUserId = 'user-1';

/// The fixed «today» of the agenda tests: Saturday 26 September 2026.
DateTime agendaToday() => DateTime(2026, 9, 26, 9);

Activity agendaActivity(
  String id,
  DateTime startsAt, {
  String? title,
  String? schedule,
}) {
  return Activity(
    id: id,
    title: title ?? 'Activitat $id',
    category: 'Música',
    municipality: 'Barcelona',
    startsAt: startsAt,
    schedule: schedule,
    imageAsset: 'assets/images/jazz_al_parc.jpg',
    source: ActivitySource.culturalAgenda,
  );
}

final agendaCatalogue = {
  'past-early': agendaActivity(
    'past-early',
    DateTime(2026, 9, 10, 18),
    title: 'Concert antic',
  ),
  'past-recent': agendaActivity(
    'past-recent',
    DateTime(2026, 9, 25, 20),
    title: 'Exposició d’ahir',
  ),
  'jazz': agendaActivity('jazz', DateTime(2026, 9, 26, 19), title: 'Jazz'),
  'cinema': agendaActivity('cinema', DateTime(2026, 9, 26, 11)),
  'theatre': agendaActivity('theatre', DateTime(2026, 9, 27, 20)),
  'october': agendaActivity('october', DateTime(2026, 10, 3, 18)),
  'next-year': agendaActivity(
    'next-year',
    DateTime(2027, 1, 15, 17),
    title: 'Festival d’hivern',
  ),
};

FakeActivityRepository agendaActivityRepository() {
  return FakeActivityRepository()
    ..findActivity = (id) async => agendaCatalogue[id];
}
