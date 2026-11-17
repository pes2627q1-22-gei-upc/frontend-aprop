import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../models/activity_category.dart';
import '../../models/activity_options.dart';
import '../../models/geo_point.dart';
import '../../models/new_activity.dart';
import '../../repositories/activity_category_repository.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/location_repository.dart';

enum CreateActivityField {
  title,
  description,
  category,
  startsAt,
  endsAt,
  price,
}

const maxActivityTitleLength = 80;
const maxActivityDescriptionLength = 1000;
const maxActivityDirectionsLength = 200;
const createActivityErrorMessage =
    'No hem pogut publicar l’activitat. Torna-ho a provar.';
const updateActivityErrorMessage =
    'No hem pogut desar els canvis. Torna-ho a provar.';

/// Formulari per publicar una activitat no oficial, o per editar-ne una amb
/// [editing]. Els textos arriben en enviar el formulari; la categoria, la
/// data i la imatge es trien amb controls i es guarden aquí.
class CreateActivityViewModel extends ChangeNotifier {
  CreateActivityViewModel({
    required this._repository,
    required this._locationRepository,
    required this._creator,
    this._categoryRepository,
    this._now = DateTime.now,
    this.editing,
  }) : _categories = _categoryRepository == null
           ? [
               for (final name in activityCategories)
                 ActivityCategory.plain(name),
             ]
           : const [] {
    final activity = editing;
    if (activity == null) return;
    // Fins que no arriben les categories, es guarda el nom que es veu.
    _category = activity.category;
    _matchEditedCategory();
    _startsAt = activity.startsAt;
    _endsAt = activity.endsAt;
    if (activityImageTemplates.contains(activity.imageAsset)) {
      _imageAsset = activity.imageAsset;
    }
    _location = activity.location;
    // El lloc ja estava triat: escriure el municipi no el mou.
    _locationAdjusted = activity.location != null;
  }

  /// L'activitat que s'edita; nul si se'n crea una de nova.
  final Activity? editing;

  bool get isEditing => editing != null;

  final ActivityRepository _repository;

  /// D'on surten les categories. Si és nul, es fa servir la llista provisional.
  final ActivityCategoryRepository? _categoryRepository;
  final LocationRepository _locationRepository;
  final ActivityCreator _creator;
  final DateTime Function() _now;

  final Map<CreateActivityField, String> _fieldErrors = {};
  String? _category;
  DateTime? _startsAt;
  DateTime? _endsAt;

  /// Sempre n'hi ha una: per defecte, la primera plantilla.
  String _imageAsset = activityImageTemplates.first;

  /// Punt del marcador al mapa. Es posa al centre del municipi quan se'l
  /// troba, i l'usuari el pot ajustar.
  GeoPoint? _location;
  GeoPoint? _municipalityCenter;
  bool _locationAdjusted = false;
  int _lookupRequest = 0;
  bool _isPublishing = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<ActivityCategory> _categories;
  bool _isLoadingCategories = false;
  String? _categoriesError;

  /// Valor de la categoria triada (`ActivityCategory.value`).
  String? get category => _category;
  List<ActivityCategory> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  DateTime? get startsAt => _startsAt;
  DateTime? get endsAt => _endsAt;
  String get imageAsset => _imageAsset;
  GeoPoint? get location => _location;

  /// `true` si el marcador és al centre del municipi trobat i encara no
  /// s'ha ajustat.
  bool get isLocationApproximate =>
      _location != null && _location == _municipalityCenter;
  bool get isPublishing => _isPublishing;
  String? get errorMessage => _errorMessage;
  String? fieldError(CreateActivityField field) => _fieldErrors[field];

  /// Data a partir de la qual es pot triar l'inici (avui).
  DateTime get today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Carrega les categories del repositori, si n'hi ha. També serveix per
  /// tornar-ho a provar.
  Future<void> loadCategories() async {
    final repository = _categoryRepository;
    if (repository == null || _isLoadingCategories || _isDisposed) return;

    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      final categories = await repository.getCreationCategories();
      if (_isDisposed) return;
      _categories = List.unmodifiable(categories);
      _matchEditedCategory();
    } catch (_) {
      if (_isDisposed) return;
      _categoriesError = 'No hem pogut carregar les categories.';
    } finally {
      if (!_isDisposed) {
        _isLoadingCategories = false;
        notifyListeners();
      }
    }
  }

  /// L'activitat editada només en sap el nom que es veu («Teatre»); el
  /// formulari desa el valor («agenda:categories/teatre»). Si cap categoria
  /// no hi correspon, no se'n tria cap: enviar el nom en crearia una de nova.
  void _matchEditedCategory() {
    final name = editing?.category;
    if (name == null || _categories.isEmpty) return;
    if (_categories.any((c) => c.value == _category)) return;
    _category = _categories
        .where((c) => c.label.toLowerCase() == name.toLowerCase())
        .firstOrNull
        ?.value;
  }

  void setCategory(String? category) {
    _category = category;
    _fieldErrors.remove(CreateActivityField.category);
    _errorMessage = null;
    notifyListeners();
  }

  void setStartsAt(DateTime startsAt) {
    _startsAt = startsAt;
    _fieldErrors.remove(CreateActivityField.startsAt);
    _errorMessage = null;
    notifyListeners();
  }

  /// La data de fi és opcional: amb `null` es treu.
  void setEndsAt(DateTime? endsAt) {
    _endsAt = endsAt;
    _fieldErrors.remove(CreateActivityField.endsAt);
    _errorMessage = null;
    notifyListeners();
  }

  void setImageAsset(String imageAsset) {
    _imageAsset = imageAsset;
    notifyListeners();
  }

  /// Busca el municipi escrit per centrar-hi el mapa. Si el troba i és un
  /// municipi nou, hi mou el marcador; si no el troba, el marcador es queda on
  /// l'usuari l'hagi posat.
  Future<void> locateMunicipality(String name) async {
    // Si arriben respostes desordenades, només val la de l'última petició.
    final request = ++_lookupRequest;
    final center = name.trim().isEmpty
        ? null
        : await _locationRepository.findMunicipality(name);
    if (_isDisposed || request != _lookupRequest) return;

    if (center == null) {
      _municipalityCenter = null;
      if (!_locationAdjusted) _location = null;
    } else if (center != _municipalityCenter) {
      _municipalityCenter = center;
      _location = center;
      _locationAdjusted = false;
    } else {
      return;
    }
    notifyListeners();
  }

  /// L'usuari ha tocat el mapa o ha arrossegat el marcador.
  void setLocation(GeoPoint location) {
    _location = location;
    _locationAdjusted = true;
    notifyListeners();
  }

  /// L'usuari ha modificat un camp de text: en treu l'error i el missatge
  /// general. Es tornaran a comprovar en publicar.
  void onFieldChanged(CreateActivityField field) {
    final hadFieldError = _fieldErrors.remove(field) != null;
    if (!hadFieldError && _errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna l'activitat creada o editada, o `null` si el formulari no és
  /// vàlid o no s'ha pogut desar. El municipi i les indicacions són opcionals.
  Future<Activity?> publish({
    required String title,
    required String description,
    required String price,
    String municipality = '',
    String directions = '',
  }) async {
    if (_isPublishing || _isDisposed) return null;

    // El backend no desa l'import: d'una activitat de pagament no se'n sap.
    // Si el camp es deixa buit, no es converteix en gratuïta.
    final keepsUnknownPrice =
        isEditing && editing!.price == null && price.trim().isEmpty;
    final parsedPrice = keepsUnknownPrice ? null : parseActivityPrice(price);
    final category = _category;
    final startsAt = _startsAt;
    final endsAt = _endsAt;
    _errorMessage = null;
    _fieldErrors
      ..clear()
      // `?` només afegeix l'entrada si la comprovació retorna un error.
      ..addAll({
        CreateActivityField.title: ?_validateTitle(title),
        CreateActivityField.description: ?_validateDescription(description),
        CreateActivityField.category: ?(category == null
            ? 'Tria una categoria.'
            : null),
        CreateActivityField.startsAt: ?_validateStartsAt(startsAt),
        CreateActivityField.endsAt: ?_validateEndsAt(startsAt, endsAt),
        CreateActivityField.price: ?(parsedPrice == null && !keepsUnknownPrice
            ? 'Introdueix un preu vàlid, per exemple 12,50.'
            : null),
      });

    if (_fieldErrors.isNotEmpty) {
      notifyListeners();
      return null;
    }

    _isPublishing = true;
    notifyListeners();

    try {
      final activity = NewActivity(
        title: title.trim(),
        description: description.trim(),
        category: category!,
        startsAt: startsAt!,
        endsAt: endsAt,
        municipality: municipality.trim(),
        // Sense indicacions es desa nul, no un text buit.
        directions: directions.trim().isEmpty ? null : directions.trim(),
        imageAsset: _imageAsset,
        location: _location,
        creator: _creator,
        price: parsedPrice,
      );
      return await switch (editing) {
        final edited? => _repository.updateActivity(edited.id, activity),
        null => _repository.createActivity(activity),
      };
    } catch (_) {
      _errorMessage = isEditing
          ? updateActivityErrorMessage
          : createActivityErrorMessage;
      return null;
    } finally {
      if (!_isDisposed) {
        _isPublishing = false;
        notifyListeners();
      }
    }
  }

  String? _validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Introdueix el títol.';
    if (trimmed.length > maxActivityTitleLength) {
      return 'Màxim $maxActivityTitleLength caràcters.';
    }
    return null;
  }

  String? _validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return 'Introdueix una descripció.';
    if (trimmed.length > maxActivityDescriptionLength) {
      return 'Màxim $maxActivityDescriptionLength caràcters.';
    }
    return null;
  }

  /// Criteri de Taiga: l'inici no pot ser anterior a la creació.
  String? _validateStartsAt(DateTime? startsAt) {
    if (startsAt == null) return 'Tria la data i l’hora d’inici.';
    if (!startsAt.isAfter(_now())) return 'L’inici ha de ser posterior a ara.';
    return null;
  }

  /// R5: la fi no pot ser anterior a l'inici. Es demana que sigui posterior,
  /// perquè si acaba quan comença no cal indicar-la.
  String? _validateEndsAt(DateTime? startsAt, DateTime? endsAt) {
    if (startsAt == null || endsAt == null || endsAt.isAfter(startsAt)) {
      return null;
    }
    return 'La fi ha de ser posterior a l’inici.';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

final _pricePattern = RegExp(r'^\d+([.,]\d{1,2})?$');

/// Converteix el text del camp de preu en euros. Buit vol dir gratuïta (0).
/// Retorna `null` si el text no és un import vàlid.
double? parseActivityPrice(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  if (!_pricePattern.hasMatch(trimmed)) return null;
  return double.parse(trimmed.replaceAll(',', '.'));
}
