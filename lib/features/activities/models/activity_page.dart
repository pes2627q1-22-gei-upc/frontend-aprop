import 'activity.dart';

/// A catalogue page; [hasMore] describes the source, before local filtering.
class ActivityPage {
  ActivityPage({required Iterable<Activity> items, required this.hasMore})
    : items = List.unmodifiable(items);

  final List<Activity> items;
  final bool hasMore;
}
