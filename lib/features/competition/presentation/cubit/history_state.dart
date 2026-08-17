import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season.model.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/game_type.enum.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading({this.selectedGameType});

  final GameType? selectedGameType;

  @override
  List<Object?> get props => [selectedGameType];
}

class HistoryFailed extends HistoryState {
  const HistoryFailed(this.failure, {this.selectedGameType});

  final Failure failure;
  final GameType? selectedGameType;

  @override
  List<Object?> get props => [failure, selectedGameType];
}

class HistoryReady extends HistoryState {
  const HistoryReady({
    this.seasons = const [],
    this.selectedSeasonId,
    this.leaderboards = const [],
    this.selectedGameType,
    this.busy = false,
  });

  final List<Season> seasons;
  final String? selectedSeasonId;
  final List<SeasonLeaderboard> leaderboards;
  final GameType? selectedGameType;
  final bool busy;

  Season? get selectedSeason {
    if (seasons.isEmpty) return null;
    for (final season in seasons) {
      if (season.id == selectedSeasonId) return season;
    }
    return seasons.first;
  }

  bool get hasHistory => seasons.length > 1;

  HistoryReady copyWith({
    List<Season>? seasons,
    String? selectedSeasonId,
    List<SeasonLeaderboard>? leaderboards,
    GameType? selectedGameType,
    bool? busy,
    bool clearGameType = false,
  }) {
    return HistoryReady(
      seasons: seasons ?? this.seasons,
      selectedSeasonId: selectedSeasonId ?? this.selectedSeasonId,
      leaderboards: leaderboards ?? this.leaderboards,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [
    seasons,
    selectedSeasonId,
    leaderboards,
    selectedGameType,
    busy,
  ];
}
