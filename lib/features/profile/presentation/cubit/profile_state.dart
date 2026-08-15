import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
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
    this.medals,
    this.bestRating = 0,
    this.playerCount = 0,
    this.history = const [],
    this.totalPlayed = 0,
    this.streak = const Streak.none(),
    this.seasonHistory = const [],
    this.hasOpponent = false,
    this.headToHead = const [],
    this.recentMatches = const [],
    this.versusRecentMatches = const [],
    this.failure,
  });

  final ProfileStatus status;
  final GameType? selectedGameType;
  final Leaderboard? leaderboard;
  final Medals? medals;
  final double bestRating;
  final int playerCount;
  final List<RatingPoint> history;
  final int totalPlayed;
  final Streak streak;
  final List<SeasonStanding> seasonHistory;
  final bool hasOpponent;
  final List<HeadToHeadRecord> headToHead;
  final List<MatchEntry> recentMatches;
  final List<MatchEntry> versusRecentMatches;
  final Failure? failure;

  List<HeadToHeadRecord> get versusRecords => selectedGameType == null
      ? headToHead
      : headToHead
            .where((record) => record.gameType == selectedGameType)
            .toList(growable: false);

  ProfileState copyWith({
    ProfileStatus? status,
    GameType? selectedGameType,
    Leaderboard? leaderboard,
    Medals? medals,
    double? bestRating,
    int? playerCount,
    List<RatingPoint>? history,
    int? totalPlayed,
    Streak? streak,
    List<SeasonStanding>? seasonHistory,
    bool? hasOpponent,
    List<HeadToHeadRecord>? headToHead,
    List<MatchEntry>? recentMatches,
    List<MatchEntry>? versusRecentMatches,
    Failure? failure,
    bool clearLeaderboard = false,
    bool clearMedals = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      leaderboard: clearLeaderboard ? null : (leaderboard ?? this.leaderboard),
      medals: clearMedals ? null : (medals ?? this.medals),
      bestRating: bestRating ?? this.bestRating,
      playerCount: playerCount ?? this.playerCount,
      history: history ?? this.history,
      totalPlayed: totalPlayed ?? this.totalPlayed,
      streak: streak ?? this.streak,
      seasonHistory: seasonHistory ?? this.seasonHistory,
      hasOpponent: hasOpponent ?? this.hasOpponent,
      headToHead: headToHead ?? this.headToHead,
      recentMatches: recentMatches ?? this.recentMatches,
      versusRecentMatches: versusRecentMatches ?? this.versusRecentMatches,
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
    seasonHistory,
    hasOpponent,
    headToHead,
    recentMatches,
    versusRecentMatches,
    failure,
  ];
}
