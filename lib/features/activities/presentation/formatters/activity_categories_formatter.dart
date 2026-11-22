import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';
import '../../models/activity_category_labels.dart';

/// «Música», o «Música +2» si l'activitat en té més (la primera fa de
/// distintiu, com a les targetes). Si hi ha un filtre de categories actiu,
/// prioritza la categoria que hi coincideix.
String activityCategoriesLabel(
  Activity activity, {
  Iterable<String> activeFilterCategories = const [],
  String? languageCode,
}) {
  final lang = languageCode ?? currentL10n.localeName;
  final ordered = orderActivityCategoriesForFilter(
    activity.categories,
    activeFilterCategories,
  );
  final primary = ordered.isNotEmpty ? ordered.first : activity.category;
  final label = localizeActivityCategory(primary, languageCode: lang);
  final more = ordered.length - 1;
  return more > 0 ? '$label +$more' : label;
}
