import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/season_standing.dart';

typedef SeasonHistoryGroup = ({
  String seasonId,
  DateTime startsAt,
  DateTime endsAt,
  List<SeasonStanding> standings,
});

enum SeasonHistoryStatus { loading, ready, failed }

class SeasonHistoryState extends Equatable {
  const SeasonHistoryState({
    this.status = SeasonHistoryStatus.loading,
    this.groups = const [],
    this.failure,
  });

  final SeasonHistoryStatus status;
  final List<SeasonHistoryGroup> groups;
  final Failure? failure;

  @override
  List<Object?> get props => [status, groups, failure];
}
