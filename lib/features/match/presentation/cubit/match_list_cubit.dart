import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/match_repository.dart';
import 'match_list_state.dart';

export 'match_list_state.dart';

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
