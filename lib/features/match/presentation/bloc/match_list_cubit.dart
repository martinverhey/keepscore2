import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/match_entry.dart';
import '../../domain/match_repository.dart';

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

  /// A failed "load more". Kept apart from [failure] so it never blanks a
  /// list that loaded perfectly well.
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

class MatchListCubit extends Cubit<MatchListState> {
  MatchListCubit(this._repository, this.competitionId)
    : super(const MatchListState());

  static const pageSize = 20;

  final MatchRepository _repository;
  final String competitionId;

  DebouncedTicks? _watcher;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const MatchListState());
    _watch();

    // A refresh keeps however many pages are already on screen.
    final limit = state.matches.length > pageSize
        ? state.matches.length
        : pageSize;

    try {
      final matches = await _repository.feed(
        competitionId: competitionId,
        limit: limit,
      );
      if (isClosed) return;
      emit(
        MatchListState(
          status: MatchListStatus.ready,
          matches: matches,
          hasMore: matches.length == limit,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        MatchListState(
          status: MatchListStatus.failed,
          matches: silent ? state.matches : const [],
          hasMore: silent && state.hasMore,
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true, clearActionFailure: true));
    try {
      final more = await _repository.feed(
        competitionId: competitionId,
        limit: pageSize,
        offset: state.matches.length,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MatchListStatus.ready,
          matches: [...state.matches, ...more],
          hasMore: more.length == pageSize,
          loadingMore: false,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(loadingMore: false, actionFailure: failure));
    }
  }

  void _watch() {
    _watcher ??= DebouncedTicks(_repository.watch(competitionId), () {
      if (!isClosed) refresh();
    });
  }

  @override
  Future<void> close() {
    _watcher?.cancel();
    return super.close();
  }
}
