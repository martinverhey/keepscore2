import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../domain/best_streaks.model.dart';
import '../../domain/rating_point.model.dart';
import '../../domain/recent_played.model.dart';
import '../../domain/streak.model.dart';

enum ProfileOverviewStatus { loading, ready, failed }

class ProfileOverviewState extends Equatable {
  const ProfileOverviewState({
    this.status = ProfileOverviewStatus.loading,
    this.selectedGameType,
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
    this.failure,
  });

  final ProfileOverviewStatus status;
  final GameType? selectedGameType;
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
  final Failure? failure;

  ProfileOverviewState copyWith({
    ProfileOverviewStatus? status,
    GameType? selectedGameType,
    Leaderboard? leaderboard,
    Medals? medals,
    double? bestRating,
    int? playerCount,
    List<RatingPoint>? history,
    int? totalPlayed,
    Streak? streak,
    BestStreaks? bestStreaks,
    RecentPlayed? recentPlayed,
    List<MatchEntry>? recentMatches,
    bool? hasOpponent,
    Failure? failure,
  }) {
    return ProfileOverviewState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      leaderboard: leaderboard ?? this.leaderboard,
      medals: medals ?? this.medals,
      bestRating: bestRating ?? this.bestRating,
      playerCount: playerCount ?? this.playerCount,
      history: history ?? this.history,
      totalPlayed: totalPlayed ?? this.totalPlayed,
      streak: streak ?? this.streak,
      bestStreaks: bestStreaks ?? this.bestStreaks,
      recentPlayed: recentPlayed ?? this.recentPlayed,
      recentMatches: recentMatches ?? this.recentMatches,
      hasOpponent: hasOpponent ?? this.hasOpponent,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedGameType,
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
    failure,
  ];
}
