import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../competition/domain/competition_repository.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/season_window.model.dart';
import '../../../player/domain/player.model.dart';
import '../../../player/domain/player_repository.dart';
import '../../domain/match_entry.model.dart';
import '../../domain/match_repository.dart';
import 'match_form_state.dart';

export 'match_form_state.dart';

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

      final leaderboards = await _leaderboard.leaderboards(
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
            for (final leaderboard in leaderboards)
              leaderboard.playerId: leaderboard.rating,
          },
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(MatchFormState(status: MatchFormStatus.failed, failure: failure));
    }
  }

  Future<void> refreshPlayers() async {
    try {
      final players = await _players.roster(competitionId);
      if (isClosed) return;
      emit(
        state.copyWith(
          players: players
              .where((player) => player.isActive)
              .toList(growable: false),
        ),
      );
    } on Failure {
      return;
    }
  }

  void assign(String playerId, MatchTeam side) {
    final assignments = Map<String, MatchTeam>.from(state.assignments);
    if (assignments[playerId] == side) {
      assignments.remove(playerId);
    } else {
      assignments[playerId] = side;
    }
    emit(state.copyWith(assignments: assignments, clearSubmitFailure: true));
  }

  void setTeam(MatchTeam side, Iterable<String> playerIds) {
    final assignments = Map<String, MatchTeam>.from(state.assignments)
      ..removeWhere((_, team) => team == side);
    for (final playerId in playerIds) {
      assignments[playerId] = side;
    }
    emit(state.copyWith(assignments: assignments, clearSubmitFailure: true));
  }

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
