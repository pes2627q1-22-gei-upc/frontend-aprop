import '../models/activity_category.dart';

abstract interface class ActivityCategoryRepository {
  /// Categories que es poden triar en crear una activitat. Llança una
  /// excepció si no s'han pogut carregar.
  Future<List<ActivityCategory>> getCreationCategories();
}
