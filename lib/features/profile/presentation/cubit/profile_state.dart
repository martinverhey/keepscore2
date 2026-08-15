import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../domain/head_to_head_record.model.dart';
import '../../domain/rating_point.model.dart';
import '../../domain/streak.model.dart';

enum ProfileStatus { loading, ready, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.selectedGameType,
    this.leaderboard,
    this.bestRating = 0,
    this.playerCount = 0,
    this.history = const [],
    this.totalPlayed = 0,
    this.streak = const Streak.none(),
    this.seasonHistory = const [],
    this.headToHead = const [],
    this.recentMatches = const [],
    this.failure,
  });

  final ProfileStatus status;
  final GameType? selectedGameType;
  final Leaderboard? leaderboard;
  final double bestRating;
  final int playerCount;
  final List<RatingPoint> history;
  final int totalPlayed;
  final Streak streak;
  final List<SeasonStanding> seasonHistory;
  final List<HeadToHeadRecord> headToHead;
  final List<MatchEntry> recentMatches;
  final Failure? failure;

  ProfileState copyWith({
    ProfileStatus? status,
    GameType? selectedGameType,
    Leaderboard? leaderboard,
    double? bestRating,
    int? playerCount,
    List<RatingPoint>? history,
    int? totalPlayed,
    Streak? streak,
    List<SeasonStanding>? seasonHistory,
    List<HeadToHeadRecord>? headToHead,
    List<MatchEntry>? recentMatches,
    Failure? failure,
    bool clearLeaderboard = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      leaderboard: clearLeaderboard ? null : (leaderboard ?? this.leaderboard),
      bestRating: bestRating ?? this.bestRating,
      playerCount: playerCount ?? this.playerCount,
      history: history ?? this.history,
      totalPlayed: totalPlayed ?? this.totalPlayed,
      streak: streak ?? this.streak,
      seasonHistory: seasonHistory ?? this.seasonHistory,
      headToHead: headToHead ?? this.headToHead,
      recentMatches: recentMatches ?? this.recentMatches,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedGameType,
    leaderboard,
    bestRating,
    playerCount,
    history,
    totalPlayed,
    streak,
    seasonHistory,
    headToHead,
    recentMatches,
    failure,
  ];
}
