import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/game_type.enum.dart';

sealed class ProfileHistoryState extends Equatable {
  const ProfileHistoryState();
}

class ProfileHistoryLoading extends ProfileHistoryState {
  const ProfileHistoryLoading();

  @override
  List<Object?> get props => [];
}

class ProfileHistoryFailed extends ProfileHistoryState {
  const ProfileHistoryFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfileHistoryReady extends ProfileHistoryState {
  const ProfileHistoryReady({
    required this.selectedGameType,
    this.leaderboards = const [],
  });

  final GameType? selectedGameType;
  final List<SeasonLeaderboard> leaderboards;

  ProfileHistoryReady copyWith({
    GameType? selectedGameType,
    List<SeasonLeaderboard>? leaderboards,
    bool clearGameType = false,
  }) {
    return ProfileHistoryReady(
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      leaderboards: leaderboards ?? this.leaderboards,
    );
  }

  @override
  List<Object?> get props => [selectedGameType, leaderboards];
}
