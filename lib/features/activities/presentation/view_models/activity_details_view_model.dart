import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../repositories/activity_details_repository.dart';
import '../../../../core/l10n/locale_controller.dart';

class ActivityDetailsViewModel extends ChangeNotifier {
  ActivityDetailsViewModel({
    required this.activityId,
    required this._repository,
  });

  final String activityId;
  final ActivityDetailsRepository _repository;

  Activity? _activity;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  Activity? get activity => _activity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _activity = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActivityById(activityId);
      if (_isDisposed) return;
      _activity = result;
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = currentL10n.actLoadDetailError;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
