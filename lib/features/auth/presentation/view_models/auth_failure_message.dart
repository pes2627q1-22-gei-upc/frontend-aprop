import '../../models/auth_failure.dart';
import '../../../../core/l10n/locale_controller.dart';

String get unexpectedAuthErrorMessage => currentL10n.authUnexpectedError;

extension AuthFailureMessage on AuthFailure {
  String get message => switch (this) {
    AuthFailure.invalidCredentials => currentL10n.authInvalidCredentials,
    AuthFailure.emailAlreadyInUse => currentL10n.authEmailInUse,
    AuthFailure.usernameAlreadyInUse => currentL10n.authUsernameInUse,
    AuthFailure.network => currentL10n.authNetworkError,
    AuthFailure.tooManyRequests => currentL10n.authTooManyRequests,
    AuthFailure.emailRequired => currentL10n.authEmailRequired,
    AuthFailure.popupBlocked => currentL10n.authPopupBlocked,
  };
}
