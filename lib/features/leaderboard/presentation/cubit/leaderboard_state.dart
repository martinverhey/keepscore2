import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../domain/leaderboard.model.dart';
import '../../domain/medals.model.dart';
import '../../domain/season.model.dart';

enum LeaderboardStatus { loading, ready, failed }

class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.season,
    this.selectedGameType,
    this.standings = const [],
    this.medals = const {},
    this.busy = false,
    this.failure,
  });

  final LeaderboardStatus status;

  final Season? season;
  final GameType? selectedGameType;
  final List<Leaderboard> standings;
  final Map<String, Medals> medals;

  final bool busy;

  final Failure? failure;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    Season? season,
    GameType? selectedGameType,
    List<Leaderboard>? standings,
    Map<String, Medals>? medals,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    bool clearGameType = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      season: season ?? this.season,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      standings: standings ?? this.standings,
      medals: medals ?? this.medals,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    season,
    selectedGameType,
    standings,
    medals,
    busy,
    failure,
  ];
}
