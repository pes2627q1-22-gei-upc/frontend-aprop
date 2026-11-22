import 'package:flutter/foundation.dart';

import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';
import '../../models/activity_category.dart';
import '../../models/activity_category_labels.dart';
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
String get createActivityErrorMessage => currentL10n.createPublishError;
String get updateActivityErrorMessage => currentL10n.createUpdateError;

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
    // El backend només desa el dia (DP-029): l'hora es recupera de l'«Horari»
    // que es va generar en crear-la.
    final time = parseActivityScheduleTime(activity.schedule ?? '');
    _startsAt = _atScheduleTime(activity.startsAt, time?.start);
    final end = _atScheduleTime(
      activity.endsAt ?? activity.startsAt,
      time?.end,
    );
    _endsAt = time?.end != null && end.isAfter(_startsAt!)
        ? end
        : activity.endsAt;
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

  /// S'edita una activitat de la qual no se sap el preu (DP-017): deixar el
  /// camp buit el manté desconegut, i per fer-la gratuïta cal escriure 0.
  bool get hasUnknownPrice => editing != null && editing!.price == null;

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
    final schedule = editing?.schedule?.trim() ?? '';
    // Un horari escrit d'una altra manera es conserva sencer com a nota.
    return parseActivityScheduleTime(schedule)?.note ?? schedule;
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
      _categoriesError = currentL10n.actLoadCategoriesError;
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
                  canonicalActivityCategoryKey(c.label) ==
                      canonicalActivityCategoryKey(name),
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
      _fieldErrors[CreateActivityField.category] = currentL10n
          .createCategoriesMax(maxActivityCategories);
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
    final keepsUnknownPrice = hasUnknownPrice && price.trim().isEmpty;
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
            ? currentL10n.createCategoryRequired
            : null),
        CreateActivityField.onlineUrl: ?(isOnline && link.isNotEmpty
            ? _validateOnlineUrl(link)
            : null),
        CreateActivityField.startsAt: ?_validateStartsAt(startsAt),
        CreateActivityField.endsAt: ?_validateEndsAt(startsAt, endsAt),
        CreateActivityField.price: ?(parsedPrice == null && !keepsUnknownPrice
            ? currentL10n.createPriceInvalid
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
    if (trimmed.isEmpty) return currentL10n.createTitleRequired;
    if (trimmed.length > maxActivityTitleLength) {
      return currentL10n.createMaxChars(maxActivityTitleLength);
    }
    return null;
  }

  String? _validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return currentL10n.createDescriptionRequired;
    if (trimmed.length > maxActivityDescriptionLength) {
      return currentL10n.createMaxChars(maxActivityDescriptionLength);
    }
    return null;
  }

  /// Criteri de Taiga: l'inici no pot ser anterior a la creació.
  String? _validateStartsAt(DateTime? startsAt) {
    if (startsAt == null) return currentL10n.createStartRequired;
    if (!startsAt.isAfter(_now())) return currentL10n.startSheetError;
    return null;
  }

  /// R5: la fi no pot ser anterior a l'inici. Es demana que sigui posterior,
  /// perquè si acaba quan comença no cal indicar-la.
  String? _validateEndsAt(DateTime? startsAt, DateTime? endsAt) {
    if (startsAt == null || endsAt == null || endsAt.isAfter(startsAt)) {
      return null;
    }
    return currentL10n.endSheetError;
  }

  String? _validateOnlineUrl(String link) {
    final uri = Uri.tryParse(link);
    final valid =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    return valid ? null : currentL10n.createOnlineUrlInvalid;
  }

  /// L'«Horari» que es desa: l'hora de les rodes i, si n'hi ha, la nota.
  /// El backend no desa l'hora de l'inici (DP-029).
  // TODO(DP-059): l'hora es guarda dins de l'«Horari» en text.
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

/// «19.00 h», o «19.00 h – 21.00 h» si acaba el mateix dia, en el format
/// d'hora de l'idioma actiu.
String activityScheduleTime(DateTime start, DateTime? end) {
  final sameDay =
      end != null &&
      end.year == start.year &&
      end.month == start.month &&
      end.day == start.day;
  return sameDay ? '${timeOfDay(start)} – ${timeOfDay(end)}' : timeOfDay(start);
}

/// L'hora d'inici (i, si n'hi ha, de fi) amb què comença un «Horari» generat
/// per [activityScheduleTime], en qualsevol dels formats d'hora de l'app
/// («19.00 h», «19:00 h», «19:00»), i el text que la segueix. Nul si l'horari
/// no comença amb una hora seguida del final o del separador.
({({int hour, int minute}) start, ({int hour, int minute})? end, String note})?
parseActivityScheduleTime(String schedule) {
  final match = _scheduleTimePattern.firstMatch(schedule.trim());
  if (match == null) return null;
  ({int hour, int minute})? clock(String? hour, String? minute) {
    if (hour == null || minute == null) return null;
    final h = int.parse(hour);
    final m = int.parse(minute);
    return h < 24 && m < 60 ? (hour: h, minute: m) : null;
  }

  final start = clock(match.group(1), match.group(2));
  if (start == null) return null;
  return (
    start: start,
    end: clock(match.group(3), match.group(4)),
    note: schedule.trim().substring(match.end).trim(),
  );
}

final _scheduleTimePattern = RegExp(
  r'^(\d{1,2})[.:](\d{2})(?:\s*h)?'
  r'(?:\s*[–-]\s*(\d{1,2})[.:](\d{2})(?:\s*h)?)?'
  r'(?:\s*·\s*|$)',
);

/// [date] a l'hora [time] si no en tenia (mitjanit, DP-029).
DateTime _atScheduleTime(DateTime date, ({int hour, int minute})? time) {
  final isMidnight = date.hour == 0 && date.minute == 0;
  if (time == null || !isMidnight) return date;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
