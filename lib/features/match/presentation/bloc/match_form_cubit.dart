import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.dart';
import '../../../competition/domain/competition_repository.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_window.dart';
import '../../../player/domain/player.dart';
import '../../../player/domain/player_repository.dart';
import '../../domain/elo_calculator.dart';
import '../../domain/match_entry.dart';
import '../../domain/match_repository.dart';

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

  /// Active roster, in name order — everyone who may be put on a side.
  final List<Player> players;

  /// Current-season rating per player. Anyone missing has not played yet and
  /// sits at the competition's starting rating.
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

  /// What the result is worth, computed locally so the numbers appear as the
  /// scores are typed. Postgres recomputes them on submit and its answer wins.
  EloPreview? get preview {
    final settings = competition;
    if (settings == null || !teamsAreValid || !scoresAreValid) return null;
    return EloCalculator.preview(
      teamA: teamA.map((player) => ratingOf(player.id)).toList(growable: false),
      teamB: teamB.map((player) => ratingOf(player.id)).toList(growable: false),
      scoreA: scoreAValue!,
      scoreB: scoreBValue!,
      settings: EloSettings(
        kFactor: settings.kFactor,
        movEnabled: settings.movEnabled,
        movCap: settings.movCap,
        startingRating: settings.startingRating,
      ),
    );
  }

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

class MatchFormCubit extends Cubit<MatchFormState> {
  MatchFormCubit(
    this._matches,
    this._competitions,
    this._players,
    this._leaderboard,
    this.competitionId,
  ) : super(const MatchFormState());

  final MatchRepository _matches;
  final CompetitionRepository _competitions;
  final PlayerRepository _players;
  final LeaderboardRepository _leaderboard;
  final String competitionId;

  Future<void> load() async {
    emit(const MatchFormState());
    try {
      final results = await Future.wait<Object?>([
        _competitions.overview(competitionId),
        _players.roster(competitionId),
        _leaderboard.currentSeason(competitionId),
      ]);
      if (isClosed) return;

      final overview = results[0] as CompetitionOverview?;
      if (overview == null) {
        emit(const MatchFormState(status: MatchFormStatus.missing));
        return;
      }

      final standings = await _leaderboard.standings(
        competitionId: competitionId,
        seasonId: (results[2] as SeasonWindow).id,
      );
      if (isClosed) return;

      emit(
        MatchFormState(
          status: MatchFormStatus.ready,
          competition: overview.competition,
          players: (results[1] as List<Player>)
              .where((player) => player.isActive)
              .toList(growable: false),
          ratings: {
            for (final standing in standings) standing.playerId: standing.rating,
          },
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(MatchFormState(status: MatchFormStatus.failed, failure: failure));
    }
  }

  /// Tapping the side a player is already on takes them back off the pitch.
  void assign(String playerId, MatchTeam side) {
    final assignments = Map<String, MatchTeam>.from(state.assignments);
    if (assignments[playerId] == side) {
      assignments.remove(playerId);
    } else {
      assignments[playerId] = side;
    }
    emit(state.copyWith(assignments: assignments, clearSubmitFailure: true));
  }

  void swapSides() {
    emit(
      state.copyWith(
        assignments: {
          for (final entry in state.assignments.entries)
            entry.key: entry.value.opposite,
        },
        scoreA: state.scoreB,
        scoreB: state.scoreA,
        clearSubmitFailure: true,
      ),
    );
  }

  void clearTeams() =>
      emit(state.copyWith(assignments: const {}, clearSubmitFailure: true));

  void scoreAChanged(String value) =>
      emit(state.copyWith(scoreA: value, clearSubmitFailure: true));

  void scoreBChanged(String value) =>
      emit(state.copyWith(scoreB: value, clearSubmitFailure: true));

  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    emit(state.copyWith(busy: true, clearSubmitFailure: true));
    try {
      final id = await _matches.create(
        competitionId: competitionId,
        teamA: state.teamA.map((player) => player.id).toList(growable: false),
        teamB: state.teamB.map((player) => player.id).toList(growable: false),
        scoreA: state.scoreAValue!,
        scoreB: state.scoreBValue!,
      );
      if (isClosed) return id;
      emit(state.copyWith(busy: false));
      return id;
    } on Failure catch (failure) {
      if (isClosed) return null;
      emit(state.copyWith(busy: false, submitFailure: failure));
      return null;
    }
  }
}
