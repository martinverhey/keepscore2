import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/elo_calculator.dart';
import '../../domain/match_entry.model.dart';

enum MatchFormStatus { loading, ready, missing, failed }

class MatchFormState extends Equatable {
  const MatchFormState({
    this.status = MatchFormStatus.loading,
    this.competition,
    this.players = const [],
    this.ratings = const {},
    this.assignments = const {},
    this.scoreA = '',
    this.scoreB = '',
    this.busy = false,
    this.failure,
    this.submitFailure,
  });

  final MatchFormStatus status;
  final Competition? competition;
  final List<Player> players;
  final Map<String, double> ratings;
  final Map<String, MatchTeam> assignments;
  final String scoreA;
  final String scoreB;
  final bool busy;
  final Failure? failure;
  final Failure? submitFailure;

  List<Player> team(MatchTeam side) => players
      .where((player) => assignments[player.id] == side)
      .toList(growable: false);

  List<Player> get teamA => team(MatchTeam.a);

  List<Player> get teamB => team(MatchTeam.b);

  List<Player> get bench => players
      .where((player) => !assignments.containsKey(player.id))
      .toList(growable: false);

  double ratingOf(String playerId) =>
      ratings[playerId] ?? (competition?.startingRating ?? 1000).toDouble();

  double teamRating(MatchTeam side) {
    final members = team(side);
    if (members.isEmpty) return 0;
    return EloCalculator.teamRating(
      members.map((player) => ratingOf(player.id)),
    );
  }

  int? get scoreAValue => int.tryParse(scoreA.trim());

  int? get scoreBValue => int.tryParse(scoreB.trim());

  bool get teamsAreValid => teamA.isNotEmpty && teamB.isNotEmpty;

  bool get scoresAreValid =>
      scoreAValue != null &&
      scoreBValue != null &&
      scoreAValue! >= 0 &&
      scoreBValue! >= 0;

  bool get isDraw => scoresAreValid && scoreAValue == scoreBValue;

  bool get drawIsRefused => isDraw && !(competition?.allowDraws ?? true);

  bool get canSubmit =>
      status == MatchFormStatus.ready &&
      teamsAreValid &&
      scoresAreValid &&
      !drawIsRefused &&
      !busy;

  MatchFormState copyWith({
    MatchFormStatus? status,
    Competition? competition,
    List<Player>? players,
    Map<String, double>? ratings,
    Map<String, MatchTeam>? assignments,
    String? scoreA,
    String? scoreB,
    bool? busy,
    Failure? failure,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
  }) {
    return MatchFormState(
      status: status ?? this.status,
      competition: competition ?? this.competition,
      players: players ?? this.players,
      ratings: ratings ?? this.ratings,
      assignments: assignments ?? this.assignments,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      busy: busy ?? this.busy,
      failure: failure ?? this.failure,
      submitFailure: clearSubmitFailure
          ? null
          : (submitFailure ?? this.submitFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    competition,
    players,
    ratings,
    assignments,
    scoreA,
    scoreB,
    busy,
    failure,
    submitFailure,
  ];
}
