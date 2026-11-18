import '../models/activity.dart';
import '../models/activity_filters.dart';
import '../models/activity_page.dart';
import '../models/geo_point.dart';
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
      // Parc de la Ciutadella.
      location: const GeoPoint(latitude: 41.3881, longitude: 2.1874),
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
      location: const GeoPoint(latitude: 41.9858, longitude: 2.8249),
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
      // Amfiteatre.
      location: const GeoPoint(latitude: 41.1146, longitude: 1.2593),
      startsAt: DateTime(2026, 9, 27, 20),
      imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
      source: ActivitySource.community,
      description:
          'Una proposta de teatre a l’aire lliure per gaudir d’una nit '
          'de cultura a Tarragona. Comparteix l’experiència en un '
          'entorn acollidor sota les estrelles.',
      creator: const ActivityCreator(
        name: 'Laia Soler',
        userId: 'demo-laiasoler',
        // Same seed as the example profile (DemoProfileRepository).
        reliability: 4.7,
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
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) async {
    RangeError.checkNotNegative(page, 'page');
    if (pageSize < 1) throw RangeError.range(pageSize, 1, null, 'pageSize');
    final source = await getActivities();
    final catalogue = filters?.applyTo(source) ?? source;
    final offset = page * pageSize;
    return ActivityPage(
      items: catalogue.skip(offset).take(pageSize),
      hasMore: offset + pageSize < catalogue.length,
    );
  }

  @override
  Future<List<String>> getFilterCategories() async => activityFilterCategories;

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
