import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/game_type.enum.dart';
import '../../domain/match_entry.model.dart';

enum MatchListStatus { loading, ready, failed }

class MatchListState extends Equatable {
  const MatchListState({
    this.status = MatchListStatus.loading,
    this.selectedGameType,
    this.matches = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  final MatchListStatus status;
  final GameType? selectedGameType;
  final List<MatchEntry> matches;
  final bool hasMore;
  final bool loadingMore;
  final bool busy;

  final Failure? failure;

  final Failure? actionFailure;

  MatchListState copyWith({
    MatchListStatus? status,
    GameType? selectedGameType,
    List<MatchEntry>? matches,
    bool? hasMore,
    bool? loadingMore,
    bool? busy,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
    bool clearGameType = false,
  }) {
    return MatchListState(
      status: status ?? this.status,
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      matches: matches ?? this.matches,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedGameType,
    matches,
    hasMore,
    loadingMore,
    busy,
    failure,
    actionFailure,
  ];
}
