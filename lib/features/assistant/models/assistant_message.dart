import '../../activities/models/activity.dart';

/// Identifies who authored a message in an assistant conversation (`MissatgeXatbot.emissor`).
enum AssistantMessageSender { user, assistant }

/// Structured search parameters extracted by the assistant from a natural-language query.
class AssistantInterpretation {
  const AssistantInterpretation({
    this.category,
    this.municipality,
    this.dateRange,
  });

  final String? category;
  final String? municipality;
  final String? dateRange;

  bool get hasAny =>
      category != null || municipality != null || dateRange != null;
}

/// A single message in an assistant conversation (`MissatgeXatbot`).
///
/// Enforces domain restriction R12:
/// - Only messages with `sender == AssistantMessageSender.assistant` may recommend activities.
/// - Only messages with `sender == AssistantMessageSender.user` may have `isVoice == true`.
class AssistantMessage {
  AssistantMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.isVoice = false,
    this.interpretation,
    List<Activity> recommendedActivities = const [],
  }) : recommendedActivities = List.unmodifiable(recommendedActivities) {
    if (sender != AssistantMessageSender.assistant &&
        this.recommendedActivities.isNotEmpty) {
      throw ArgumentError(
        'R12 violation: only assistant messages can recommend activities.',
      );
    }
    if (sender != AssistantMessageSender.assistant && interpretation != null) {
      throw ArgumentError(
        'Only assistant messages can include a query interpretation.',
      );
    }
    if (sender != AssistantMessageSender.user && isVoice) {
      throw ArgumentError(
        'R12 violation: only user messages can be sent by voice.',
      );
    }
  }

  factory AssistantMessage.user({
    required String id,
    required String text,
    required DateTime sentAt,
    bool isVoice = false,
  }) {
    return AssistantMessage(
      id: id,
      sender: AssistantMessageSender.user,
      text: text,
      sentAt: sentAt,
      isVoice: isVoice,
    );
  }

  factory AssistantMessage.assistant({
    required String id,
    required String text,
    required DateTime sentAt,
    AssistantInterpretation? interpretation,
    List<Activity> recommendedActivities = const [],
  }) {
    return AssistantMessage(
      id: id,
      sender: AssistantMessageSender.assistant,
      text: text,
      sentAt: sentAt,
      interpretation: interpretation,
      recommendedActivities: recommendedActivities,
    );
  }

  final String id;
  final AssistantMessageSender sender;
  final String text;
  final DateTime sentAt;
  final bool isVoice;
  final AssistantInterpretation? interpretation;
  final List<Activity> recommendedActivities;
}
