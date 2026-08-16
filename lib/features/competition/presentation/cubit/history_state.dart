import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season.model.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/game_type.enum.dart';

enum HistoryStatus { loading, ready, failed }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.loading,
    this.seasons = const [],
    this.selectedSeasonId,
    this.leaderboards = const [],
    this.selectedGameType,
    this.busy = false,
    this.failure,
  });

  final HistoryStatus status;
  final List<Season> seasons;
  final String? selectedSeasonId;
  final List<SeasonLeaderboard> leaderboards;
  final GameType? selectedGameType;
  final bool busy;
  final Failure? failure;

  Season? get selectedSeason {
    if (seasons.isEmpty) return null;
    for (final season in seasons) {
      if (season.id == selectedSeasonId) return season;
    }
    return seasons.first;
  }

  bool get hasHistory => seasons.length > 1;

  HistoryState copyWith({
    HistoryStatus? status,
    List<Season>? seasons,
    String? selectedSeasonId,
    List<SeasonLeaderboard>? leaderboards,
    GameType? selectedGameType,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    bool clearGameType = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      seasons: seasons ?? this.seasons,
      selectedSeasonId: selectedSeasonId ?? this.selectedSeasonId,
      leaderboards: leaderboards ?? this.leaderboards,
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
    seasons,
    selectedSeasonId,
    leaderboards,
    selectedGameType,
    busy,
    failure,
  ];
}
