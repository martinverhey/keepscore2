import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../player/domain/player.model.dart';

sealed class StartTournamentState extends Equatable {
  const StartTournamentState();
}

class StartTournamentLoading extends StartTournamentState {
  const StartTournamentLoading();

  @override
  List<Object?> get props => [];
}

class StartTournamentFailed extends StartTournamentState {
  const StartTournamentFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class StartTournamentReady extends StartTournamentState {
  const StartTournamentReady({
    required this.players,
    this.selected = const {},
    this.busy = false,
    this.actionFailure,
  });

  static const bracketSizes = [2, 4, 8, 16];
  static const maxPlayers = 16;

  final List<Player> players;
  final Set<String> selected;
  final bool busy;
  final Failure? actionFailure;

  bool get canStart => bracketSizes.contains(selected.length) && !busy;

  bool get isFull => selected.length >= maxPlayers;

  bool isSelected(String playerId) => selected.contains(playerId);

  bool canSelect(String playerId) => isSelected(playerId) || !isFull;

  StartTournamentReady copyWith({
    List<Player>? players,
    Set<String>? selected,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return StartTournamentReady(
      players: players ?? this.players,
      selected: selected ?? this.selected,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [players, selected, busy, actionFailure];
}
