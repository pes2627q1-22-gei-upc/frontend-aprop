import '../../activities/models/activity.dart';
import '../../activities/repositories/activity_repository.dart';
import '../models/public_profile.dart';
import '../models/user_profile.dart';
import '../repositories/public_profile_repository.dart';

/// Example people of the demo data: the creator of the catalogue's community
/// activity and the people in the example notices.
// TODO(DP-063): Demo friendship and privacy are fixed examples, not a graph.
class DemoPublicProfileRepository implements PublicProfileRepository {
  DemoPublicProfileRepository({required this.activityRepository});

  final ActivityRepository activityRepository;

  /// The notices name Laia with another ID; both open the same profile.
  static const _aliases = {'demo-person-laia': 'demo-laiasoler'};

  static const _people = {
    'demo-laiasoler': (
      name: 'Laia Soler',
      username: 'laiasoler',
      biography: 'Teatre, concerts a l’aire lliure i alguna exposició.',
      avatar: 'assets/images/laia_soler.jpg',
      friends: 14,
      rating: 4.7,
      isFriend: true,
      plansVisible: true,
    ),
    'demo-person-marc': (
      name: 'Marc Vidal',
      username: 'marcvidal',
      biography: '',
      avatar: null,
      friends: 3,
      rating: null,
      isFriend: false,
      plansVisible: false,
    ),
    // A friend who keeps «Mostrar els meus plans» off.
    'demo-person-julia': (
      name: 'Júlia Riera',
      username: 'juliariera',
      biography: 'Sempre a punt per a un concert.',
      avatar: null,
      friends: 8,
      rating: null,
      isFriend: true,
      plansVisible: false,
    ),
  };

  /// Laia's example history, the same one her own profile shows.
  static const _laiaPlans = ['demo-jazz', 'demo-theatre', 'demo-exhibition'];

  String _id(String userId) => _aliases[userId] ?? userId;

  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    final id = _id(userId);
    final person = _people[id];
    if (person == null) throw const PublicProfileNotFound();
    final plans = id == 'demo-laiasoler' ? _laiaPlans.length : 0;
    return PublicProfile(
      profile: UserProfile(
        userId: userId,
        displayName: person.name,
        username: person.username,
        biography: person.biography,
        avatarAsset: person.avatar,
        planCount: plans,
        friendCount: person.friends,
        organizerRating: person.rating,
        progress: const ProfileProgress(level: null, experience: 0),
      ),
      isFriend: person.isFriend,
      plansVisible: person.plansVisible,
    );
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) async {
    final id = _id(userId);
    final catalogue = await activityRepository.getActivities();
    return List.unmodifiable(
      catalogue.where(
        (a) => a.source == ActivitySource.community && a.creator?.userId == id,
      ),
    );
  }

  @override
  Future<List<Activity>> getPastPlans(String userId) async {
    final id = _id(userId);
    if (!(_people[id]?.plansVisible ?? false)) {
      throw StateError('These plans are private');
    }
    if (id != 'demo-laiasoler') return const [];
    final catalogue = await activityRepository.getActivities();
    return List.unmodifiable(catalogue.where((a) => _laiaPlans.contains(a.id)));
  }
}
