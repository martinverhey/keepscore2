import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../domain/competition.model.dart';
import '../../domain/competition_repository.dart';
import 'competition_list_state.dart';

export 'competition_list_state.dart';

class CompetitionListCubit extends Cubit<CompetitionListState> {
  CompetitionListCubit(this._repository, this._authBloc)
    : super(const CompetitionListLoading()) {
    _authSubscription = _authBloc.stream.listen(_onSession);
  }

  final CompetitionRepository _repository;
  final AuthBloc _authBloc;

  late final StreamSubscription<AuthSessionState> _authSubscription;

  Future<void>? _inFlight;

  CompetitionListReady? get _ready => switch (state) {
    CompetitionListReady ready => ready,
    _ => null,
  };

  Future<void> ensureLoaded() {
    if (_ready != null) return Future.value();
    return _inFlight ??= load().whenComplete(() => _inFlight = null);
  }

  bool isMember(String competitionId) => _find(competitionId) != null;

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const CompetitionListLoading());
    try {
      final competitions = await _repository.myCompetitions();
      if (isClosed) return;
      emit(CompetitionListReady(competitions: competitions));
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(CompetitionListFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<bool> rename(String competitionId, String name) => _mutate(() async {
    final overview = _find(competitionId);
    if (overview == null) return;
    final competition = overview.competition;
    await _repository.updateSettings(
      competitionId: competitionId,
      name: name,
      seasonLength: competition.seasonLength,
      kFactor: competition.kFactor,
      movEnabled: competition.movEnabled,
      movCap: competition.movCap,
      allowDraws: competition.allowDraws,
    );
  });

  Future<bool> leave(String competitionId) =>
      _mutate(() => _repository.leave(competitionId));

  Future<bool> delete(String competitionId) =>
      _mutate(() => _repository.delete(competitionId));

  CompetitionOverview? _find(String competitionId) {
    final ready = _ready;
    if (ready == null) return null;
    for (final overview in ready.competitions) {
      if (overview.id == competitionId) return overview;
    }
    return null;
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    final ready = _ready;
    if (ready == null || ready.busy) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));
    try {
      await action();
      if (isClosed) return true;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
      await refresh();
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, actionFailure: failure));
      }
      return false;
    }
  }

  void _onSession(AuthSessionState session) {
    if (session.isAuthenticated) return;
    _inFlight = null;
    emit(const CompetitionListLoading());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
