import '../../features/auth/presentation/cubit/auth_bloc.dart';
import '../../features/competition/domain/competition.model.dart';

extension CompetitionOwnership on Competition? {
  bool isOwnedBySession(AuthSessionState session) =>
      this?.isOwnedBy(session.user?.id) ?? false;
}
