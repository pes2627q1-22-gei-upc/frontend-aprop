import 'package:flutter/foundation.dart';

import '../../models/discovery_feed.dart';
import '../../repositories/discovery_repository.dart';
import '../../../../core/l10n/locale_controller.dart';

class DiscoverViewModel extends ChangeNotifier {
  DiscoverViewModel({required this.repository, required this.userId});

  final DiscoveryRepository repository;
  final String userId;
  DiscoveryFeed? _feed;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  DiscoveryFeed? get feed => _feed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getFeed(userId: userId);
      if (!_isDisposed) {
        final previous = _feed;
        _feed = previous == null || !result.hasErrors
            ? result
            : DiscoveryFeed(
                recommended: result.recommendationsUnavailable
                    ? previous.recommended
                    : result.recommended,
                featured: result.featuredUnavailable
                    ? previous.featured
                    : result.featured,
                isPersonalized: result.recommendationsUnavailable
                    ? previous.isPersonalized
                    : result.isPersonalized,
                recommendationAvailability: result.recommendationAvailability,
                featuredUnavailable: result.featuredUnavailable,
              );
      }
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = currentL10n.discoverLoadError;
      }
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
