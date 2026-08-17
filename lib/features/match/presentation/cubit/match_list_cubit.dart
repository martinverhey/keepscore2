import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/data/realtime.dart';
import '../../../../core/error/failure.dart';
import '../../domain/game_type.enum.dart';
import '../../domain/match_repository.dart';
import 'game_type_filter_cubit.dart';
import 'match_list_state.dart';

export 'match_list_state.dart';

class MatchListCubit extends Cubit<MatchListState> {
  MatchListCubit(
    this._repository,
    this._gameTypeFilterCubit,
    this.competitionId,
  ) : super(const MatchListLoading()) {
    _gameTypeSubscription = _gameTypeFilterCubit.stream.listen(_applyGameType);
  }

  static const pageSize = 20;

  final MatchRepository _repository;
  final GameTypeFilterCubit _gameTypeFilterCubit;
  final String competitionId;

  StreamSubscription<GameType?>? _gameTypeSubscription;
  DebouncedTicks? _watcher;

  MatchListReady? get _ready => switch (state) {
    MatchListReady ready => ready,
    _ => null,
  };

  Future<void> load({bool silent = false}) async {
    final ready = _ready;
    if (!silent) emit(const MatchListLoading());
    _watch();

    final gameType = _gameTypeFilterCubit.state;
    final currentLength = ready?.matches.length ?? 0;
    final limit = currentLength > pageSize ? currentLength : pageSize;

    try {
      final matches = await _repository.feed(
        competitionId: competitionId,
        gameType: gameType,
        limit: limit,
      );
      if (isClosed) return;
      emit(
        MatchListReady(
          selectedGameType: gameType,
          matches: matches,
          hasMore: matches.length == limit,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      if (silent && ready != null) return;
      emit(MatchListFailed(failure));
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> selectGameTypeFilter(GameType? gameType) =>
      _gameTypeFilterCubit.select(gameType);

  Future<void> _applyGameType(GameType? gameType) async {
    final ready = _ready;
    if (ready == null || gameType == ready.selectedGameType) return;

    emit(
      ready.copyWith(
        selectedGameType: gameType,
        clearGameType: gameType == null,
        matches: const [],
        busy: true,
        clearActionFailure: true,
      ),
    );

    try {
      final matches = await _repository.feed(
        competitionId: competitionId,
        gameType: gameType,
        limit: pageSize,
      );
      if (isClosed) return;
      final latest = _ready;
      if (latest == null) return;
      emit(
        latest.copyWith(
          matches: matches,
          hasMore: matches.length == pageSize,
          busy: false,
        ),
      );
    } on Failure {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) emit(latest.copyWith(busy: false));
    }
  }

  Future<void> loadMore() async {
    final ready = _ready;
    if (ready == null || ready.loadingMore || !ready.hasMore) return;
    emit(ready.copyWith(loadingMore: true, clearActionFailure: true));
    try {
      final more = await _repository.feed(
        competitionId: competitionId,
        gameType: ready.selectedGameType,
        limit: pageSize,
        offset: ready.matches.length,
      );
      if (isClosed) return;
      final latest = _ready;
      if (latest == null) return;
      emit(
        latest.copyWith(
          matches: [...latest.matches, ...more],
          hasMore: more.length == pageSize,
          loadingMore: false,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      final latest = _ready;
      if (latest != null) {
        emit(latest.copyWith(loadingMore: false, actionFailure: failure));
      }
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
