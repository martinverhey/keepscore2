import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../../match/domain/game_type.dart';
import '../../../match/domain/match_entry.dart';
import '../../domain/head_to_head_record.dart';
import '../../domain/rating_point.dart';
import '../../domain/streak.dart';

enum ProfileStatus { loading, ready, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.selectedGameType,
    this.standing,
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
  final Leaderboard? standing;
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
    Leaderboard? standing,
    double? bestRating,
    int? playerCount,
    List<RatingPoint>? history,
    int? totalPlayed,
    Streak? streak,
    List<SeasonStanding>? seasonHistory,
    List<HeadToHeadRecord>? headToHead,
    List<MatchEntry>? recentMatches,
    Failure? failure,
    bool clearStanding = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      standing: clearStanding ? null : (standing ?? this.standing),
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
    standing,
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
