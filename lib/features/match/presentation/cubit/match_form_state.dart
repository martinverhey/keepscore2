import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/elo_calculator.dart';
import '../../domain/match_entry.model.dart';
import 'match_entry_mode.enum.dart';

export 'match_entry_mode.enum.dart';

sealed class MatchFormState extends Equatable {
  const MatchFormState();
}

class MatchFormLoading extends MatchFormState {
  const MatchFormLoading();

  @override
  List<Object?> get props => [];
}

class MatchFormMissing extends MatchFormState {
  const MatchFormMissing();

  @override
  List<Object?> get props => [];
}

class MatchFormFailed extends MatchFormState {
  const MatchFormFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class MatchFormReady extends MatchFormState {
  const MatchFormReady({
    required this.competition,
    this.players = const [],
    this.ratings = const {},
    this.assignments = const {},
    this.mode = MatchEntryMode.oneVsOne,
    this.busy = false,
    this.submitFailure,
  });

  final Competition competition;
  final List<Player> players;
  final Map<String, double> ratings;
  final Map<String, MatchTeam> assignments;
  final MatchEntryMode mode;
  final bool busy;
  final Failure? submitFailure;

  bool get isOneVsOne => mode == MatchEntryMode.oneVsOne;

  List<Player> team(MatchTeam side) => players
      .where((player) => assignments[player.id] == side)
      .toList(growable: false);

  List<Player> get teamA => team(MatchTeam.a);

  List<Player> get teamB => team(MatchTeam.b);

  List<Player> get bench => players
      .where((player) => !assignments.containsKey(player.id))
      .toList(growable: false);

  double ratingOf(String playerId) =>
      ratings[playerId] ?? competition.startingRating.toDouble();

  double teamRating(MatchTeam side) {
    final members = team(side);
    if (members.isEmpty) return 0;
    return EloCalculator.teamRating(
      members.map((player) => ratingOf(player.id)),
    );
  }

  bool get teamsAreValid => teamA.isNotEmpty && teamB.isNotEmpty;

  bool scoresAreValid({required int? scoreAValue, required int? scoreBValue}) =>
      scoreAValue != null &&
      scoreBValue != null &&
      scoreAValue >= 0 &&
      scoreBValue >= 0;

  bool isDraw({required int? scoreAValue, required int? scoreBValue}) =>
      scoresAreValid(scoreAValue: scoreAValue, scoreBValue: scoreBValue) &&
      scoreAValue == scoreBValue;

  bool drawIsRefused({required int? scoreAValue, required int? scoreBValue}) =>
      isDraw(scoreAValue: scoreAValue, scoreBValue: scoreBValue) &&
      !competition.allowDraws;

  bool canSubmit({required int? scoreAValue, required int? scoreBValue}) =>
      teamsAreValid &&
      scoresAreValid(scoreAValue: scoreAValue, scoreBValue: scoreBValue) &&
      !drawIsRefused(scoreAValue: scoreAValue, scoreBValue: scoreBValue) &&
      !busy;

  MatchFormReady copyWith({
    List<Player>? players,
    Map<String, double>? ratings,
    Map<String, MatchTeam>? assignments,
    MatchEntryMode? mode,
    bool? busy,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
  }) {
    return MatchFormReady(
      competition: competition,
      players: players ?? this.players,
      ratings: ratings ?? this.ratings,
      assignments: assignments ?? this.assignments,
      mode: mode ?? this.mode,
      busy: busy ?? this.busy,
      submitFailure: clearSubmitFailure
          ? null
          : (submitFailure ?? this.submitFailure),
    );
  }

  @override
  List<Object?> get props => [
    competition,
    players,
    ratings,
    assignments,
    mode,
    busy,
    submitFailure,
  ];
}
