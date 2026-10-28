import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleActivity = Activity(
    id: 'demo-jazz',
    title: 'Jazz al parc',
    category: 'Música',
    municipality: 'Barcelona',
    startsAt: DateTime(2026, 9, 26, 19),
    imageAsset: 'assets/images/jazz_al_parc.jpg',
    source: ActivitySource.culturalAgenda,
  );

  test('TestR12_AssistantMessageAllowsRecommendationsOnlyFromAssistant', () {
    final assistantMsg = AssistantMessage.assistant(
      id: 'm-1',
      text: 'Et recomano aquest concert.',
      sentAt: DateTime(2026, 9, 26, 18),
      interpretation: const AssistantInterpretation(
        category: 'Música',
        municipality: 'Barcelona',
      ),
      recommendedActivities: [sampleActivity],
    );

    expect(assistantMsg.sender, AssistantMessageSender.assistant);
    expect(assistantMsg.recommendedActivities, [sampleActivity]);
    expect(
      () => assistantMsg.recommendedActivities.add(sampleActivity),
      throwsUnsupportedError,
    );

    expect(
      () => AssistantMessage(
        id: 'm-2',
        sender: AssistantMessageSender.user,
        text: 'Busco música',
        sentAt: DateTime(2026, 9, 26, 18),
        recommendedActivities: [sampleActivity],
      ),
      throwsArgumentError,
    );

    expect(
      () => AssistantMessage(
        id: 'm-3',
        sender: AssistantMessageSender.user,
        text: 'Busco música',
        sentAt: DateTime(2026, 9, 26, 18),
        interpretation: const AssistantInterpretation(category: 'Música'),
      ),
      throwsArgumentError,
    );
  });

  test('TestR12_AssistantMessageAllowsVoiceFlagOnlyForUser', () {
    final userVoiceMsg = AssistantMessage.user(
      id: 'u-1',
      text: 'Què puc fer avui?',
      sentAt: DateTime(2026, 9, 26, 18),
      isVoice: true,
    );
    expect(userVoiceMsg.isVoice, isTrue);

    expect(
      () => AssistantMessage(
        id: 'a-1',
        sender: AssistantMessageSender.assistant,
        text: 'Hola!',
        sentAt: DateTime(2026, 9, 26, 18),
        isVoice: true,
      ),
      throwsArgumentError,
    );
  });
}
