import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/match_entry.dart';

enum MatchListStatus { loading, ready, failed }

class MatchListState extends Equatable {
  const MatchListState({
    this.status = MatchListStatus.loading,
    this.matches = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
    this.actionFailure,
  });

  final MatchListStatus status;
  final List<MatchEntry> matches;
  final bool hasMore;
  final bool loadingMore;

  final Failure? failure;

  final Failure? actionFailure;

  MatchListState copyWith({
    MatchListStatus? status,
    List<MatchEntry>? matches,
    bool? hasMore,
    bool? loadingMore,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) {
    return MatchListState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    matches,
    hasMore,
    loadingMore,
    failure,
    actionFailure,
  ];
}
