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
  onlineUrl,
}

const maxActivityTitleLength = 80;
const maxActivityDescriptionLength = 1000;
const maxActivityDirectionsLength = 200;
const maxActivityCategories = 3;
const maxActivityScheduleNoteLength = 120;
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
    // Fins que no arriben les categories, es guarden els noms que es veuen.
    _selectedCategories = List.of(activity.categories);
    _matchEditedCategories();
    _modality = activity.modality ?? ActivityModality.inPerson;
    _isPermanent = activity.isPermanent;
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

  /// Valors de les categories triades, en l'ordre en què s'han triat: la
  /// primera fa de distintiu.
  List<String> _selectedCategories = [];
  ActivityModality _modality = ActivityModality.inPerson;
  bool _isPermanent = false;
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

  /// Valors (`ActivityCategory.value`) de les categories triades.
  List<String> get selectedCategories => List.unmodifiable(_selectedCategories);

  /// La primera categoria triada, la que fa de distintiu.
  String? get category => _selectedCategories.firstOrNull;
  ActivityModality get modality => _modality;
  bool get isPermanent => _isPermanent;

  /// En editar, el text que s'havia afegit a l'horari generat («Durada: 1
  /// h»), perquè el formulari el torni a mostrar.
  String get initialScheduleNote {
    final activity = editing;
    final schedule = activity?.schedule?.trim();
    if (activity == null || schedule == null) return '';
    final generated = activityScheduleTime(activity.startsAt, activity.endsAt);
    if (schedule == generated) return '';
    final prefix = '$generated$_scheduleSeparator';
    // Un horari escrit d'una altra manera es conserva sencer com a nota.
    return schedule.startsWith(prefix)
        ? schedule.substring(prefix.length)
        : schedule;
  }

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
      _matchEditedCategories();
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

  /// L'activitat editada només en sap els noms que es veuen («Teatre»); el
  /// formulari desa els valors («agenda:categories/teatre»). Les que no hi
  /// corresponen es treuen: enviar el nom en crearia una categoria nova.
  void _matchEditedCategories() {
    if (editing == null || _categories.isEmpty) return;
    _selectedCategories = {
      for (final name in _selectedCategories)
        ?_categories
            .where(
              (c) =>
                  c.value == name ||
                  c.label.toLowerCase() == name.toLowerCase(),
            )
            .firstOrNull
            ?.value,
    }.take(maxActivityCategories).toList();
  }

  /// Tria només [category] (o cap, si és nul).
  void setCategory(String? category) {
    _selectedCategories = [?category];
    _fieldErrors.remove(CreateActivityField.category);
    _errorMessage = null;
    notifyListeners();
  }

  /// Afegeix o treu [category]. N'hi pot haver fins a [maxActivityCategories].
  void toggleCategory(String category) {
    _errorMessage = null;
    if (_selectedCategories.contains(category)) {
      _selectedCategories = [
        for (final selected in _selectedCategories)
          if (selected != category) selected,
      ];
      _fieldErrors.remove(CreateActivityField.category);
    } else if (_selectedCategories.length >= maxActivityCategories) {
      _fieldErrors[CreateActivityField.category] =
          'Pots triar fins a $maxActivityCategories categories.';
    } else {
      _selectedCategories = [..._selectedCategories, category];
      _fieldErrors.remove(CreateActivityField.category);
    }
    notifyListeners();
  }

  void setModality(ActivityModality modality) {
    _modality = modality;
    if (modality == ActivityModality.inPerson) {
      _fieldErrors.remove(CreateActivityField.onlineUrl);
    }
    notifyListeners();
  }

  void setPermanent(bool isPermanent) {
    _isPermanent = isPermanent;
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
    String scheduleNote = '',
    String onlineUrl = '',
  }) async {
    if (_isPublishing || _isDisposed) return null;

    // El backend no desa l'import: d'una activitat de pagament no se'n sap.
    // Si el camp es deixa buit, no es converteix en gratuïta.
    final keepsUnknownPrice =
        isEditing && editing!.price == null && price.trim().isEmpty;
    final parsedPrice = keepsUnknownPrice ? null : parseActivityPrice(price);
    final categories = _selectedCategories;
    final isOnline = _modality != ActivityModality.inPerson;
    final link = onlineUrl.trim();
    final startsAt = _startsAt;
    final endsAt = _endsAt;
    _errorMessage = null;
    _fieldErrors
      ..clear()
      // `?` només afegeix l'entrada si la comprovació retorna un error.
      ..addAll({
        CreateActivityField.title: ?_validateTitle(title),
        CreateActivityField.description: ?_validateDescription(description),
        CreateActivityField.category: ?(categories.isEmpty
            ? 'Tria una categoria.'
            : null),
        CreateActivityField.onlineUrl: ?(isOnline && link.isNotEmpty
            ? _validateOnlineUrl(link)
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
        categories: categories,
        startsAt: startsAt!,
        endsAt: endsAt,
        municipality: municipality.trim(),
        // Sense indicacions es desa nul, no un text buit.
        directions: directions.trim().isEmpty ? null : directions.trim(),
        imageAsset: _imageAsset,
        location: _location,
        creator: _creator,
        price: parsedPrice,
        schedule: _scheduleFor(startsAt, endsAt, scheduleNote),
        modality: _modality,
        isPermanent: _isPermanent,
        onlineUrl: isOnline && link.isNotEmpty ? link : null,
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

  String? _validateOnlineUrl(String link) {
    final uri = Uri.tryParse(link);
    final valid =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Introdueix un enllaç que comenci per https://.';
  }

  /// L'«Horari» que es desa: l'hora de les rodes i, si n'hi ha, la nota.
  /// El backend no desa l'hora de l'inici (DP-029).
  // TODO(DP-051): l'hora es guarda dins de l'«Horari» en text.
  static String _scheduleFor(DateTime start, DateTime? end, String note) {
    final time = activityScheduleTime(start, end);
    final extra = note.trim();
    return extra.isEmpty ? time : '$time$_scheduleSeparator$extra';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

const _scheduleSeparator = ' · ';

/// «19.00 h», o «19.00 – 21.00 h» si acaba el mateix dia.
String activityScheduleTime(DateTime start, DateTime? end) {
  String clock(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}.'
      '${date.minute.toString().padLeft(2, '0')}';
  final sameDay =
      end != null &&
      end.year == start.year &&
      end.month == start.month &&
      end.day == start.day;
  return sameDay ? '${clock(start)} – ${clock(end)} h' : '${clock(start)} h';
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
