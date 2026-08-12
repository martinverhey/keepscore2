import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../../match/domain/game_type.dart';

typedef SeasonHistoryGroup = ({
  String seasonId,
  DateTime startsAt,
  DateTime endsAt,
  List<SeasonStanding> standings,
});

enum SeasonHistoryStatus { loading, ready, failed }

class SeasonHistoryState extends Equatable {
  const SeasonHistoryState({
    this.status = SeasonHistoryStatus.loading,
    this.groups = const [],
    this.selectedGameType,
    this.busy = false,
    this.failure,
  });

  final SeasonHistoryStatus status;
  final List<SeasonHistoryGroup> groups;
  final GameType? selectedGameType;
  final bool busy;
  final Failure? failure;

  SeasonHistoryState copyWith({
    SeasonHistoryStatus? status,
    List<SeasonHistoryGroup>? groups,
    GameType? selectedGameType,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    bool clearGameType = false,
  }) {
    return SeasonHistoryState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, groups, selectedGameType, busy, failure];
}
