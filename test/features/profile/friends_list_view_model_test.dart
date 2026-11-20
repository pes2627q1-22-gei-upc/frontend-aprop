import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/features/profile/presentation/view_models/friends_list_view_model.dart';
import 'package:aprop/features/profile/repositories/friends_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFriends implements FriendsRepository {
  Object? error;
  String? requestedId = 'none';
  List<UserSummary> friends = const [
    UserSummary(id: 'me', username: 'me', displayName: 'Jo'),
    UserSummary(id: 'u2', username: 'marc', displayName: 'Marc Vidal'),
  ];

  @override
  Future<List<UserSummary>> getFriends({String? userId}) async {
    requestedId = userId;
    if (error case final error?) throw error;
    return friends;
  }
}

void main() {
  late _FakeFriends repository;

  setUp(() => repository = _FakeFriends());

  test('Loads the friends and leaves out the signed-in person', () async {
    final model = FriendsListViewModel(
      repository: repository,
      hiddenIds: {'me'},
    );
    addTearDown(model.dispose);

    final loading = model.load();
    expect(model.isLoading, isTrue);
    await loading;

    expect(repository.requestedId, isNull);
    expect(model.friends!.map((f) => f.id), ['u2']);
    expect(model.errorMessage, isNull);
  });

  test('Asks for another person’s friends with their ID', () async {
    final model = FriendsListViewModel(repository: repository, userId: 'u2');
    addTearDown(model.dispose);

    await model.load();

    expect(repository.requestedId, 'u2');
  });

  test('A failure shows an error that can be retried', () async {
    repository.error = Exception('offline');
    final model = FriendsListViewModel(repository: repository);
    addTearDown(model.dispose);

    await model.load();
    expect(model.friends, isNull);
    expect(model.errorMessage, isNotNull);

    repository.error = null;
    await model.load();
    expect(model.friends, hasLength(2));
    expect(model.errorMessage, isNull);
  });
}
