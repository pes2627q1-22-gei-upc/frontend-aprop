import '../models/activity.dart';
import '../models/new_activity.dart';
import '../repositories/activity_repository.dart';

/// Catàleg en memòria. Les activitats que creen els usuaris s'hi afegeixen i
/// es perden en tancar l'aplicació.
class DemoActivityRepository implements ActivityRepository {
  static final List<Activity> _catalogue = List.unmodifiable([
    Activity(
      id: 'demo-jazz',
      title: 'Jazz al parc',
      category: 'Música',
      municipality: 'Barcelona',
      startsAt: DateTime(2026, 9, 26, 19),
      imageAsset: 'assets/images/jazz_al_parc.jpg',
      source: ActivitySource.culturalAgenda,
      description:
          'Gaudeix d’una tarda de jazz en directe a l’aire lliure. '
          'Una proposta per descobrir nous sons i compartir la música '
          'en un entorn verd de Barcelona.',
    ),
    Activity(
      id: 'demo-exhibition',
      title: 'Mirades de Catalunya',
      category: 'Exposicions',
      municipality: 'Girona',
      startsAt: DateTime(2026, 9, 27, 10),
      imageAsset: 'assets/images/mirades_de_catalunya.jpg',
      source: ActivitySource.culturalAgenda,
      description:
          'Una proposta expositiva per descobrir perspectives diverses '
          'sobre la cultura i el territori de Catalunya.',
    ),
    Activity(
      id: 'demo-theatre',
      title: 'Teatre sota les estrelles',
      category: 'Teatre',
      municipality: 'Tarragona',
      startsAt: DateTime(2026, 9, 27, 20),
      imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
      source: ActivitySource.community,
      description:
          'Una proposta de teatre a l’aire lliure per gaudir d’una nit '
          'de cultura a Tarragona. Comparteix l’experiència en un '
          'entorn acollidor sota les estrelles.',
      creator: const ActivityCreator(
        name: 'Laia Soler',
        avatarAsset: 'assets/images/laia_soler.jpg',
        isFriend: true,
      ),
    ),
  ]);

  final List<Activity> _activities = [..._catalogue];
  int _createdCount = 0;

  @override
  Future<List<Activity>> getActivities() async {
    final sorted = [..._activities]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    for (final activity in _activities) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  // TODO(DP-017): sense contracte del backend; es guarda només en memòria.
  @override
  Future<Activity> createActivity(NewActivity activity) async {
    final created = Activity(
      id: 'demo-created-${++_createdCount}',
      title: activity.title,
      category: activity.category,
      municipality: activity.municipality,
      startsAt: activity.startsAt,
      source: ActivitySource.community,
      imageAsset: activity.imageAsset,
      creator: activity.creator,
      description: activity.description,
      directions: activity.directions,
      location: activity.location,
      price: activity.price,
    );
    _activities.add(created);
    return created;
  }
}
