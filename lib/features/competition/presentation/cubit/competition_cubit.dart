import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/competition_repository.dart';
import 'competition_state.dart';

export 'competition_state.dart';

class CompetitionCubit extends Cubit<CompetitionState> {
  CompetitionCubit(this._repository, this._authBloc)
    : super(const CompetitionLoading()) {
    _authSubscription = _authBloc.stream.listen(_onSession);
  }

  final CompetitionRepository _repository;
  final AuthBloc _authBloc;

  late final StreamSubscription<AuthSessionState> _authSubscription;

  String? _competitionId;

  String? get competitionId => _competitionId;

  CompetitionReady? get _ready => switch (state) {
    CompetitionReady ready => ready,
    _ => null,
  };

  Future<void> select(String competitionId) {
    if (competitionId == _competitionId) return refresh();
    _competitionId = competitionId;
    return load();
  }

  void clearIfSelected(String competitionId) {
    if (competitionId != _competitionId) return;
    _clear();
  }

  Future<void> load({bool silent = false}) async {
    final competitionId = _competitionId;
    if (competitionId == null) return;

    final ready = _ready;
    if (!silent) emit(const CompetitionLoading());
    try {
      final overview = await _repository.overview(competitionId);
      if (isClosed || competitionId != _competitionId) return;
      emit(
        overview == null
            ? const CompetitionMissing()
            : CompetitionReady(overview),
      );
    } on Failure catch (failure) {
      if (isClosed || competitionId != _competitionId) return;
      if (silent && ready != null) return;
      emit(CompetitionFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  void _onSession(AuthSessionState session) {
    if (session.isAuthenticated) return;
    _clear();
  }

  void _clear() {
    _competitionId = null;
    emit(const CompetitionLoading());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
