import 'package:aprop/features/attendance/presentation/view_models/attendance_view_model.dart';
import 'package:aprop/features/attendance/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AttendanceRepository {
  final answers = <String, bool?>{};
  Object? readError;
  Object? writeError;
  int reads = 0;

  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async {
    reads++;
    if (readError case final error?) throw error;
    return answers[activityId];
  }

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {
    if (writeError case final error?) throw error;
    answers[activityId] = attended;
  }
}

void main() {
  late _Repository repository;
  late AttendanceViewModel model;

  setUp(() {
    repository = _Repository();
    model = AttendanceViewModel(userId: 'u', repository: repository);
  });
  tearDown(() => model.dispose());

  test('Only unanswered plans are pending, and each is read once', () async {
    repository.answers.addAll({'went': true, 'missed': false});

    await model.ensureLoaded(['went', 'missed', 'open']);
    await model.ensureLoaded(['went', 'missed', 'open']);

    expect(repository.reads, 3);
    expect(model.isPending('open'), isTrue);
    expect(model.isPending('went'), isFalse);
    expect(model.isPending('missed'), isFalse);
    expect(model.attended('went'), isTrue);
    expect(model.attended('missed'), isFalse);
  });

  test(
    'A failed read does not ask: the question is not shown by mistake',
    () async {
      repository.readError = Exception('offline');

      await model.ensureLoaded(['open']);

      expect(model.isKnown('open'), isFalse);
      expect(model.isPending('open'), isFalse);
    },
  );

  test('Answering stores it; only «Sí» lets the person rate', () async {
    await model.ensureLoaded(['a', 'b']);

    expect(await model.answer('a', attended: true), isTrue);
    expect(await model.answer('b', attended: false), isTrue);

    expect(repository.answers, {'a': true, 'b': false});
    expect(model.attended('a'), isTrue);
    expect(model.attended('b'), isFalse);
    expect(model.isPending('a'), isFalse);
    expect(model.isPending('b'), isFalse);
  });

  test('A failed answer keeps the question with an error', () async {
    await model.ensureLoaded(['a']);
    repository.writeError = Exception('offline');

    expect(await model.answer('a', attended: true), isFalse);

    expect(model.isPending('a'), isTrue);
    expect(model.errorFor('a'), isNotNull);
    expect(model.attended('a'), isFalse);
  });

  test('«Més tard» hides it only until the next visit', () async {
    await model.ensureLoaded(['a']);

    model.postpone('a');
    expect(model.isPending('a'), isFalse);

    model.startVisit();
    expect(model.isPending('a'), isTrue);
  });

  test('A refusal of the server is explained', () async {
    await model.ensureLoaded(['a', 'b']);

    repository.writeError = AttendanceFailure.notStarted;
    await model.answer('a', attended: true);
    expect(model.errorFor('a'), 'Aquesta activitat encara no ha començat.');

    repository.writeError = AttendanceFailure.notEnrolled;
    await model.answer('b', attended: true);
    expect(model.errorFor('b'), 'Ja no hi estàs apuntat.');
  });
}
