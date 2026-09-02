import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/extensions/player_list.extension.dart';
import '../../../competition/domain/competition_repository.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
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
  ) : super(const MatchFormLoading());

  final MatchRepository _matches;
  final CompetitionRepository _competitions;
  final PlayerRepository _players;
  final LeaderboardRepository _leaderboard;
  final String competitionId;

  MatchFormReady? get _ready => switch (state) {
    MatchFormReady ready => ready,
    _ => null,
  };

  Future<void> load() async {
    emit(const MatchFormLoading());
    try {
      final overviewFuture = _competitions.overview(competitionId);
      final playersFuture = _players.currentPlayers(competitionId);
      final seasonFuture = _leaderboard.currentSeason(competitionId);

      final overview = await overviewFuture;
      if (isClosed) return;
      if (overview == null) {
        emit(const MatchFormMissing());
        return;
      }

      final players = await playersFuture;
      final season = await seasonFuture;
      if (isClosed) return;

      final leaderboards = await _leaderboard.leaderboards(
        competitionId: competitionId,
        seasonId: season.id,
      );
      if (isClosed) return;

      emit(
        MatchFormReady(
          competition: overview.competition,
          players: players.active,
          ratings: {
            for (final leaderboard in leaderboards)
              leaderboard.playerId: leaderboard.rating,
          },
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(MatchFormFailed(failure));
    }
  }

  Future<void> refreshPlayers() async {
    if (_ready == null) return;
    try {
      final players = await _players.currentPlayers(competitionId);
      if (isClosed) return;
      final ready = _ready;
      if (ready != null) emit(ready.copyWith(players: players.active));
    } on Failure {
      return;
    }
  }

  void assign(String playerId, MatchTeam side) {
    final ready = _ready;
    if (ready == null) return;
    final assignments = Map<String, MatchTeam>.from(ready.assignments);
    if (assignments[playerId] == side) {
      assignments.remove(playerId);
    } else {
      assignments[playerId] = side;
    }
    emit(ready.copyWith(assignments: assignments, clearSubmitFailure: true));
  }

  void setTeam(MatchTeam side, Iterable<String> playerIds) {
    final ready = _ready;
    if (ready == null) return;
    final assignments = Map<String, MatchTeam>.from(ready.assignments)
      ..removeWhere((_, team) => team == side);
    for (final playerId in playerIds) {
      assignments[playerId] = side;
    }
    emit(ready.copyWith(assignments: assignments, clearSubmitFailure: true));
  }

  void setTeams({
    required Iterable<String> teamA,
    required Iterable<String> teamB,
  }) {
    final ready = _ready;
    if (ready == null) return;
    emit(
      ready.copyWith(
        assignments: {
          for (final playerId in teamA) playerId: MatchTeam.a,
          for (final playerId in teamB) playerId: MatchTeam.b,
        },
        clearSubmitFailure: true,
      ),
    );
  }

  void setMode(MatchEntryMode mode) {
    final ready = _ready;
    if (ready == null || ready.mode == mode) return;
    emit(
      ready.copyWith(
        mode: mode,
        assignments: mode == MatchEntryMode.oneVsOne
            ? _withoutCrowdedSides(ready.assignments)
            : ready.assignments,
        clearSubmitFailure: true,
      ),
    );
  }

  Future<String?> submit({required int scoreA, required int scoreB}) async {
    final ready = _ready;
    if (ready == null) return null;
    if (!ready.canSubmit(scoreAValue: scoreA, scoreBValue: scoreB)) {
      return null;
    }
    emit(ready.copyWith(busy: true, clearSubmitFailure: true));
    try {
      final id = await _matches.create(
        competitionId: competitionId,
        teamA: ready.teamA.map((player) => player.id).toList(growable: false),
        teamB: ready.teamB.map((player) => player.id).toList(growable: false),
        scoreA: scoreA,
        scoreB: scoreB,
      );
      if (isClosed) return id;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
      return id;
    } on Failure catch (failure) {
      if (isClosed) return null;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(busy: false, submitFailure: failure));
      }
      return null;
    }
  }
}

Map<String, MatchTeam> _withoutCrowdedSides(
  Map<String, MatchTeam> assignments,
) {
  final crowded = MatchTeam.values.where(
    (side) => assignments.values.where((team) => team == side).length > 1,
  );
  return {
    for (final entry in assignments.entries)
      if (!crowded.contains(entry.value)) entry.key: entry.value,
  };
}
