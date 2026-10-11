enum ActivitySource { culturalAgenda, community }

class ActivityCreator {
  const ActivityCreator({
    required this.name,
    required this.avatarAsset,
    required this.isFriend,
  });

  final String name;
  final String avatarAsset;
  final bool isFriend;
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.municipality,
    required this.startsAt,
    required this.imageAsset,
    required this.source,
    this.creator,
  });

  final String id;
  final String title;
  final String category;
  final String municipality;
  final DateTime startsAt;
  final String imageAsset;
  final ActivitySource source;
  final ActivityCreator? creator;
}
