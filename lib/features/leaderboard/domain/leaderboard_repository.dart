import 'season.dart';
import 'season_window.dart';
import 'standing.dart';

abstract interface class LeaderboardRepository {
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at});

  Future<List<Season>> seasons(String competitionId);

  Future<List<Standing>> standings({
    required String competitionId,
    required String? seasonId,
  });

  /// Ticks whenever the ratings in [seasonId] change. Carries no payload: a
  /// replayed season rewrites every row, so refetching the view is both
  /// simpler and cheaper than reconciling a stream of individual rows.
  Stream<void> watchStandings({
    required String competitionId,
    required String? seasonId,
  });
}
