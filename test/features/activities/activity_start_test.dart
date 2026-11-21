import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_start.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _activity(DateTime startsAt, {String? schedule}) => Activity(
  id: 'a',
  title: 'Concert',
  category: 'Música',
  municipality: 'Barcelona',
  startsAt: startsAt,
  imageAsset: 'assets/images/jazz_al_parc.jpg',
  source: ActivitySource.culturalAgenda,
  schedule: schedule,
);

/// The backend keeps only the day of the start (DP-029): «Com va anar?» must
/// not ask in the morning about an evening concert.
void main() {
  group('The hour written in the schedule', () {
    test('Reads «20 h», «19.30 h», «A les 18:15» and «19:00 – 21:00»', () {
      expect(scheduleStartHour('20 h'), (hour: 20, minute: 0));
      expect(scheduleStartHour('A les 19.30 h'), (hour: 19, minute: 30));
      expect(scheduleStartHour('A les 18:15'), (hour: 18, minute: 15));
      expect(scheduleStartHour('19:00 – 21:00'), (hour: 19, minute: 0));
      expect(scheduleStartHour('De 10h a 14h'), (hour: 10, minute: 0));
    });

    test('Dates, prices and words are not hours', () {
      expect(scheduleStartHour(null), isNull);
      expect(scheduleStartHour(''), isNull);
      expect(scheduleStartHour('Tot el dia'), isNull);
      expect(scheduleStartHour('21.11.2026'), isNull);
      expect(scheduleStartHour('Entrada 12,50 €'), isNull);
      expect(scheduleStartHour('3 hores de durada'), isNull);
      expect(scheduleStartHour('25 h'), isNull);
    });
  });

  group('When the activity starts', () {
    test('A real hour in the date wins over the schedule', () {
      final activity = _activity(DateTime(2026, 11, 21, 19), schedule: '20 h');
      expect(activityStartTime(activity), DateTime(2026, 11, 21, 19));
    });

    test('At midnight, the hour comes from the schedule', () {
      final activity = _activity(DateTime(2026, 11, 21), schedule: '20 h');
      expect(activityStartTime(activity), DateTime(2026, 11, 21, 20));
      expect(activityHasStarted(activity, DateTime(2026, 11, 21, 19)), isFalse);
      expect(activityHasStarted(activity, DateTime(2026, 11, 21, 20)), isTrue);
    });

    test('Without any hour, it only counts once its day is over', () {
      final activity = _activity(DateTime(2026, 11, 21));
      expect(activityStartTime(activity), isNull);
      expect(
        activityHasStarted(activity, DateTime(2026, 11, 21, 23, 59)),
        isFalse,
      );
      expect(activityHasStarted(activity, DateTime(2026, 11, 22)), isTrue);
    });
  });

  group('activityHasEnded', () {
    final now = DateTime(2026, 11, 21, 10);
    test('A one-day plan ends when its day is over', () {
      expect(activityHasEnded(_activity(DateTime(2026, 11, 19)), now), isTrue);
      expect(activityHasEnded(_activity(DateTime(2026, 11, 21)), now), isFalse);
    });

    test('A multi-day plan lasts until its end day', () {
      final festival = Activity(
        id: 'f',
        title: 'Festival',
        category: 'Música',
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 11, 20),
        endsAt: DateTime(2026, 11, 22),
        imageAsset: 'assets/images/jazz_al_parc.jpg',
        source: ActivitySource.culturalAgenda,
      );
      expect(activityHasEnded(festival, now), isFalse);
    });

    test('Permanent plans never end', () {
      final permanent = Activity(
        id: 'p',
        title: 'Museu',
        category: 'Museus',
        municipality: 'Barcelona',
        startsAt: DateTime(2020, 1, 1),
        isPermanent: true,
        imageAsset: 'assets/images/jazz_al_parc.jpg',
        source: ActivitySource.culturalAgenda,
      );
      expect(activityHasEnded(permanent, now), isFalse);
    });
  });
}
