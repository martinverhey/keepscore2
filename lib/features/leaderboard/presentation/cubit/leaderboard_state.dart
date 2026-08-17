import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
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
    this.selectedGameType,
    this.leaderboards = const [],
    this.medals = const {},
    this.busy = false,
  });

  final Season season;
  final GameType? selectedGameType;
  final List<Leaderboard> leaderboards;
  final Map<String, Medals> medals;
  final bool busy;

  LeaderboardReady copyWith({
    Season? season,
    GameType? selectedGameType,
    List<Leaderboard>? leaderboards,
    Map<String, Medals>? medals,
    bool? busy,
    bool clearGameType = false,
  }) {
    return LeaderboardReady(
      season: season ?? this.season,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      leaderboards: leaderboards ?? this.leaderboards,
      medals: medals ?? this.medals,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [
    season,
    selectedGameType,
    leaderboards,
    medals,
    busy,
  ];
}
