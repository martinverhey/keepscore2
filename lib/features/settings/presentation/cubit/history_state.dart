import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season.model.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();

  @override
  List<Object?> get props => [];
}

class HistoryFailed extends HistoryState {
  const HistoryFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class HistoryReady extends HistoryState {
  const HistoryReady({
    this.seasons = const [],
    this.selectedSeasonId,
    this.leaderboards = const [],
    this.busy = false,
  });

  final List<Season> seasons;
  final String? selectedSeasonId;
  final List<SeasonLeaderboard> leaderboards;
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
    bool? busy,
  }) {
    return HistoryReady(
      seasons: seasons ?? this.seasons,
      selectedSeasonId: selectedSeasonId ?? this.selectedSeasonId,
      leaderboards: leaderboards ?? this.leaderboards,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [seasons, selectedSeasonId, leaderboards, busy];
}
