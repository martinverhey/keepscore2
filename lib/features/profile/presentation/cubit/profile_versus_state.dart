import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
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
    this.headToHead = const HeadToHeadRecord.zero(),
    this.recentMatches = const [],
  });

  final HeadToHeadRecord headToHead;
  final List<MatchEntry> recentMatches;

  @override
  List<Object?> get props => [headToHead, recentMatches];
}
