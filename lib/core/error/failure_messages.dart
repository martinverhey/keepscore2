import '../../l10n/app_localizations.dart';
import 'failure.dart';

extension FailureMessage on Failure {
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    AuthFailure(:final message) =>
      message.isEmpty ? l10n.errorSignedOut : message,
    PermissionFailure() => l10n.errorNotAuthorized,
    ValidationFailure(:final message) =>
      message.isEmpty ? l10n.errorGeneric : message,
    UnknownFailure() => l10n.errorGeneric,
  };
}
