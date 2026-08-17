import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../domain/head_to_head_record.model.dart';

sealed class ProfileVersusState extends Equatable {
  const ProfileVersusState();
}

class ProfileVersusLoading extends ProfileVersusState {
  const ProfileVersusLoading();

  @override
  List<Object?> get props => [];
}

class ProfileVersusFailed extends ProfileVersusState {
  const ProfileVersusFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfileVersusReady extends ProfileVersusState {
  const ProfileVersusReady({
    required this.selectedGameType,
    this.headToHead = const [],
    this.recentMatches = const [],
  });

  final GameType? selectedGameType;
  final List<HeadToHeadRecord> headToHead;
  final List<MatchEntry> recentMatches;

  List<HeadToHeadRecord> get records => selectedGameType == null
      ? headToHead
      : headToHead
            .where((record) => record.gameType == selectedGameType)
            .toList(growable: false);

  ProfileVersusReady copyWith({
    GameType? selectedGameType,
    List<HeadToHeadRecord>? headToHead,
    List<MatchEntry>? recentMatches,
  }) {
    return ProfileVersusReady(
      selectedGameType: selectedGameType ?? this.selectedGameType,
      headToHead: headToHead ?? this.headToHead,
      recentMatches: recentMatches ?? this.recentMatches,
    );
  }

  @override
  List<Object?> get props => [selectedGameType, headToHead, recentMatches];
}
