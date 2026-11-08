import '../../activities/models/activity.dart';

/// Identifies who authored a message in an assistant conversation (`MissatgeXatbot.emissor`).
enum AssistantMessageSender { user, assistant }

/// App screen an assistant reply suggests opening (`AssistantAction.screen`).
enum AssistantScreenTarget {
  home,
  agenda,
  discover,
  notifications,
  profile,
  settings,
  interestTest;

  /// Returns null for values this app does not handle.
  static AssistantScreenTarget? fromApi(Object? value) => switch (value) {
    'home' => home,
    'agenda' => agenda,
    'discover' => discover,
    'notifications' => notifications,
    'profile' => profile,
    'settings' => settings,
    'interest-test' => interestTest,
    _ => null,
  };
}

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
    this.action,
    this.rawSentAt,
    this.conversationStartedAt,
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
    if (sender != AssistantMessageSender.assistant && action != null) {
      throw ArgumentError('Only assistant messages can suggest a screen.');
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
    AssistantScreenTarget? action,
    String? rawSentAt,
    String? conversationStartedAt,
  }) {
    return AssistantMessage(
      id: id,
      sender: AssistantMessageSender.assistant,
      text: text,
      sentAt: sentAt,
      interpretation: interpretation,
      recommendedActivities: recommendedActivities,
      action: action,
      rawSentAt: rawSentAt,
      conversationStartedAt: conversationStartedAt,
    );
  }

  final String id;
  final AssistantMessageSender sender;
  final String text;
  final DateTime sentAt;
  final bool isVoice;
  final AssistantInterpretation? interpretation;
  final List<Activity> recommendedActivities;

  /// Screen the reply suggests opening; only on the reply just received.
  final AssistantScreenTarget? action;

  /// `sent-at` and conversation `started-at` exactly as the backend sent them.
  /// Together they identify the message for feedback; null when the message
  /// did not come from the backend (e.g. the local welcome text).
  final String? rawSentAt;
  final String? conversationStartedAt;

  bool get canRate =>
      sender == AssistantMessageSender.assistant &&
      (rawSentAt?.isNotEmpty ?? false) &&
      (conversationStartedAt?.isNotEmpty ?? false);
}
