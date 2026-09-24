import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../profile/domain/rating_point.model.dart';
import '../../domain/leaderboard.model.dart';
import '../../domain/medals.model.dart';
import '../../domain/season.model.dart';

sealed class LeaderboardState extends Equatable {
  const LeaderboardState();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();

  @override
  List<Object?> get props => [];
}

class LeaderboardFailed extends LeaderboardState {
  const LeaderboardFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class LeaderboardReady extends LeaderboardState {
  const LeaderboardReady({
    required this.season,
    this.leaderboards = const [],
    this.medals = const {},
    this.viewerTrend = const [],
    this.finishedSeasons = const [],
    this.viewedSeasonId,
    this.finishedLeaderboards = const [],
    this.busy = false,
  });

  final Season season;
  final List<Leaderboard> leaderboards;
  final Map<String, Medals> medals;
  final List<RatingPoint> viewerTrend;
  final List<Season> finishedSeasons;
  final String? viewedSeasonId;
  final List<Leaderboard> finishedLeaderboards;
  final bool busy;

  bool get hasHistory => finishedSeasons.isNotEmpty;

  Season? get viewedFinishedSeason {
    for (final finished in finishedSeasons) {
      if (finished.id == viewedSeasonId) return finished;
    }
    return null;
  }

  Season get viewedSeason => viewedFinishedSeason ?? season;

  List<Season> get pickableSeasons => [season, ...finishedSeasons];

  List<Leaderboard> get viewedLeaderboards =>
      viewedFinishedSeason == null ? leaderboards : finishedLeaderboards;

  LeaderboardReady copyWith({
    Season? season,
    List<Leaderboard>? leaderboards,
    Map<String, Medals>? medals,
    List<RatingPoint>? viewerTrend,
    List<Season>? finishedSeasons,
    String? viewedSeasonId,
    bool viewCurrentSeason = false,
    List<Leaderboard>? finishedLeaderboards,
    bool? busy,
  }) {
    return LeaderboardReady(
      season: season ?? this.season,
      leaderboards: leaderboards ?? this.leaderboards,
      medals: medals ?? this.medals,
      viewerTrend: viewerTrend ?? this.viewerTrend,
      finishedSeasons: finishedSeasons ?? this.finishedSeasons,
      viewedSeasonId: viewCurrentSeason
          ? null
          : viewedSeasonId ?? this.viewedSeasonId,
      finishedLeaderboards: finishedLeaderboards ?? this.finishedLeaderboards,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [
    season,
    leaderboards,
    medals,
    viewerTrend,
    finishedSeasons,
    viewedSeasonId,
    finishedLeaderboards,
    busy,
  ];
}
