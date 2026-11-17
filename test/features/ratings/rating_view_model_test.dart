import 'dart:async';

import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:aprop/features/ratings/models/already_rated_exception.dart';
import 'package:aprop/features/ratings/presentation/view_models/rating_view_model.dart';
import 'package:aprop/features/ratings/repositories/rating_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRatingRepository implements RatingRepository {
  final calls = <(String, int)>[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<void> rate({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    calls.add((activityId, score));
    await gate?.future;
    if (failure != null) throw failure!;
  }
}

void main() {
  late _FakeRatingRepository repository;
  late RatingViewModel viewModel;

  setUp(() {
    repository = _FakeRatingRepository();
    viewModel = RatingViewModel(userId: 'u1', repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test('starts without ratings, errors or pending submissions', () {
    expect(viewModel.hasRated('a1'), isFalse);
    expect(viewModel.scoreFor('a1'), isNull);
    expect(viewModel.isSubmitting('a1'), isFalse);
    expect(viewModel.errorFor('a1'), isNull);
  });

  test('stores the score after the repository confirms it', () async {
    await viewModel.submit('a1', 4);

    expect(repository.calls, [('a1', 4)]);
    expect(viewModel.scoreFor('a1'), 4);
    expect(viewModel.hasRated('a1'), isTrue);
    expect(viewModel.isSubmitting('a1'), isFalse);
  });

  test('shows an error, keeps it unrated and allows retrying', () async {
    repository.failure = StateError('offline');
    await viewModel.submit('a1', 3);

    expect(viewModel.hasRated('a1'), isFalse);
    expect(viewModel.errorFor('a1'), isNotNull);

    repository.failure = null;
    await viewModel.submit('a1', 3);
    expect(viewModel.scoreFor('a1'), 3);
    expect(viewModel.errorFor('a1'), isNull);
  });

  test('ignores a second tap while the first is pending', () async {
    repository.gate = Completer<void>();
    final first = viewModel.submit('a1', 5);
    await viewModel.submit('a1', 1);

    expect(viewModel.isSubmitting('a1'), isTrue);
    repository.gate!.complete();
    await first;

    expect(repository.calls, [('a1', 5)]);
    expect(viewModel.scoreFor('a1'), 5);
  });

  test('does not rate twice', () async {
    await viewModel.submit('a1', 2);
    await viewModel.submit('a1', 5);

    expect(repository.calls, [('a1', 2)]);
    expect(viewModel.scoreFor('a1'), 2);
  });

  test('treats an already rated rejection as rated, not as an error', () async {
    repository.failure = const AlreadyRatedException();
    await viewModel.submit('a1', 4);

    expect(viewModel.hasRated('a1'), isTrue);
    expect(viewModel.scoreFor('a1'), isNull);
    expect(viewModel.errorFor('a1'), isNull);
  });

  test(
    'rejects scores outside 1 to 5 without calling the repository',
    () async {
      await viewModel.submit('a1', 0);
      await viewModel.submit('a1', 6);

      expect(repository.calls, isEmpty);
      expect(viewModel.hasRated('a1'), isFalse);
    },
  );

  test('demo repository accepts one rating per user and activity', () async {
    final demo = DemoRatingRepository();
    await demo.rate(userId: 'u1', activityId: 'a1', score: 5);

    expect(
      demo.rate(userId: 'u1', activityId: 'a1', score: 4),
      throwsA(isA<AlreadyRatedException>()),
    );
    await demo.rate(userId: 'u2', activityId: 'a1', score: 4);
  });
}
