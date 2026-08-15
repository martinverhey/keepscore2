import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../domain/head_to_head_record.model.dart';

enum ProfileVersusStatus { loading, ready, failed }

class ProfileVersusState extends Equatable {
  const ProfileVersusState({
    this.status = ProfileVersusStatus.loading,
    this.selectedGameType,
    this.headToHead = const [],
    this.recentMatches = const [],
    this.failure,
  });

  final ProfileVersusStatus status;
  final GameType? selectedGameType;
  final List<HeadToHeadRecord> headToHead;
  final List<MatchEntry> recentMatches;
  final Failure? failure;

  List<HeadToHeadRecord> get records => selectedGameType == null
      ? headToHead
      : headToHead
            .where((record) => record.gameType == selectedGameType)
            .toList(growable: false);

  ProfileVersusState copyWith({
    ProfileVersusStatus? status,
    GameType? selectedGameType,
    List<HeadToHeadRecord>? headToHead,
    List<MatchEntry>? recentMatches,
    Failure? failure,
  }) {
    return ProfileVersusState(
      status: status ?? this.status,
      selectedGameType: selectedGameType ?? this.selectedGameType,
      headToHead: headToHead ?? this.headToHead,
      recentMatches: recentMatches ?? this.recentMatches,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedGameType,
    headToHead,
    recentMatches,
    failure,
  ];
}
