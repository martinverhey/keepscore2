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
    this.selectedSeasonId,
    this.selectedGameType,
    this.busy = false,
    this.failure,
  });

  final SeasonHistoryStatus status;
  final List<SeasonHistoryGroup> groups;
  final String? selectedSeasonId;
  final GameType? selectedGameType;
  final bool busy;
  final Failure? failure;

  SeasonHistoryGroup? get selectedGroup {
    if (groups.isEmpty) return null;
    for (final group in groups) {
      if (group.seasonId == selectedSeasonId) return group;
    }
    return groups.first;
  }

  bool get hasHistory => groups.length > 1;

  SeasonHistoryState copyWith({
    SeasonHistoryStatus? status,
    List<SeasonHistoryGroup>? groups,
    String? selectedSeasonId,
    GameType? selectedGameType,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    bool clearGameType = false,
  }) {
    return SeasonHistoryState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedSeasonId: selectedSeasonId ?? this.selectedSeasonId,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    groups,
    selectedSeasonId,
    selectedGameType,
    busy,
    failure,
  ];
}
