import '../models/activity.dart';
import '../repositories/activity_repository.dart';

class DemoActivityRepository implements ActivityRepository {
  static final List<Activity> _activities = List.unmodifiable([
    Activity(
      id: 'demo-jazz',
      title: 'Jazz al parc',
      category: 'Música',
      municipality: 'Barcelona',
      startsAt: DateTime(2026, 9, 26, 19),
      imageAsset: 'assets/images/jazz_al_parc.jpg',
      source: ActivitySource.culturalAgenda,
    ),
    Activity(
      id: 'demo-exhibition',
      title: 'Mirades de Catalunya',
      category: 'Exposicions',
      municipality: 'Girona',
      startsAt: DateTime(2026, 9, 27, 10),
      imageAsset: 'assets/images/mirades_de_catalunya.jpg',
      source: ActivitySource.culturalAgenda,
    ),
    Activity(
      id: 'demo-theatre',
      title: 'Teatre sota les estrelles',
      category: 'Teatre',
      municipality: 'Tarragona',
      startsAt: DateTime(2026, 9, 27, 20),
      imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
      source: ActivitySource.community,
      creator: const ActivityCreator(
        name: 'Laia Soler',
        avatarAsset: 'assets/images/laia_soler.jpg',
        isFriend: true,
      ),
    ),
  ]);

  @override
  Future<List<Activity>> getActivities() async {
    return _activities;
  }
}
