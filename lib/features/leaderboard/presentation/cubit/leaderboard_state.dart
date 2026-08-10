import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/season.dart';
import '../../domain/standing.dart';

enum LeaderboardStatus { loading, ready, failed }

class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.seasons = const [],
    this.selectedStartsAt,
    this.standings = const [],
    this.busy = false,
    this.failure,
  });

  final LeaderboardStatus status;

  /// Newest first. The window the competition is currently playing for is
  /// always the first entry, whether or not it has a row in `seasons` yet.
  final List<Season> seasons;

  final DateTime? selectedStartsAt;
  final List<Standing> standings;

  /// A season switch is in flight.
  final bool busy;

  final Failure? failure;

  Season? get currentSeason => seasons.isEmpty ? null : seasons.first;

  Season? get selectedSeason {
    if (seasons.isEmpty) return null;
    for (final season in seasons) {
      if (selectedStartsAt != null &&
          season.startsAt.isAtSameMomentAs(selectedStartsAt!)) {
        return season;
      }
    }
    return seasons.first;
  }

  bool get isShowingCurrentSeason => selectedSeason == currentSeason;

  bool get hasHistory => seasons.length > 1;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<Season>? seasons,
    DateTime? selectedStartsAt,
    List<Standing>? standings,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      seasons: seasons ?? this.seasons,
      selectedStartsAt: selectedStartsAt ?? this.selectedStartsAt,
      standings: standings ?? this.standings,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    seasons,
    selectedStartsAt,
    standings,
    busy,
    failure,
  ];
}
