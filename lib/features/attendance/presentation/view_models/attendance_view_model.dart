import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../repositories/attendance_repository.dart';

/// The person's answers to «Com va anar?» (#64), shared by the Agenda and
/// the ratings: only who went can rate (R10).
class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({required this.userId, required this._repository});

  final String userId;
  final AttendanceRepository _repository;

  /// Answers read or given: true, false or null (not answered).
  final _answers = <String, bool?>{};
  final _loading = <String>{};
  final _answering = <String>{};
  final _errors = <String, String>{};

  /// «Més tard» during the current visit to the Agenda.
  final _postponed = <String>{};
  bool _isDisposed = false;

  /// Whether the answer of [activityId] is already known.
  bool isKnown(String activityId) => _answers.containsKey(activityId);

  /// True if the person said they went (only then can they rate).
  bool attended(String activityId) => _answers[activityId] == true;

  /// The question is still open and was not left for later.
  bool isPending(String activityId) =>
      isKnown(activityId) &&
      _answers[activityId] == null &&
      !_postponed.contains(activityId);

  bool isAnswering(String activityId) => _answering.contains(activityId);
  String? errorFor(String activityId) => _errors[activityId];

  /// Reads the answers not known yet. A failure leaves them unknown: the
  /// question is not shown rather than shown by mistake.
  Future<void> ensureLoaded(Iterable<String> activityIds) async {
    final missing = [
      for (final id in activityIds.toSet())
        if (!isKnown(id) && !_loading.contains(id)) id,
    ];
    if (missing.isEmpty || _isDisposed) return;
    _loading.addAll(missing);
    var changed = false;
    await Future.wait([
      for (final id in missing)
        () async {
          try {
            final answer = await _repository.getAttendance(
              userId: userId,
              activityId: id,
            );
            if (_isDisposed) return;
            _answers[id] = answer;
            changed = true;
          } catch (_) {
            // Asked again on the next visit.
          } finally {
            _loading.remove(id);
          }
        }(),
    ]);
    if (changed && !_isDisposed) notifyListeners();
  }

  /// Stores «Sí, hi vaig anar» (true) or «No hi vaig anar» (false). The
  /// card stays until the server confirms it.
  Future<bool> answer(String activityId, {required bool attended}) async {
    if (_isDisposed || _answering.contains(activityId)) return false;
    _answering.add(activityId);
    _errors.remove(activityId);
    notifyListeners();
    try {
      await _repository.setAttendance(
        userId: userId,
        activityId: activityId,
        attended: attended,
      );
      if (_isDisposed) return false;
      _answers[activityId] = attended;
      return true;
    } catch (_) {
      if (_isDisposed) return false;
      _errors[activityId] = currentL10n.attendanceSaveError;
      return false;
    } finally {
      if (!_isDisposed) {
        _answering.remove(activityId);
        notifyListeners();
      }
    }
  }

  /// «Més tard»: hides the question until the next visit to the Agenda.
  void postpone(String activityId) {
    if (_isDisposed || !_postponed.add(activityId)) return;
    _errors.remove(activityId);
    notifyListeners();
  }

  /// A new visit to the Agenda asks again what was left for later.
  void startVisit() {
    if (_isDisposed || _postponed.isEmpty) return;
    _postponed.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
