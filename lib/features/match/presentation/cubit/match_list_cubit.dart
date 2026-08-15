import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/game_type.dart';
import '../../domain/match_repository.dart';
import 'game_type_filter_cubit.dart';
import 'match_list_state.dart';

export 'match_list_state.dart';

class MatchListCubit extends Cubit<MatchListState> {
  MatchListCubit(this._repository, this._gameTypeFilterCubit, this.competitionId)
    : super(const MatchListState()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  static const pageSize = 20;

  final MatchRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;

  StreamSubscription<GameType?>? _gameTypeSubscription;
  DebouncedTicks? _watcher;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const MatchListState());
    _watch();

    final gameType = _gameTypeFilterCubit.state;
    final limit = state.matches.length > pageSize
        ? state.matches.length
        : pageSize;

    try {
      final matches = await _repository.feed(
        competitionId: competitionId,
        gameType: gameType,
        limit: limit,
      );
      if (isClosed) return;
      emit(
        MatchListState(
          status: MatchListStatus.ready,
          selectedGameType: gameType,
          matches: matches,
          hasMore: matches.length == limit,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        MatchListState(
          status: MatchListStatus.failed,
          selectedGameType: gameType,
          matches: silent ? state.matches : const [],
          hasMore: silent && state.hasMore,
          failure: failure,
        ),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
    if (gameType == state.selectedGameType) return;

    emit(
      state.copyWith(
        selectedGameType: gameType,
        clearGameType: gameType == null,
        matches: const [],
        busy: true,
        clearFailure: true,
      ),
    );

    try {
      final matches = await _repository.feed(
        competitionId: competitionId,
        gameType: gameType,
        limit: pageSize,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          matches: matches,
          hasMore: matches.length == pageSize,
          busy: false,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, failure: failure));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true, clearActionFailure: true));
    try {
      final more = await _repository.feed(
        competitionId: competitionId,
        gameType: state.selectedGameType,
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
    _gameTypeSubscription?.cancel();
    _watcher?.cancel();
    return super.close();
  }
}
