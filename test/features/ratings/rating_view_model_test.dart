import 'dart:async';

import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:aprop/features/ratings/models/already_rated_exception.dart';
import 'package:aprop/features/ratings/models/rating_not_found_exception.dart';
import 'package:aprop/features/ratings/presentation/view_models/rating_view_model.dart';
import 'package:aprop/features/ratings/repositories/rating_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRatingRepository implements RatingRepository {
  final calls = <(String, int)>[];
  final updates = <(String, int)>[];
  final deletes = <String>[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<void> updateRating({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    updates.add((activityId, score));
    await gate?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> deleteRating({
    required String userId,
    required String activityId,
  }) async {
    deletes.add(activityId);
    await gate?.future;
    if (failure != null) throw failure!;
  }

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

  group('edit and delete', () {
    setUp(() => viewModel.submit('a1', 2));

    test('update stores the new score', () async {
      expect(await viewModel.update('a1', 5), isTrue);

      expect(repository.updates, [('a1', 5)]);
      expect(viewModel.scoreFor('a1'), 5);
      expect(viewModel.errorFor('a1'), isNull);
    });

    test('update works for a rating made earlier (score unknown)', () async {
      repository.failure = const AlreadyRatedException();
      await viewModel.submit('a2', 3);
      repository.failure = null;

      expect(await viewModel.update('a2', 4), isTrue);
      expect(viewModel.scoreFor('a2'), 4);
    });

    test('update ignores unrated activities and invalid scores', () async {
      expect(await viewModel.update('a9', 3), isFalse);
      expect(await viewModel.update('a1', 6), isFalse);
      expect(repository.updates, isEmpty);
    });

    test('failed update keeps the old score and shows an error', () async {
      repository.failure = StateError('offline');

      expect(await viewModel.update('a1', 5), isFalse);
      expect(viewModel.scoreFor('a1'), 2);
      expect(viewModel.errorFor('a1'), isNotNull);
      expect(viewModel.isSubmitting('a1'), isFalse);
    });

    test('remove makes the activity ratable again', () async {
      expect(await viewModel.remove('a1'), isTrue);

      expect(repository.deletes, ['a1']);
      expect(viewModel.hasRated('a1'), isFalse);
      expect(viewModel.scoreFor('a1'), isNull);
      await viewModel.submit('a1', 4);
      expect(viewModel.scoreFor('a1'), 4);
    });

    test('failed remove keeps the rating and shows an error', () async {
      repository.failure = StateError('offline');

      expect(await viewModel.remove('a1'), isFalse);
      expect(viewModel.hasRated('a1'), isTrue);
      expect(viewModel.errorFor('a1'), isNotNull);
    });

    test(
      'a rating missing on the server is no longer shown as rated',
      () async {
        repository.failure = const RatingNotFoundException();

        expect(await viewModel.update('a1', 5), isFalse);
        expect(viewModel.hasRated('a1'), isFalse);
        expect(viewModel.errorFor('a1'), isNotNull);
      },
    );

    test('removing a rating already gone on the server succeeds', () async {
      repository.failure = const RatingNotFoundException();

      expect(await viewModel.remove('a1'), isTrue);
      expect(viewModel.hasRated('a1'), isFalse);
      expect(viewModel.errorFor('a1'), isNull);
    });

    test('clearError drops a stale error', () async {
      repository.failure = StateError('offline');
      await viewModel.update('a1', 5);

      viewModel.clearError('a1');

      expect(viewModel.errorFor('a1'), isNull);
    });

    test('ignores a second change while one is pending', () async {
      repository.gate = Completer<void>();
      final first = viewModel.update('a1', 5);

      expect(viewModel.isSubmitting('a1'), isTrue);
      expect(await viewModel.remove('a1'), isFalse);
      repository.gate!.complete();
      await first;

      expect(repository.deletes, isEmpty);
      expect(viewModel.scoreFor('a1'), 5);
    });
  });

  test('demo repository edits and deletes only the own rating', () async {
    final demo = DemoRatingRepository();
    await demo.rate(userId: 'u1', activityId: 'a1', score: 5);

    await demo.updateRating(userId: 'u1', activityId: 'a1', score: 2);
    await expectLater(
      demo.updateRating(userId: 'u2', activityId: 'a1', score: 2),
      throwsA(isA<RatingNotFoundException>()),
    );
    await demo.deleteRating(userId: 'u1', activityId: 'a1');
    await expectLater(
      demo.deleteRating(userId: 'u1', activityId: 'a1'),
      throwsA(isA<RatingNotFoundException>()),
    );
    await demo.rate(userId: 'u1', activityId: 'a1', score: 3);
  });
}
