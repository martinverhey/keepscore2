import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/player.dart';
import '../../domain/player_repository.dart';

enum PlayersStatus { loading, ready, failed }

class PlayersState extends Equatable {
  const PlayersState({
    this.status = PlayersStatus.loading,
    this.players = const [],
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  final PlayersStatus status;
  final List<Player> players;
  final bool busy;
  final Failure? failure;
  final Failure? actionFailure;

  List<Player> get active =>
      players.where((player) => player.isActive).toList(growable: false);

  List<Player> get inactive =>
      players.where((player) => !player.isActive).toList(growable: false);

  PlayersState copyWith({
    PlayersStatus? status,
    List<Player>? players,
    bool? busy,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) {
    return PlayersState(
      status: status ?? this.status,
      players: players ?? this.players,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure:
          clearActionFailure ? null : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [status, players, busy, failure, actionFailure];
}

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
      emit(state.copyWith(
        status: PlayersStatus.ready,
        players: players,
        clearFailure: true,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(
        status: PlayersStatus.failed,
        players: silent ? state.players : const [],
        failure: failure,
      ));
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
    players.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return List.unmodifiable(players);
  }
}
