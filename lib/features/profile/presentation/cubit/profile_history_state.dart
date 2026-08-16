import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/game_type.enum.dart';

enum ProfileHistoryStatus { loading, ready, failed }

class ProfileHistoryState extends Equatable {
  const ProfileHistoryState({
    this.status = ProfileHistoryStatus.loading,
    this.selectedGameType,
    this.leaderboards = const [],
    this.failure,
  });

  final ProfileHistoryStatus status;
  final GameType? selectedGameType;
  final List<SeasonLeaderboard> leaderboards;
  final Failure? failure;

  ProfileHistoryState copyWith({
    ProfileHistoryStatus? status,
    GameType? selectedGameType,
    List<SeasonLeaderboard>? leaderboards,
    Failure? failure,
  }) {
    return ProfileHistoryState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      leaderboards: leaderboards ?? this.leaderboards,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, selectedGameType, leaderboards, failure];
}
