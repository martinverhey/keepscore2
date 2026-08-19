import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../domain/best_streaks.model.dart';
import '../../domain/rating_point.model.dart';
import '../../domain/recent_played.model.dart';
import '../../domain/streak.model.dart';

sealed class ProfileOverviewState extends Equatable {
  const ProfileOverviewState();
}

class ProfileOverviewLoading extends ProfileOverviewState {
  const ProfileOverviewLoading();

  @override
  List<Object?> get props => [];
}

class ProfileOverviewFailed extends ProfileOverviewState {
  const ProfileOverviewFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfileOverviewReady extends ProfileOverviewState {
  const ProfileOverviewReady({
    this.leaderboard,
    this.medals,
    this.bestRating = 0,
    this.playerCount = 0,
    this.history = const [],
    this.totalPlayed = 0,
    this.streak = const Streak.none(),
    this.bestStreaks = const BestStreaks.zero(),
    this.recentPlayed = const RecentPlayed.zero(),
    this.recentMatches = const [],
    this.hasOpponent = false,
  });

  final Leaderboard? leaderboard;
  final Medals? medals;
  final double bestRating;
  final int playerCount;
  final List<RatingPoint> history;
  final int totalPlayed;
  final Streak streak;
  final BestStreaks bestStreaks;
  final RecentPlayed recentPlayed;
  final List<MatchEntry> recentMatches;
  final bool hasOpponent;

  @override
  List<Object?> get props => [
    leaderboard,
    medals,
    bestRating,
    playerCount,
    history,
    totalPlayed,
    streak,
    bestStreaks,
    recentPlayed,
    recentMatches,
    hasOpponent,
  ];
}
