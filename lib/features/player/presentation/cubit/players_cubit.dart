import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/player.dart';
import '../../domain/player_repository.dart';
import 'players_state.dart';

export 'players_state.dart';

class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repository, this.competitionId)
    : super(const PlayersState());

  final PlayerRepository _repository;
  final String competitionId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const PlayersState());
    try {
      final players = await _repository.roster(competitionId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlayersStatus.ready,
          players: _sortedByName(players),
          clearFailure: true,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlayersStatus.failed,
          players: silent ? state.players : const [],
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<bool> addPlaceholder(String displayName) => _mutate(
    () => _repository.addPlaceholder(
      competitionId: competitionId,
      displayName: displayName,
    ),
  );

  Future<bool> rename(String playerId, String displayName) => _mutate(
    () => _repository.rename(playerId: playerId, displayName: displayName),
  );

  Future<bool> setActive(String playerId, {required bool isActive}) => _mutate(
    () => _repository.setActive(playerId: playerId, isActive: isActive),
  );

  Future<bool> _mutate(Future<Player> Function() action) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true, clearActionFailure: true));
    try {
      final player = await action();
      if (isClosed) return true;
      emit(state.copyWith(busy: false, players: _merged(player)));
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(state.copyWith(busy: false, actionFailure: failure));
      return false;
    }
  }

  List<Player> _merged(Player player) {
    final players = [
      for (final existing in state.players)
        if (existing.id == player.id) player else existing,
    ];
    if (!players.any((existing) => existing.id == player.id)) {
      players.add(player);
    }
    return _sortedByName(players);
  }
}

List<Player> _sortedByName(List<Player> players) {
  final sorted = [...players];
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return List.unmodifiable(sorted);
}
