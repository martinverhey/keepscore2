import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/player_list.extension.dart';
import '../../domain/player.model.dart';

sealed class PlayersState extends Equatable {
  const PlayersState();
}

class PlayersLoading extends PlayersState {
  const PlayersLoading();

  @override
  List<Object?> get props => [];
}

class PlayersFailed extends PlayersState {
  const PlayersFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class PlayersReady extends PlayersState {
  const PlayersReady({
    this.players = const [],
    this.busy = false,
    this.actionFailure,
  });

  final List<Player> players;
  final bool busy;
  final Failure? actionFailure;

  List<Player> get active => players.active;

  List<Player> get inactive =>
      players.where((player) => !player.isActive).toList(growable: false);

  List<Player> get claimed =>
      active.where((player) => player.isClaimed).toList(growable: false);

  List<Player> get unclaimed =>
      active.where((player) => player.isPlaceholder).toList(growable: false);

  PlayersReady copyWith({
    List<Player>? players,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return PlayersReady(
      players: players ?? this.players,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [players, busy, actionFailure];
}
