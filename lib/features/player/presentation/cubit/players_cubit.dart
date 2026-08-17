import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/player.model.dart';
import '../../domain/player_repository.dart';
import 'players_state.dart';

export 'players_state.dart';

class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repository, this.competitionId)
    : super(const PlayersLoading());

  final PlayerRepository _repository;
  final String competitionId;

  PlayersReady? get _ready => switch (state) {
    PlayersReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const PlayersLoading());
    try {
      final players = await _repository.currentPlayers(competitionId);
      if (isClosed) return;
      emit(PlayersReady(players: _sortedByName(players)));
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(PlayersFailed(failure));
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
    final ready = _ready;
    if (ready == null || ready.busy) return false;
    emit(ready.copyWith(busy: true, clearActionFailure: true));
    try {
      final player = await action();
      if (isClosed) return true;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, players: _merged(latest, player)));
      }
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

  List<Player> _merged(PlayersReady ready, Player player) {
    final players = [
      for (final existing in ready.players)
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
