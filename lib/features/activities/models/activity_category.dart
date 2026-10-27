/// Categoria que es pot triar en crear una activitat.
class ActivityCategory {
  const ActivityCategory({required this.value, required this.label});

  /// Sense backend, el nom és també el valor que es desa.
  const ActivityCategory.plain(String name) : this(value: name, label: name);

  /// El que es desa a l'activitat, com `agenda:categories/teatre`.
  final String value;

  /// El que veu l'usuari, com «Teatre».
  final String label;
}
