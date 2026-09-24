import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../player/domain/player_repository.dart';
import '../../domain/tournament_repository.dart';
import 'start_tournament_state.dart';

export 'start_tournament_state.dart';

class StartTournamentCubit extends Cubit<StartTournamentState> {
  StartTournamentCubit(
    this._repository,
    this._playerRepository,
    this.competitionId,
  ) : super(const StartTournamentLoading());

  final TournamentRepository _repository;
  final PlayerRepository _playerRepository;
  final String competitionId;

  StartTournamentReady? get _ready => switch (state) {
    StartTournamentReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const StartTournamentLoading());
    try {
      final players = await _playerRepository.currentPlayers(competitionId);
      if (isClosed) return;
      emit(
        StartTournamentReady(
          players: players
              .where((player) => player.isActive)
              .toList(growable: false),
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(StartTournamentFailed(failure));
    }
  }

  void toggle(String playerId) {
    final ready = _ready;
    if (ready == null) return;

    if (ready.isSelected(playerId)) {
      emit(
        ready.copyWith(
          selected: {...ready.selected}..remove(playerId),
          clearActionFailure: true,
        ),
      );
      return;
    }
    if (ready.isFull) return;

    emit(
      ready.copyWith(
        selected: {...ready.selected, playerId},
        clearActionFailure: true,
      ),
    );
  }

  Future<String?> start() async {
    final ready = _ready;
    if (ready == null || !ready.canStart) return null;
    emit(ready.copyWith(busy: true, clearActionFailure: true));

    try {
      final id = await _repository.start(
        competitionId: competitionId,
        playerIds: ready.selected.toList(growable: false),
      );
      if (isClosed) return null;
      return id;
    } on Failure catch (failure) {
      if (isClosed) return null;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, actionFailure: failure));
      }
      return null;
    }
  }
}
