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
