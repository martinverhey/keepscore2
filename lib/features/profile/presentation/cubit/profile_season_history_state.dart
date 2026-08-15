import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../match/domain/game_type.enum.dart';

enum ProfileSeasonHistoryStatus { loading, ready, failed }

class ProfileSeasonHistoryState extends Equatable {
  const ProfileSeasonHistoryState({
    this.status = ProfileSeasonHistoryStatus.loading,
    this.selectedGameType,
    this.standings = const [],
    this.failure,
  });

  final ProfileSeasonHistoryStatus status;
  final GameType? selectedGameType;
  final List<SeasonStanding> standings;
  final Failure? failure;

  ProfileSeasonHistoryState copyWith({
    ProfileSeasonHistoryStatus? status,
    GameType? selectedGameType,
    List<SeasonStanding>? standings,
    Failure? failure,
  }) {
    return ProfileSeasonHistoryState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      standings: standings ?? this.standings,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, selectedGameType, standings, failure];
}
