import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season.model.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../match/domain/game_type.enum.dart';

enum SeasonHistoryStatus { loading, ready, failed }

class SeasonHistoryState extends Equatable {
  const SeasonHistoryState({
    this.status = SeasonHistoryStatus.loading,
    this.seasons = const [],
    this.selectedSeasonId,
    this.standings = const [],
    this.selectedGameType,
    this.busy = false,
    this.failure,
  });

  final SeasonHistoryStatus status;
  final List<Season> seasons;
  final String? selectedSeasonId;
  final List<SeasonStanding> standings;
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

  SeasonHistoryState copyWith({
    SeasonHistoryStatus? status,
    List<Season>? seasons,
    String? selectedSeasonId,
    List<SeasonStanding>? standings,
    GameType? selectedGameType,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
    bool clearGameType = false,
  }) {
    return SeasonHistoryState(
      status: status ?? this.status,
      seasons: seasons ?? this.seasons,
      selectedSeasonId: selectedSeasonId ?? this.selectedSeasonId,
      standings: standings ?? this.standings,
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
    standings,
    selectedGameType,
    busy,
    failure,
  ];
}
