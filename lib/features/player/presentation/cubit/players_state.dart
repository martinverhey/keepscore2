import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/player_list_active.dart';
import '../../domain/player.model.dart';

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

  List<Player> get active => players.active;

  List<Player> get inactive =>
      players.where((player) => !player.isActive).toList(growable: false);

  List<Player> get claimed =>
      active.where((player) => player.isClaimed).toList(growable: false);

  List<Player> get unclaimed =>
      active.where((player) => player.isPlaceholder).toList(growable: false);

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
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [status, players, busy, failure, actionFailure];
}
