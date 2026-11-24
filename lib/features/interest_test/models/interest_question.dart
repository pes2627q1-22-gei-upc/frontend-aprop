/// An activity shown in the interest test.
class InterestQuestion {
  const InterestQuestion({
    required this.eventId,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.imageAsset,
    this.categories = const [],
  });

  final int eventId;
  final String title;
  final String description;
  final String? imageUrl;
  final String? imageAsset;
  final List<String> categories;
}

/// The user's answer to one [InterestQuestion].
class InterestAnswer {
  const InterestAnswer({required this.eventId, required this.likes});

  final int eventId;
  final bool likes;
}

/// Completion, onboarding prompt, and partial-progress state of the test.
class InterestTestStatus {
  const InterestTestStatus({
    required this.completed,
    required this.prompted,
    this.inProgress = false,
    this.answeredCount = 0,
    this.dateTaken,
  });

  final bool completed;
  final bool prompted;
  final bool inProgress;
  final int answeredCount;
  final DateTime? dateTaken;

  /// Whether onboarding should auto-open the test for this account.
  bool get shouldPromptOnboarding => !completed && !prompted && !inProgress;
}
