import 'package:aprop/features/activities/models/activity.dart';

Activity event(String id, DateTime date, {String category = 'Música'}) =>
    Activity(
      id: id,
      title: id,
      category: category,
      municipality: 'Barcelona',
      startsAt: date,
      imageAsset: 'assets/images/jazz_al_parc.jpg',
      source: ActivitySource.culturalAgenda,
    );
