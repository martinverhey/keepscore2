import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../domain/head_to_head_record.dart';
import '../../domain/rating_point.dart';
import '../../domain/streak.dart';

enum ProfileStatus { loading, ready, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.standing,
    this.playerCount = 0,
    this.history = const [],
    this.totalPlayed = 0,
    this.streak = const Streak.none(),
    this.seasonHistory = const [],
    this.headToHead = const [],
    this.failure,
  });

  final ProfileStatus status;
  final Leaderboard? standing;
  final int playerCount;
  final List<RatingPoint> history;
  final int totalPlayed;
  final Streak streak;
  final List<SeasonStanding> seasonHistory;
  final List<HeadToHeadRecord> headToHead;
  final Failure? failure;

  @override
  List<Object?> get props => [
    status,
    standing,
    playerCount,
    history,
    totalPlayed,
    streak,
    seasonHistory,
    headToHead,
    failure,
  ];
}
