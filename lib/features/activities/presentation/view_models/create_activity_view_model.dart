import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../models/activity_options.dart';
import '../../models/new_activity.dart';
import '../../repositories/activity_repository.dart';

enum CreateActivityField {
  title,
  description,
  category,
  startsAt,
  municipality,
  price,
}

const maxActivityTitleLength = 80;
const maxActivityDescriptionLength = 1000;
const maxActivityDirectionsLength = 200;
const createActivityErrorMessage =
    'No hem pogut publicar l’activitat. Torna-ho a provar.';

/// Formulari per publicar una activitat no oficial. Els textos arriben en
/// enviar el formulari; la categoria, la data i la imatge es trien amb
/// controls i es guarden aquí.
class CreateActivityViewModel extends ChangeNotifier {
  CreateActivityViewModel({
    required this._repository,
    required this._creator,
    this._now = DateTime.now,
  });

  final ActivityRepository _repository;
  final ActivityCreator _creator;
  final DateTime Function() _now;

  final Map<CreateActivityField, String> _fieldErrors = {};
  String? _category;
  DateTime? _startsAt;

  /// Sempre n'hi ha una: per defecte, la primera plantilla.
  String _imageAsset = activityImageTemplates.first;
  bool _isPublishing = false;
  bool _isDisposed = false;
  String? _errorMessage;

  String? get category => _category;
  DateTime? get startsAt => _startsAt;
  String get imageAsset => _imageAsset;
  bool get isPublishing => _isPublishing;
  String? get errorMessage => _errorMessage;
  String? fieldError(CreateActivityField field) => _fieldErrors[field];

  /// Data a partir de la qual es pot triar l'inici (avui).
  DateTime get today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
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

  void setImageAsset(String imageAsset) {
    _imageAsset = imageAsset;
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

  /// Retorna l'activitat creada, o `null` si el formulari no és vàlid o la
  /// publicació ha fallat.
  Future<Activity?> publish({
    required String title,
    required String description,
    required String municipality,
    required String price,
    String directions = '',
  }) async {
    if (_isPublishing || _isDisposed) return null;

    final parsedPrice = parseActivityPrice(price);
    final category = _category;
    final startsAt = _startsAt;
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
        CreateActivityField.municipality: ?(municipality.trim().isEmpty
            ? 'Introdueix el municipi.'
            : null),
        CreateActivityField.price: ?(parsedPrice == null
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
      return await _repository.createActivity(
        NewActivity(
          title: title.trim(),
          description: description.trim(),
          category: category!,
          startsAt: startsAt!,
          municipality: municipality.trim(),
          // Sense indicacions es desa nul, no un text buit.
          directions: directions.trim().isEmpty ? null : directions.trim(),
          imageAsset: _imageAsset,
          creator: _creator,
          price: parsedPrice,
        ),
      );
    } catch (_) {
      _errorMessage = createActivityErrorMessage;
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
