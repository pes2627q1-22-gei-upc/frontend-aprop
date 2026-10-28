import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/assistant/data/demo_assistant_repository.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoAssistantRepository repository;

  setUp(() {
    repository = DemoAssistantRepository(
      activityRepository: DemoActivityRepository(),
      clock: () => DateTime(2026, 9, 26, 12),
    );
  });

  test('Interprets category, municipality and date range and returns matching activities', () async {
    final reply = await repository.sendMessage(
      'Vull anar a veure teatre a Tarragona el 27 de setembre',
    );

    expect(reply.sender, AssistantMessageSender.assistant);
    expect(reply.interpretation?.category, 'Teatre');
    expect(reply.interpretation?.municipality, 'Tarragona');
    expect(reply.interpretation?.dateRange, '27 set. 2026');
    expect(reply.recommendedActivities.map((a) => a.id).toList(), [
      'demo-theatre',
    ]);
    expect(reply.text, contains('tipus: teatre'));
    expect(reply.text, contains('municipi: Tarragona'));
    expect(reply.text, contains('dates: 27 set. 2026'));
  });

  test(
    'Interprets weekend range and returns matching weekend activities',
    () async {
      final reply = await repository.sendMessage(
        'Què puc fer aquest cap de setmana?',
      );

      expect(reply.interpretation?.dateRange, '26–27 set. 2026');
      expect(reply.recommendedActivities.length, 3);
    },
  );

  test(
    'Returns clear message and empty list when no activity matches criteria',
    () async {
      final reply = await repository.sendMessage('Busco cinema a Lleida');

      expect(reply.interpretation?.category, 'Cinema');
      expect(reply.interpretation?.municipality, 'Lleida');
      expect(reply.recommendedActivities, isEmpty);
      expect(
        reply.text,
        contains('No he trobat cap activitat que coincideixi'),
      );
    },
  );

  test(
    'Returns general catalogue suggestions when no specific filter is detected',
    () async {
      final reply = await repository.sendMessage('Hola, recomana’m plans');

      expect(reply.interpretation, isNull);
      expect(reply.recommendedActivities.length, 3);
      expect(
        reply.text,
        contains('Aquí tens algunes propostes culturals destacades'),
      );
    },
  );
}
