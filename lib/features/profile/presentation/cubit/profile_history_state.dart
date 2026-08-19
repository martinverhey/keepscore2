import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';

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
  const ProfileHistoryReady({this.leaderboards = const []});

  final List<SeasonLeaderboard> leaderboards;

  @override
  List<Object?> get props => [leaderboards];
}
