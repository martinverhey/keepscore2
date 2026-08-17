import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/game_type.enum.dart';
import '../../domain/match_entry.model.dart';

sealed class MatchListState extends Equatable {
  const MatchListState();
}

class MatchListLoading extends MatchListState {
  const MatchListLoading();

  @override
  List<Object?> get props => [];
}

class MatchListFailed extends MatchListState {
  const MatchListFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class MatchListReady extends MatchListState {
  const MatchListReady({
    this.selectedGameType,
    this.matches = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.busy = false,
    this.actionFailure,
  });

  final GameType? selectedGameType;
  final List<MatchEntry> matches;
  final bool hasMore;
  final bool loadingMore;
  final bool busy;
  final Failure? actionFailure;

  MatchListReady copyWith({
    GameType? selectedGameType,
    List<MatchEntry>? matches,
    bool? hasMore,
    bool? loadingMore,
    bool? busy,
    Failure? actionFailure,
    bool clearActionFailure = false,
    bool clearGameType = false,
  }) {
    return MatchListReady(
      selectedGameType: clearGameType
          ? null
          : (selectedGameType ?? this.selectedGameType),
      matches: matches ?? this.matches,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      busy: busy ?? this.busy,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    selectedGameType,
    matches,
    hasMore,
    loadingMore,
    busy,
    actionFailure,
  ];
}
