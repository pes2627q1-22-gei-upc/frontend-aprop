import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/models/public_profile.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:aprop/features/profile/repositories/public_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements PublicProfileRepository {
  Object? profileError;
  Object? plansError;
  bool plansVisible = true;
  int planCalls = 0;

  final _activity = Activity(
    id: 'a1',
    title: 'Concert',
    category: 'Música',
    municipality: 'Girona',
    startsAt: DateTime(2026, 10, 1),
    imageAsset: 'assets/images/jazz_al_parc.jpg',
    source: ActivitySource.community,
  );

  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    if (profileError case final error?) throw error;
    return PublicProfile(
      profile: UserProfile(
        userId: userId,
        displayName: 'Marc Vidal',
        username: 'marcvidal',
        progress: const ProfileProgress(level: null, experience: 0),
      ),
      plansVisible: plansVisible,
      isFriend: plansVisible,
    );
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) async => [
    _activity,
  ];

  @override
  Future<List<Activity>> getPastPlans(String userId) async {
    planCalls++;
    if (plansError case final error?) throw error;
    return [_activity];
  }
}

void main() {
  late _FakeRepository repository;
  late PublicProfileViewModel viewModel;

  setUp(() {
    repository = _FakeRepository();
    viewModel = PublicProfileViewModel(userId: 'u2', repository: repository);
  });
  tearDown(() => viewModel.dispose());

  test('Loads the header and both lists when the plans are visible', () async {
    await viewModel.load();

    expect(viewModel.profile?.profile.username, 'marcvidal');
    expect(viewModel.createdActivities, hasLength(1));
    expect(viewModel.pastPlans, hasLength(1));
    expect(viewModel.errorMessage, isNull);
  });

  test('Private plans are never requested', () async {
    repository.plansVisible = false;

    await viewModel.load();
    await viewModel.loadPastPlans();

    expect(repository.planCalls, 0);
    expect(viewModel.pastPlans, isNull);
    expect(viewModel.createdActivities, hasLength(1));
  });

  test('A failed load shows an error and can be retried', () async {
    repository.profileError = Exception('offline');

    await viewModel.load();
    expect(viewModel.profile, isNull);
    expect(viewModel.errorMessage, isNotNull);

    repository.profileError = null;
    await viewModel.load();
    expect(viewModel.profile, isNotNull);
    expect(viewModel.errorMessage, isNull);
  });

  test('A missing person is not an error to retry', () async {
    repository.profileError = const PublicProfileNotFound();

    await viewModel.load();

    expect(viewModel.notFound, isTrue);
    expect(viewModel.errorMessage, isNull);
  });

  test('A failed plans list keeps the header and the created list', () async {
    repository.plansError = Exception('offline');

    await viewModel.load();

    expect(viewModel.profile, isNotNull);
    expect(viewModel.createdActivities, hasLength(1));
    expect(viewModel.pastPlans, isNull);
    expect(viewModel.plansError, isNotNull);
  });
}
